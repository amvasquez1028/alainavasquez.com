# Creates the S3 bucket for alainavasquez.com static hosting and syncs site files.
# Prerequisites: AWS CLI installed. Either `aws configure` (default profile) or
# set $env:AWS_PROFILE = "YourProfile" before running (e.g. AdminUser).
#
# Region: us-east-1 — pair this origin with CloudFront + ACM (us-east-1) for
# https://alainavasquez.com/
#
# Bucket name has NO dots (avoids SSL issues with virtual-hosted-style access).
#
# After CloudFormation manages the bucket policy (deploy-cloudfront.ps1), use
# -SkipBucketPolicyAndPublicAccess when syncing so you do not replace the OAC policy.
# After configure-s3-website-redirect.ps1, use -SkipWebsiteHosting so you do not
# replace redirect-all with index/error hosting.

param(
  [switch]$SkipWebsiteHosting,
  [switch]$SkipBucketPolicyAndPublicAccess
)

$ErrorActionPreference = "Stop"

$BucketName = "alainavasquez-com-web-prod"
$Region = "us-east-1"
$SiteRoot = Split-Path -Parent $PSScriptRoot

if (-not (Test-Path (Join-Path $SiteRoot "index.html"))) {
  Write-Error "Could not find index.html next to scripts folder. Site root: $SiteRoot"
}

Write-Host "Bucket: $BucketName"
Write-Host "Region: $Region"
Write-Host "Site root: $SiteRoot"
Write-Host ""

aws sts get-caller-identity | Out-Null
if ($LASTEXITCODE -ne 0) {
  Write-Error "AWS credentials not found. Run: aws configure"
}

# HeadBucket returns 404 + stderr when missing; avoid Stop treating that as fatal.
$prevErr = $ErrorActionPreference
$ErrorActionPreference = "SilentlyContinue"
$null = aws s3api head-bucket --bucket $BucketName 2>&1
$exists = ($LASTEXITCODE -eq 0)
$ErrorActionPreference = $prevErr

if (-not $exists) {
  aws s3api create-bucket --bucket $BucketName --region $Region
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
  Write-Host "Created bucket: $BucketName"
} else {
  Write-Host "Bucket already exists: $BucketName"
}

$utf8NoBom = New-Object System.Text.UTF8Encoding $false
$encJson = @'
{
  "Rules": [{
    "ApplyServerSideEncryptionByDefault": { "SSEAlgorithm": "AES256" },
    "BucketKeyEnabled": true
  }]
}
'@
Push-Location $PSScriptRoot
try {
  $sseFile = Join-Path $PSScriptRoot "_sse-run.json"
  [System.IO.File]::WriteAllText($sseFile, $encJson.Trim(), $utf8NoBom)
  # AWS CLI on Windows expects file://C:/path (two slashes), not file:///C:/...
  $sseUri = "file://" + ($sseFile -replace "\\", "/")
  aws s3api put-bucket-encryption --bucket $BucketName --server-side-encryption-configuration $sseUri
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
  Remove-Item $sseFile -Force -ErrorAction SilentlyContinue
} finally {
  Pop-Location
}

if (-not $SkipWebsiteHosting) {
  aws s3 website "s3://$BucketName/" --index-document index.html --error-document index.html
} else {
  Write-Host "Skipping S3 website configuration (-SkipWebsiteHosting)."
}

if (-not $SkipBucketPolicyAndPublicAccess) {
  # Allow bucket policy that grants public GetObject (website endpoint is HTTP).
  aws s3api put-public-access-block --bucket $BucketName --public-access-block-configuration `
    "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false"

  $policy = @"
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::$BucketName/*"
    }
  ]
}
"@
  Push-Location $PSScriptRoot
  try {
    $policyFile = Join-Path $PSScriptRoot "_policy-run.json"
    [System.IO.File]::WriteAllText($policyFile, $policy.Trim(), $utf8NoBom)
    $policyUri = "file://" + ($policyFile -replace "\\", "/")
    aws s3api put-bucket-policy --bucket $BucketName --policy $policyUri
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    Remove-Item $policyFile -Force -ErrorAction SilentlyContinue
  } finally {
    Pop-Location
  }
} else {
  Write-Host "Skipping public access block and bucket policy (-SkipBucketPolicyAndPublicAccess)."
}

Write-Host ""
Write-Host "Uploading site..."
aws s3 sync $SiteRoot "s3://$BucketName/" `
  --delete `
  --exclude ".git/*" `
  --exclude ".cursor/*" `
  --exclude "scripts/*" `
  --exclude "user/*" `
  --exclude "infrastructure/*" `
  --exclude "assets/*" `
  --exclude "_sse-run.json" `
  --exclude "_policy-run.json" `
  --exclude "*.md"

$websiteUrl = "http://$BucketName.s3-website-$Region.amazonaws.com"
Write-Host ""
Write-Host "Website endpoint (HTTP): $websiteUrl"
Write-Host ""
Write-Host "HTTPS + custom domain: run deploy-cloudfront.ps1, then configure-s3-website-redirect.ps1."
Write-Host "Later syncs: .\create-s3-bucket.ps1 -SkipWebsiteHosting -SkipBucketPolicyAndPublicAccess"
