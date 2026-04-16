# alainavasquez.com — static site

Public portfolio for **https://alainavasquez.com/** (HTML + CSS on S3 + CloudFront).

## Security

- **Never commit AWS keys.** Use `aws configure`, `aws configure sso`, or an IAM role on the deploy machine. See `user/README.md`.
- Infrastructure is defined in `infrastructure/cloudfront-acm.yaml` (ACM, CloudFront with OAC, security headers, Route 53).

## Deploy (summary)

1. Configure AWS CLI (`us-east-1`).
2. `.\scripts\deploy-cloudfront.ps1` — ACM, CloudFront, bucket policy (OAC), response headers (CSP + HSTS short phase).
3. `.\scripts\configure-s3-website-redirect.ps1` — S3 website URL redirects to `https://alainavasquez.com/`.
4. `.\scripts\create-s3-bucket.ps1 -SkipWebsiteHosting -SkipBucketPolicyAndPublicAccess` — upload site files without overwriting stack policy.

After HTML/CSS changes, create a CloudFront invalidation for `/*` (or at least `/index.html` and `/styles.css`).

## HSTS note

CloudFront sends **HSTS** with `max-age=300` (5 minutes) and `includeSubDomains` for an initial phase. After you confirm apex and `www` behave correctly, raise `AccessControlMaxAgeSec` in the template (e.g. `31536000`) and redeploy.

## CSP note

If you add third-party scripts, fonts, or inline styles, update **ContentSecurityPolicy** on `SiteSecurityHeadersPolicy` in `infrastructure/cloudfront-acm.yaml` to match.
