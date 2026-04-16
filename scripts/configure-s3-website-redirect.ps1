# Configures the S3 *website* endpoint for this bucket to issue an HTTP redirect to
# your primary domain. Anyone opening the old URL
# http://alainavasquez-com-web-prod.s3-website-us-east-1.amazonaws.com/ is sent to
# https://alainavasquez.com/ (or the host you pass in).
#
# Run this ONLY AFTER CloudFront uses the S3 REST origin + OAC (see
# infrastructure/cloudfront-acm.yaml and deploy-cloudfront.ps1). If CloudFront still
# used the website endpoint as origin, redirects would break the CDN.
#
# Prerequisites: AWS CLI (e.g. $env:AWS_PROFILE = "AdminUser")

param(
  [string]$BucketName = "alainavasquez-com-web-prod",
  [string]$RedirectHostName = "alainavasquez.com",
  [ValidateSet("https", "http")]
  [string]$RedirectProtocol = "https",
  [string]$Region = "us-east-1"
)

$ErrorActionPreference = "Stop"

aws sts get-caller-identity | Out-Null
if ($LASTEXITCODE -ne 0) {
  Write-Error "AWS credentials not found. Run: aws configure"
}

$utf8NoBom = New-Object System.Text.UTF8Encoding $false
$websiteJson = @"
{
  "RedirectAllRequestsTo": {
    "HostName": "$RedirectHostName",
    "Protocol": "$RedirectProtocol"
  }
}
"@

Push-Location $PSScriptRoot
try {
  [System.IO.File]::WriteAllText("_website-redirect.json", $websiteJson.Trim(), $utf8NoBom)
  aws s3api put-bucket-website `
    --bucket $BucketName `
    --website-configuration file://_website-redirect.json `
    --region $Region
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
  Remove-Item "_website-redirect.json" -Force -ErrorAction SilentlyContinue
} finally {
  Pop-Location
}

$websiteUrl = "http://$BucketName.s3-website-$Region.amazonaws.com"
Write-Host ""
Write-Host "S3 website endpoint now redirects to ${RedirectProtocol}://${RedirectHostName}/"
Write-Host "Test: $websiteUrl"
