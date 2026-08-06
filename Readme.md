# Infrastructure and ec2_restart Service

This repository contains Terraform configurations for deploying the necessary AWS infrastructure, as well as a serverless function (AWS Lambda) designed to automatically restart EC2 instances.

---

## 1. Repository Structure

The project structure is divided into two primary blocks: core infrastructure (`modules`) and the serverless function (`lambdas`).

```
infra-actions/
├── lambdas/
│   └── ec2_restart/            # AWS Lambda function module
├── modules/                    # Base infrastructure modules
│   ├── cicd_lambda_role/       # Setup for IAM role and permissions/restrictions for the CI/CD pipeline
│   ├── s3_tf_state/            # Remote S3 bucket creation for storing Terraform state
│   └── ssm_parameters/         # AWS Systems Manager Parameter Store definition for storing secrets
├── .gitignore
└── .gitlab-ci.yml              # CI/CD pipeline for automated Lambda deployment
```

### Core Modules Overview:
* **`modules/cicd_lambda_role`**: Provisions IAM roles and security policies with scoped permissions for deployment pipelines.
* **`modules/s3_tf_state`**: Provisions and configures an S3 bucket to store Terraform state files (`.tfstate`) remotely.
* **`modules/ssm_parameters`**: Defines parameters within AWS SSM Parameter Store for securely managing configurations and secrets.

---

## 2. Manual Module Deployment (Local Machine)

Since the modules inside the `modules/` directory handle core infrastructure, they must be applied **manually from a local machine**.

### Step 1: Generating Access Keys via AWS Console

1. Log in to your **AWS Management Console**.
2. In the top-right corner, click on your profile/account ID and select **Security credentials** (or navigate to **IAM** -> **Users** -> select your IAM user).
3. Switch to the **Access keys** tab.
4. Click **Create access key**.
5. Select **Command Line Interface (CLI)** as the use case, acknowledge the recommendation, and click **Next**.
6. Copy or download the `.csv` file containing:
   * `Access Key ID`
   * `Secret Access Key`

> **Note:** Installing the `aws cli` tool locally is **not required**, as Terraform includes built-in AWS authentication providers and operates as a standalone CLI tool.

---

### Step 2: Exporting Credentials to Terminal Session

Before executing Terraform commands, export the credentials into your active terminal session (`bash` / `zsh`):

```bash
export AWS_ACCESS_KEY_ID="your_access_key_id"
export AWS_SECRET_ACCESS_KEY="your_secret_access_key"
export AWS_DEFAULT_REGION="eu-central-1"
```

---

## Step 3: Prerequisites. Installing Terraform (v1.5.0+)

Before running any deployment commands, ensure you have **Terraform v1.5.0 or higher** installed on your local machine.

### macOS (via Homebrew)

The easiest way to install Terraform on macOS is using [Homebrew](https://brew.sh/):

```bash
# Install the HashiCorp tap
brew tap hashicorp/tap

# Install Terraform
brew install hashicorp/tap/terraform

# Verify installation (Ensure version is 1.5.0+)
terraform -v
````

### Ubuntu / Linux & Other Operating Systems

For Ubuntu, Debian, or other OS distributions, please follow the official HashiCorp step-by-step installation guide:

👉 **[HashiCorp Official Terraform Installation Guide](https://developer.hashicorp.com/terraform/install)**

> **Verification:**  
> After installation, verify the installed version by running:
> ```bash
> terraform -v
> ```
> Make sure the version reported is **1.5.0 or higher**.

---

### Step 4: Applying Modules

For each module in the `modules/` directory (e.g., `cicd_lambda_role`, `s3_tf_state`, `ssm_parameters`), run the following steps:

1. Navigate to the module directory:
   ```bash
   cd modules/cicd_lambda_role
   ```

2. Initialize Terraform:
   ```bash
   terraform init
   ```

3. Review the execution plan:
   ```bash
   terraform plan
   ```

4. Apply the configuration:
   ```bash
   terraform apply
   ```

---

### Important: Configuring GitLab CI/CD Role ARN

After applying the `modules/cicd_lambda_role` module, Terraform will output the ARN of the created IAM Role:

```hcl
output "gitlab_ci_role_arn" {
  value = aws_iam_role.gitlab_ci_role.arn
}
```

This role uses AWS OIDC OpenID Connect federation (`sts:AssumeRoleWithWebIdentity`) to securely authenticate GitLab CI/CD jobs without using static AWS Access Keys.

#### How to set up the Role ARN variable in GitLab:

1. Copy the `gitlab_ci_role_arn` value outputted after running `terraform apply` (or run `terraform output gitlab_ci_role_arn`).
2. Go to your repository in **GitLab**.
3. In the left sidebar, navigate to **Settings** -> **CI/CD**.
4. Expand the **Variables** section.
5. Click **Add variable** and configure the following settings:
   * **Flags / Type:** `Variable`
   * **Key:** `AWS_ROLE_ARN`
   * **Value:** `<paste_copied_role_arn_here>`
   * **Protect variable:** Optional (check if you only run pipelines on protected branches).
   * **Mask variable:** **Unchecked** (Leave **Visible** / unmasked, as IAM Role ARNs do not meet GitLab's regex requirements for masked variables and are safe to remain visible).
6. Click **Add variable** to save.

---

## How to Add a New Lambda Function

To introduce and deploy a new AWS Lambda function to the infrastructure, follow the structured process outlined below:

### 1. Create a Directory Structure
Navigate to the `lambdas/` directory and create a new folder for your service (e.g., `lambdas/my_new_service/`)

---

### 2. Configure Terraform Resources
Write the necessary Terraform configuration inside `main.tf`.

> ⚠️ **CRITICAL SECURITY MANDATE: Permissions Boundary**  
> Any IAM Role created for a Lambda function **MUST** attach the mandatory permissions boundary policy. Without this boundary, the CI/CD pipeline deployment role will fail to provision the IAM role due to scoped permissions restrictions.
>
> Add the `permissions_boundary` argument to every `aws_iam_role` block in your Lambda Terraform code:
>
> ```hcl
> data "aws_caller_identity" "current" {}
> resource "aws_iam_role" "lambda_exec_role" {
>   name = "my_new_service_lambda_role"
>
>   # MANDATORY BOUNDARY ATTACHMENT:
>   permissions_boundary = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/LambdaPermissionsBoundary"
>
>   assume_role_policy = jsonencode({
>     Version = "2012-10-17"
>     Statement = [
>       {
>         Action = "sts:AssumeRole"
>         Effect = "Allow"
>         Principal = {
>           Service = "lambda.amazonaws.com"
>         }
>       }
>     ]
>   })
> }
> ```

---

### 3. Commit and Push Changes
Commit your new Lambda module code and push the changes to your Git repository:

```bash
git add lambdas/my_new_service/
git commit -m "Lambda function description"
git push origin your-feature-branch
```

---

### 4. Automated Deployment via GitLab CI/CD Pipeline
Once your branch is merged into the `master` branch, GitLab CI/CD will detect the new Lambda module and prepare the infrastructure deployment.

The execution step for deploying Lambda Terraform modules requires manual approval in the pipeline:

```yaml
rules:
- if: $CI_COMMIT_BRANCH == "master"
  when: manual
  ```

Upon confirmation, Terraform will execute and provision the new AWS Lambda function along with its associated resources in your AWS environment.
