# alainavasquez.com — static site

Public portfolio for **https://alainavasquez.com/** (HTML + CSS on S3 + CloudFront).

## Security

- **Never commit AWS keys.** Use `aws configure`, `aws configure sso`, or an IAM role on the deploy machine. See `user/README.md`.
- Infrastructure is defined in `infrastructure/cloudfront-acm.yaml` (ACM, CloudFront with OAC, security headers, Route 53).

## Deploy (summary)

1. Configure AWS CLI in **`%USERPROFILE%\.aws`** (e.g. `credentials` + `config` with profile **`AdminUser`**). In PowerShell: `$env:AWS_PROFILE = "AdminUser"`; region **`us-east-1`**.
2. `.\scripts\deploy-cloudfront.ps1` — ACM, CloudFront, bucket policy (OAC), response headers (CSP + HSTS short phase), then locks S3 public access block when legacy public read is off.
3. `.\scripts\configure-s3-website-redirect.ps1` — S3 website URL redirects to `https://alainavasquez.com/`.
4. `.\scripts\create-s3-bucket.ps1 -SkipWebsiteHosting -SkipBucketPolicyAndPublicAccess` — upload site files without overwriting stack policy.

After HTML/CSS changes, create a CloudFront invalidation for `/*` (or at least `/index.html` and `/styles.css`).

## HSTS note

CloudFront sends **HSTS** with `max-age=300` (5 minutes) and `includeSubDomains` for an initial phase. After you confirm apex and `www` behave correctly, raise `AccessControlMaxAgeSec` in the template (e.g. `31536000`) and redeploy.

## CSP note

If you add third-party scripts, fonts, or inline styles, update **ContentSecurityPolicy** on `SiteSecurityHeadersPolicy` in `infrastructure/cloudfront-acm.yaml` to match.

## Push to GitHub (public repo)

This repo is initialized with `main` and **no secrets** in history. To publish:

1. On GitHub: **New repository** → name (e.g. `alainavasquez.com` or `alainavasquez-com-site`) → **Public** → create **without** README (this repo already has one).
2. Locally (replace `YOUR_USER` and `REPO`):

```bash
git remote add origin https://github.com/YOUR_USER/REPO.git
git push -u origin main
```

Or install [GitHub CLI](https://cli.github.com/) and run: `gh repo create REPO --public --source=. --remote=origin --push`

Before pushing, optionally set your preferred author: `git config user.email "you@users.noreply.github.com"` (repo-local is already set for commits in this clone).
