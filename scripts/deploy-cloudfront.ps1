# Deploy ACM + CloudFront + Route 53 aliases for https://alainavasquez.com/
#
# CloudFront pulls objects from the S3 regional REST endpoint with Origin Access
# Control (OAC). After a successful deploy, run configure-s3-website-redirect.ps1 so
# the legacy S3 website URL redirects to https://alainavasquez.com/
#
# Requirements:
# - AWS CLI configured (e.g. $env:AWS_PROFILE = "AdminUser")
# - Public Route 53 hosted zone for the domain IN THIS ACCOUNT (same as CLI identity)
# - S3 bucket exists with site objects (see create-s3-bucket.ps1)
#
# Usage:
#   .\deploy-cloudfront.ps1
#   .\deploy-cloudfront.ps1 -HostedZoneId Z...   # override zone if needed
#
# Optional:
#   .\deploy-cloudfront.ps1 -EnableLegacyPublicRead true   # legacy public S3 read (not recommended)

param(
  [Parameter(HelpMessage = "Route 53 hosted zone ID for alainavasquez.com")]
  [string]$HostedZoneId = "Z0799029THB6926C6JAD",

  [string]$DomainName = "alainavasquez.com",
  [string]$SiteBucketName = "alainavasquez-com-web-prod",
  [ValidateSet("true", "false")]
  [string]$EnableLegacyPublicRead = "false",

  [ValidateSet("true", "false")]
  [string]$IncludeWwwHostname = "true",

  [string]$PriceClass = "PriceClass_100",
  [string]$StackName = "alainavasquez-com-cdn",
  [string]$Region = "us-east-1"
)

$ErrorActionPreference = "Stop"

$template = Join-Path (Split-Path -Parent $PSScriptRoot) "infrastructure\cloudfront-acm.yaml"
if (-not (Test-Path $template)) {
  Write-Error "Template not found: $template"
}

Write-Host "Stack: $StackName"
Write-Host "Region: $Region (required for ACM used by CloudFront)"
Write-Host "Domain: $DomainName + www.$DomainName"
Write-Host "S3 REST origin: ${SiteBucketName}.s3.${Region}.amazonaws.com (OAC)"
Write-Host "EnableLegacyPublicRead: $EnableLegacyPublicRead"
Write-Host "IncludeWwwHostname: $IncludeWwwHostname"
Write-Host ""

aws sts get-caller-identity | Out-Null
if ($LASTEXITCODE -ne 0) {
  Write-Error "AWS CLI not configured. Set credentials or `$env:AWS_PROFILE."
}

aws cloudformation deploy `
  --template-file $template `
  --stack-name $StackName `
  --parameter-overrides `
  "HostedZoneId=$HostedZoneId" `
  "DomainName=$DomainName" `
  "SiteBucketName=$SiteBucketName" `
  "EnableLegacyPublicRead=$EnableLegacyPublicRead" `
  "IncludeWwwHostname=$IncludeWwwHostname" `
  "PriceClass=$PriceClass" `
  --region $Region

if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

if ($EnableLegacyPublicRead -eq "false") {
  Write-Host ""
  Write-Host "Applying S3 public access block (OAC-only bucket)..."
  & (Join-Path $PSScriptRoot "lock-s3-public-access-block.ps1") -BucketName $SiteBucketName -Region $Region
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

Write-Host ""
Write-Host "Outputs:"
aws cloudformation describe-stacks --stack-name $StackName --region $Region `
  --query "Stacks[0].Outputs" --output table
