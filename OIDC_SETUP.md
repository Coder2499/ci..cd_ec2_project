# GitHub OIDC Setup Guide for AWS Terraform Deployment

## Overview
This project now uses **OpenID Connect (OIDC)** to authenticate with AWS instead of storing long-lived access keys in GitHub Secrets. This is more secure and requires no secret management.

---

## What Changed

### ✅ GitHub Actions Workflows Updated
Both `deploy.yml` and `destroy.yml` now use OIDC authentication:

**Old Method (❌ Insecure)**
```yaml
- name: Configure AWS Credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
    aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
    aws-region: ${{ secrets.AWS_REGION }}
```

**New Method (✅ Secure)**
```yaml
- name: Configure AWS Credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: arn:aws:iam::YOUR_ACCOUNT_ID:role/github-actions-role
    role-session-name: github-actions-session
    aws-region: ap-south-1
```

**Key Changes:**
- ✅ Added `permissions` section with `id-token: write` (required for OIDC)
- ✅ Removed secret-based credentials
- ✅ Using role ARN instead (temporary credentials generated at runtime)
- ✅ Fixed AWS region as environment variable (no longer needs AWS_REGION secret)

---

## AWS Setup Required

### Step 1: Create an IAM Role for GitHub Actions

Run this in AWS CLI or via AWS Console:

```bash
# Create trust policy file: trust-policy.json
cat > trust-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::YOUR_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:Coder2499/ci..cd_ec2_project:*"
        }
      }
    }
  ]
}
EOF

# Create the IAM role
aws iam create-role \
  --role-name github-actions-role \
  --assume-role-policy-document file://trust-policy.json

# Attach policy for EC2 and Terraform operations
aws iam attach-role-policy \
  --role-name github-actions-role \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2FullAccess
```

### Step 2: Update YOUR_ACCOUNT_ID

Replace `YOUR_ACCOUNT_ID` in the workflow files with your actual AWS account ID:

```bash
# Find your account ID
aws sts get-caller-identity --query Account --output text
```

Then update both `deploy.yml` and `destroy.yml`:
```yaml
role-to-assume: arn:aws:iam::123456789012:role/github-actions-role  # Replace 123456789012
```

### Step 3: Remove GitHub Secrets (Optional Cleanup)

You can now delete these secrets from GitHub Settings → Secrets:
- `AWS_ACCESS_KEY_ID` ❌
- `AWS_SECRET_ACCESS_KEY` ❌
- `AWS_REGION` ❌ (now hardcoded in workflow)

---

## How OIDC Works

1. GitHub Actions generates a **temporary OIDC token** with a 1-hour expiration
2. GitHub Actions exchanges this token for **temporary AWS credentials**
3. Terraform uses these temporary credentials (AccessKeyId, SecretAccessKey, SessionToken)
4. Credentials **automatically expire** after 1 hour
5. No secrets stored anywhere ✅

---

## Benefits

| Aspect | Access Keys ❌ | OIDC ✅ |
|--------|---|---|
| Secret Storage | Required | Not needed |
| Credential Rotation | Manual | Automatic (1 hour) |
| Security Risk | High (if leaked) | Low (temporary) |
| Management | Complex | Simple |
| Cost | Free | Free |

---

## Troubleshooting

If workflows fail with "AssumeRole" errors:

1. ✅ Verify IAM role exists: `aws iam get-role --role-name github-actions-role`
2. ✅ Check account ID is correct in role ARN
3. ✅ Verify OIDC provider exists: `aws iam list-open-id-connect-providers`
4. ✅ Check GitHub repo name matches in trust policy (`Coder2499/ci..cd_ec2_project`)

---

## Additional Notes

- The IAM role should have **minimal permissions** needed for Terraform operations
- Currently using `AmazonEC2FullAccess` - consider restricting to specific resources in production
- OIDC provider should already exist in your AWS account (GitHub maintains it)
- If not, create it via AWS Console: IAM → Identity Providers → Add Provider (OpenID Connect)
