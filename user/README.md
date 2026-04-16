# Local-only files

Do **not** put AWS access keys in this repository.

- Use **`aws configure`** (stores keys under **`%USERPROFILE%\.aws`**) or **`aws configure sso`**, then set **`AWS_PROFILE`** (e.g. **`AdminUser`**) in your shell before running scripts.
- Deploy scripts: `scripts/deploy-cloudfront.ps1`, `scripts/create-s3-bucket.ps1`, `scripts/configure-s3-website-redirect.ps1`.

The `credentials/` folder is ignored by git so local exports stay private.
