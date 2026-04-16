# Local-only files

Do **not** put AWS access keys in this repository.

- Use **`aws configure`** (or **`aws configure sso`**) and a named **`AWS_PROFILE`**, or attach an **IAM role** to the machine or CI runner that deploys.
- Deploy scripts: `scripts/deploy-cloudfront.ps1`, `scripts/create-s3-bucket.ps1`, `scripts/configure-s3-website-redirect.ps1`.

The `credentials/` folder is ignored by git so local exports stay private.
