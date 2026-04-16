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

This repo uses branch **`main`** and **no secrets** in history. Author email is set to **`alainavasquez1028@gmail.com`** for this clone.

1. Sign in as **[amvasquez1028](https://github.com/amvasquez1028)** on GitHub.
2. **[Create a new public repository](https://github.com/new)** named **`alainavasquez.com`** (exact name matches the configured remote), **without** adding a README, `.gitignore`, or license (this repo already has them).
3. Push:

```bash
git remote add origin https://github.com/amvasquez1028/alainavasquez.com.git   # if not already set
git push -u origin main
```

If you prefer a different repo name, run `git remote set-url origin https://github.com/amvasquez1028/YOUR_REPO_NAME.git` then push.

Or install [GitHub CLI](https://cli.github.com/) and run: `gh repo create alainavasquez.com --public --source=. --remote=origin --push`
