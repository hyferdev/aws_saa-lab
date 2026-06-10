# SAA Sprint — Day 1 Runbook

Goal: a secured AWS account and a GitHub Actions pipeline that runs Terraform
against AWS using **OIDC (no long-lived keys)**. By the end, merging a PR
auto-applies infrastructure.

## Repo layout

```
saa-sprint/
├── bootstrap/        # run ONCE, locally, with admin creds. Creates state
│   │                 # backend + GitHub OIDC provider + CI role.
│   ├── versions.tf
│   ├── variables.tf
│   ├── main.tf
│   └── outputs.tf
├── infra/            # the running project. Grows daily. Applied by CI.
│   ├── backend.tf    # <- paste your state bucket name here after bootstrap
│   └── smoketest.tf  # Day 1 test resource; delete on Day 2
├── .github/workflows/
│   └── terraform.yml # plan on PR, apply on merge to main
└── .gitignore
```

---

## Step 1 — Secure the account (console, ~30–45 min)

Do these by hand once; they can't safely be Terraformed (chicken-and-egg).

1. **Root user:** sign in as root → IAM → enable an MFA device on the root
   user. Then stop using root.
2. **Admin identity:** create an IAM user named `admin` with
   `AdministratorAccess`, console + programmatic access, and its own MFA.
   (IAM Identity Center is the more modern path if you prefer.)
3. **Cost guardrails:**
   - Billing → **Budgets** → create a monthly **cost budget** (e.g. $20) with
     alerts at 80% and 100%. This is the reliable one.
   - Optional CloudWatch billing alarm: enable *Receive Billing Alerts* in
     Billing preferences first, then create the alarm **in us-east-1** (billing
     metrics only live there).
4. **CLI:** `aws configure` with the `admin` user's access key. Verify:
   ```bash
   aws sts get-caller-identity
   ```
   These admin keys are your ONLY long-lived credential. Use them for
   bootstrap only; after that the pipeline uses OIDC. Consider deleting the
   keys afterward and doing future bootstrap edits from AWS CloudShell.

## Step 2 — Create the repo

Create a fresh GitHub repo, then copy the contents of `saa-sprint/` into it
and push the initial commit.

## Step 3 — Run the bootstrap (local, once)

```bash
cd bootstrap
terraform init
terraform apply \
  -var "github_org=YOUR_GH_USERNAME" \
  -var "github_repo=YOUR_REPO_NAME" \
  -var "state_bucket_name=saa-sprint-tfstate-CHANGE-ME-1234"
```

Note the three outputs: `state_bucket`, `lock_table`, `github_role_arn`.
(The bootstrap keeps its state locally — fine for a sandbox.)

## Step 4 — Wire up infra + the pipeline

1. In `infra/backend.tf`, replace `REPLACE_WITH_state_bucket_OUTPUT` with the
   `state_bucket` output value. Confirm `dynamodb_table` matches `lock_table`.
2. In GitHub: repo → Settings → Secrets and variables → Actions → **Variables**
   → add `AWS_ROLE_ARN` = the `github_role_arn` output. (It's a variable, not a
   secret — there's nothing sensitive in a role ARN.)
3. Initialize the remote backend locally and push:
   ```bash
   cd ../infra
   terraform init   # uses the S3 backend now
   ```
4. Open a PR with the repo contents → the workflow runs `terraform plan`.
   Merge it → the workflow runs `terraform apply` and creates the smoke-test
   SSM parameter.

## Checkpoint ✅

- `aws sts get-caller-identity` works.
- Budget alert exists.
- A PR shows a `plan`; merging to `main` runs an `apply`.
- Verify the result:
  ```bash
  aws ssm get-parameter --name /saa-sprint/pipeline-check
  ```

If that parameter exists and no long-lived keys were stored in GitHub, Day 1
is done.

---

## Two things to understand (not just copy)

- **Trust policy vs permissions policy.** The CI role's *trust* is tightly
  scoped to `repo:org/repo:*` — only your workflows can assume it. Its
  *permissions* are broad (AdministratorAccess) as a sandbox shortcut. Knowing
  the difference between "who can assume a role" and "what the role can do" is
  directly tested on the exam.
- **Why no access keys in CI.** OIDC issues a short-lived token per run instead
  of storing a static secret in GitHub. This is the same federation pattern
  behind cross-account roles and identity providers you'll see in Domain 1.
