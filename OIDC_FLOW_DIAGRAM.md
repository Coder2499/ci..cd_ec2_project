# 🔄 OIDC Authentication Flow - Visual Guide

## The Complete OIDC Process Explained

### Scenario: You trigger "Deploy Infrastructure" workflow

```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃                    STEP-BY-STEP FLOW DIAGRAM                      ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛


┌─────────────────────────────────────────────────────────────────────┐
│ STEP 1: You Trigger Workflow on GitHub                             │
└─────────────────────────────────────────────────────────────────────┘

    You visit: https://github.com/Coder2499/ci..cd_ec2_project/actions
         ↓
    Click: Deploy Infrastructure
         ↓
    Click: Run workflow
         ↓
    Choose: Environment = "dev"
         ↓
    Click: Run workflow button ✓


┌─────────────────────────────────────────────────────────────────────┐
│ STEP 2: GitHub Actions Runner Starts                              │
└─────────────────────────────────────────────────────────────────────┘

    GitHub allocates runner (ubuntu-latest)
         ↓
    Runner checks out your code
         ↓
    Runner finds workflow file (.github/workflows/deploy.yml)
         ↓
    Runner reads permissions section:
    ┌──────────────────────────────────┐
    │ permissions:                     │
    │   contents: read       ← Read repo code
    │   id-token: write      ← ⭐ KEY: Can create OIDC tokens
    └──────────────────────────────────┘


┌─────────────────────────────────────────────────────────────────────┐
│ STEP 3: GitHub Generates OIDC Token ⭐ CRITICAL STEP              │
└─────────────────────────────────────────────────────────────────────┘

    Because workflow has: permissions.id-token: write
         ↓
    GitHub OIDC Provider generates token containing:
    ┌──────────────────────────────────────────┐
    │ {                                        │
    │   "iss": "https://token.actions.github.. │
    │   "aud": "sts.amazonaws.com",            │
    │   "sub": "repo:Coder2499/ci..cd_ec2_..  │
    │   "iat": 1714296741,                     │
    │   "exp": 1714297041,  ← 15 min from now │
    │   "signer": "GitHub OIDC"                │
    │ }                                        │
    └──────────────────────────────────────────┘
    
    Token is: SIGNED by GitHub (cryptographically)
    Lifetime: 15 minutes only
    Status: ✅ READY to exchange


┌─────────────────────────────────────────────────────────────────────┐
│ STEP 4: configure-aws-credentials Action Runs                      │
└─────────────────────────────────────────────────────────────────────┘

    Workflow step executes:
    ┌──────────────────────────────────────────┐
    │ - name: Configure AWS Credentials        │
    │   uses: aws-actions/configure-aws-..     │
    │   with:                                  │
    │     role-to-assume: arn:aws:iam::      │
    │       502580451784:role/github-actions-  │
    │       role                               │
    │     role-session-name: github-actions-.. │
    │     aws-region: ap-south-1               │
    └──────────────────────────────────────────┘
         ↓
    Action receives OIDC token from GitHub
         ↓
    Action prepares to exchange with AWS


┌─────────────────────────────────────────────────────────────────────┐
│ STEP 5: Exchange Token with AWS STS Service                        │
└─────────────────────────────────────────────────────────────────────┘

    Action calls: AWS STS AssumeRoleWithWebIdentity
         ↓
    Request to AWS:
    ┌──────────────────────────────────────────────┐
    │ POST https://sts.amazonaws.com               │
    │                                              │
    │ "I have this GitHub OIDC token.              │
    │  Please exchange it for AWS credentials      │
    │  to assume this role:                        │
    │  arn:aws:iam::502580451784:role/github-..   │
    │  actions-role"                              │
    │                                              │
    │ Token: eyJhbGciOiJSUzI1NiIsInR5cCI...[long]  │
    └──────────────────────────────────────────────┘


┌─────────────────────────────────────────────────────────────────────┐
│ STEP 6: AWS Validates OIDC Token ⭐ SECURITY CHECK                 │
└─────────────────────────────────────────────────────────────────────┘

    AWS STS receives request
         ↓
    AWS validates token signature:
    ✓ Is token signed by GitHub OIDC provider?
         ↓ (Check signature with GitHub's public key)
         ↓
    ✓ Has token expired?
         ↓ (Check exp: 1714297041 > now)
         ↓
    ✓ Is audience correct?
         ↓ (Check aud: "sts.amazonaws.com")
         ↓
    ✓ Is repository in token correct?
         ↓ (Check sub contains "Coder2499/ci..cd_ec2_project")
         ↓
    All checks ✅ PASS


┌─────────────────────────────────────────────────────────────────────┐
│ STEP 7: AWS Validates Role Trust Policy                            │
└─────────────────────────────────────────────────────────────────────┘

    AWS checks github-actions-role's trust policy:
    
    ┌────────────────────────────────────────────┐
    │ Trust Policy:                              │
    │                                            │
    │ Principal: Federated OIDC provider ✓       │
    │   → arn:aws:iam::502580451784:oidc-       │
    │     provider/token.actions.githubusercontent.com
    │                                            │
    │ Condition 1:                               │
    │   token.actions.githubusercontent.com:aud  │
    │   = sts.amazonaws.com ✓                   │
    │                                            │
    │ Condition 2:                               │
    │   token.actions.githubusercontent.com:sub  │
    │   = repo:Coder2499/ci..cd_ec2_project:* ✓ │
    │                                            │
    └────────────────────────────────────────────┘
         ↓
    All conditions ✅ MATCH


┌─────────────────────────────────────────────────────────────────────┐
│ STEP 8: AWS Issues Temporary Credentials                           │
└─────────────────────────────────────────────────────────────────────┘

    AWS STS issues temporary credentials:
    
    ┌────────────────────────────────────────────┐
    │ Credentials Response:                      │
    │                                            │
    │ AccessKeyId:                               │
    │ ASIA4567890EXAMPLE                         │
    │                                            │
    │ SecretAccessKey:                           │
    │ wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY  │
    │                                            │
    │ SessionToken:                              │
    │ AQoDYXdzEJr...[very long token]            │
    │                                            │
    │ Expiration:                                │
    │ 2026-04-28T06:12:21Z (1 hour from now)    │
    │                                            │
    └────────────────────────────────────────────┘
         ↓
    Status: ✅ ISSUED


┌─────────────────────────────────────────────────────────────────────┐
│ STEP 9: Action Writes Credentials to Environment                   │
└─────────────────────────────────────────────────────────────────────┘

    configure-aws-credentials action:
         ↓
    Sets environment variables in runner:
    
    ┌────────────────────────────────────────────┐
    │ AWS_ACCESS_KEY_ID=ASIA4567890EXAMPLE       │
    │ AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI...     │
    │ AWS_SESSION_TOKEN=AQoDYXdzEJr...           │
    │ AWS_REGION=ap-south-1                      │
    │ AWS_ROLE_ARN=arn:aws:iam::502580451784:..  │
    │ AWS_WEB_IDENTITY_TOKEN_FILE=/tmp/token     │
    └────────────────────────────────────────────┘
         ↓
    Next steps in workflow can now access AWS


┌─────────────────────────────────────────────────────────────────────┐
│ STEP 10: Terraform Init & Apply Executes                           │
└─────────────────────────────────────────────────────────────────────┘

    Workflow continues:
    
    - name: Terraform Init
      run: terraform init
           ↓ Uses temporary credentials
           ↓ Downloads modules
           ↓ Initializes state
    
    - name: Terraform Apply
      run: terraform apply -auto-approve
           ↓ Uses temporary credentials
           ↓ Creates EC2 instance in AWS
           ↓ Tags it with environment name
           ↓ All actions logged to CloudTrail


┌─────────────────────────────────────────────────────────────────────┐
│ STEP 11: Workflow Completes                                        │
└─────────────────────────────────────────────────────────────────────┘

    Terraform apply completes ✅
         ↓
    GitHub Actions runner shuts down
         ↓
    Environment variables cleared
         ↓
    Temporary credentials destroyed
         ↓
    Status: ✅ SUCCESS


┌─────────────────────────────────────────────────────────────────────┐
│ STEP 12: Credentials Auto-Expire (Even if forgotten)               │
└─────────────────────────────────────────────────────────────────────┘

    If credentials somehow lingered:
         ↓
    1 hour passes (Expiration: 2026-04-28T06:12:21Z)
         ↓
    AWS automatically revokes credentials
         ↓
    Any further requests fail: "Token has expired"
         ↓
    Status: ✅ AUTO-REVOKED (No manual cleanup!)
```

---

## Key Differences: Before vs After

### ❌ BEFORE (Access Key Method)
```
GitHub Secrets:
  AWS_ACCESS_KEY_ID = AKIAIOSFODNN7EXAMPLE
  AWS_SECRET_ACCESS_KEY = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
  AWS_REGION = ap-south-1

Each Workflow Run:
  ├─ Downloads credentials from secrets
  ├─ Uses same long-lived keys every time
  ├─ No expiration date
  └─ Risk: If leaked, anyone can use it for months

❌ Security: POOR
❌ Rotation: MANUAL (risky)
❌ Audit Trail: LIMITED
```

### ✅ AFTER (OIDC Method)
```
No Secrets Stored Anywhere!

Each Workflow Run:
  ├─ GitHub generates temporary OIDC token (unique per run)
  ├─ Exchanges token for temporary AWS credentials
  ├─ Uses credentials for 1 hour only
  └─ Credentials auto-expire and are destroyed

✅ Security: EXCELLENT
✅ Rotation: AUTOMATIC
✅ Audit Trail: COMPLETE
```

---

## Where Credentials Are At Each Stage

```
STAGE 1: Before workflow
┌─────────────────────────────────────────┐
│ OIDC Token:   NOT EXIST YET             │
│ AWS Creds:    NOT EXIST YET             │
│ GitHub Secrets: EXIST (but not used)    │
└─────────────────────────────────────────┘

STAGE 2: Workflow starts
┌─────────────────────────────────────────┐
│ OIDC Token:   GENERATED ← GitHub        │
│ AWS Creds:    NOT EXIST YET             │
│ GitHub Secrets: NOT USED                │
└─────────────────────────────────────────┘

STAGE 3: Exchanging token
┌─────────────────────────────────────────┐
│ OIDC Token:   SENT TO AWS               │
│ AWS Creds:    BEING ISSUED              │
│ GitHub Secrets: NOT USED                │
└─────────────────────────────────────────┘

STAGE 4: Terraform running
┌─────────────────────────────────────────┐
│ OIDC Token:   EXPIRED (15 min limit)    │
│ AWS Creds:    ACTIVE IN MEMORY          │
│ GitHub Secrets: NOT USED                │
└─────────────────────────────────────────┘

STAGE 5: Workflow completes
┌─────────────────────────────────────────┐
│ OIDC Token:   DESTROYED                 │
│ AWS Creds:    DESTROYED (1 hour expiry) │
│ GitHub Secrets: DELETED (if you do it)  │
└─────────────────────────────────────────┘
```

---

## Summary: What This Means for You

✅ **Every workflow run has unique credentials** - Can't reuse old ones
✅ **Credentials only last 1 hour** - Auto-cleanup, no manual work
✅ **Only your repo can get credentials** - Trust policy restricts access
✅ **Full audit trail in CloudTrail** - Know exactly what happened
✅ **Zero secrets stored** - Nothing to leak or compromise
✅ **Industry standard** - Used by major companies

🎯 **Result: Production-grade security for your CI/CD pipeline!**
