# Tightens S3 public access block on the site bucket (CloudFormation has no standalone
# BucketPublicAccessBlock resource for existing buckets). Safe when the bucket policy
# only allows CloudFront (OAC), not Principal *.
#
# Run after deploy-cloudfront.ps1 when not using legacy public read.

param(
  [string]$BucketName = "alainavasquez-com-web-prod",
  [string]$Region = "us-east-1"
)

$ErrorActionPreference = "Stop"

aws sts get-caller-identity | Out-Null
if ($LASTEXITCODE -ne 0) {
  Write-Error "AWS CLI not configured. Use ~/.aws (e.g. aws configure --profile AdminUser)."
}

aws s3api put-public-access-block `
  --bucket $BucketName `
  --region $Region `
  --public-access-block-configuration `
  "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "Public access block enabled on bucket: $BucketName"
