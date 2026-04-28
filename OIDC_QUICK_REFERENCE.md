# 🚀 OIDC Quick Reference Card

## Your Configuration Details

```
AWS Account ID:           502580451784
Region:                   ap-south-1
OIDC Provider:            token.actions.githubusercontent.com
IAM Role Name:            github-actions-role
IAM Role ARN:             arn:aws:iam::502580451784:role/github-actions-role
Role ID:                  AROAXKBBBDHENH22Q6C4X
Created:                  2026-04-28T05:12:21Z
EC2 Permissions:          AmazonEC2FullAccess
Repository:               Coder2499/ci..cd_ec2_project
```

---

## Verification Commands (Copy-Paste Ready)

### 1. Check OIDC Provider
```bash
aws iam list-open-id-connect-providers
```
Expected: OIDC provider ARN listed ✅

### 2. Check IAM Role
```bash
aws iam get-role --role-name github-actions-role
```
Expected: Role details displayed ✅

### 3. Check Trust Policy
```bash
aws iam get-role --role-name github-actions-role | jq '.Role.AssumeRolePolicyDocument'
```
Expected: Trust policy with GitHub OIDC condition ✅

### 4. Check Permissions
```bash
aws iam list-attached-role-policies --role-name github-actions-role
```
Expected: AmazonEC2FullAccess policy listed ✅

### 5. Check Workflow Configuration
```bash
grep -n "id-token: write" .github/workflows/deploy.yml
grep -n "role-to-assume" .github/workflows/deploy.yml
```
Expected: Both lines found ✅

### 6. Check No Secrets Used
```bash
grep "secrets.AWS" .github/workflows/*.yml
```
Expected: No output (empty) ✅

---

## What Each File Does

| File | Purpose |
|------|---------|
| [OIDC_SETUP.md](OIDC_SETUP.md) | Step-by-step setup instructions |
| [OIDC_VERIFICATION.md](OIDC_VERIFICATION.md) | Complete verification guide |
| [OIDC_SUMMARY.md](OIDC_SUMMARY.md) | Visual architecture & flow diagrams |
| [OIDC_QUICK_REFERENCE.md](OIDC_QUICK_REFERENCE.md) | This file - quick commands |

---

## GitHub Actions Workflow URL

**Deploy Workflow:**
https://github.com/Coder2499/ci..cd_ec2_project/actions/workflows/deploy.yml

**Destroy Workflow:**
https://github.com/Coder2499/ci..cd_ec2_project/actions/workflows/destroy.yml

---

## Testing Workflow

```bash
# 1. Commit and push changes
git add .github/workflows/
git commit -m "Enable OIDC authentication"
git push origin main

# 2. Go to GitHub Actions and run Deploy workflow
# (Or use GitHub CLI if you prefer)
gh workflow run deploy.yml -f environment=dev -f base_name=test-server

# 3. Watch logs for:
#    - "Attempting to assume role"
#    - "Successfully assumed role"
```

---

## Cleanup Tasks

```bash
# Delete old AWS secrets from GitHub (if they exist)
# Go to: Settings → Secrets and delete:
# - AWS_ACCESS_KEY_ID
# - AWS_SECRET_ACCESS_KEY  
# - AWS_REGION
```

---

## Common Issues & Solutions

### Issue: "User: is not authorized to perform: iam:..."
**Solution:** 
- Check that you're using correct AWS credentials locally
- Run: `aws sts get-caller-identity`

### Issue: "Workflow fails with AssumeRole error"
**Solution:**
- Verify account ID is correct: `502580451784`
- Verify role exists: `aws iam get-role --role-name github-actions-role`
- Check trust policy: `aws iam get-role --role-name github-actions-role | jq '.Role.AssumeRolePolicyDocument'`

### Issue: "Role not found in workflow logs"
**Solution:**
- Wait 30 seconds after creating role (IAM propagation delay)
- Verify role ARN in workflow files: `grep "502580451784" .github/workflows/*.yml`

---

## Security Checklist

- [ ] OIDC provider created
- [ ] IAM role created
- [ ] Trust policy configured (repository restricted)
- [ ] EC2 permissions attached
- [ ] Workflows updated with role ARN
- [ ] Workflows have `id-token: write` permission
- [ ] Old AWS_* secrets deleted from GitHub
- [ ] First workflow run successful (check logs for "Successfully assumed role")
- [ ] CloudTrail shows AssumeRole events from sts.amazonaws.com

---

## Architecture at a Glance

```
GitHub Workflow                AWS Account
     │                              │
     ├─ Generate OIDC token        │
     │                              │
     └─→ Exchange for credentials  │
                ↓                    │
          AWS STS Service ←─────────┤
                ↓                    │
          Validate Token            │
          Check Trust Policy ←──────┤
                ↓                    │
          Issue Temp Credentials    │
                ↓                    │
          Terraform Uses Creds      │
                ↓                    │
          Create/Update Resources   │
                ↓                    │
          Credentials Auto-Expire   │
```

---

## Key Points to Remember

✅ **No secrets stored anywhere**
✅ **Credentials auto-rotate every workflow**
✅ **1-hour max token lifetime**
✅ **Audit trail in CloudTrail**
✅ **AWS security best practice**
✅ **Industry standard for CI/CD**

---

## Need Help?

See the other OIDC documentation files:
- **Setup guide**: [OIDC_SETUP.md](OIDC_SETUP.md)
- **Detailed verification**: [OIDC_VERIFICATION.md](OIDC_VERIFICATION.md)
- **Architecture & flow**: [OIDC_SUMMARY.md](OIDC_SUMMARY.md)
