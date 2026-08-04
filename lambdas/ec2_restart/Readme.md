# AWS EC2 Slack Restarter

A lightweight tool for rebooting AWS EC2 instances via Slack Slash Commands using AWS Lambda and Terraform.

---

## 🚀 Deployment Steps

### 1. Configure Terraform Variables

Open `main.tf` and set your specific configuration values (lines 73–75):

* **`main.tf:73`** — Target EC2 Instance ID (e.g., `i-014a14322c65e9487`)
* **`main.tf:74`** — Slack Signing Secret for request verification
* **`main.tf:75`** — AWS Region (e.g., `eu-central-1`)
* **`main.tf:76`** — Slack Channel ID (e.g., `C01R2XXXXXX`)

---

### 2. Export AWS Credentials

Export your AWS credentials to your environment variables:

```bash
export AWS_ACCESS_KEY_ID="AAAA"
export AWS_SECRET_ACCESS_KEY="9AAAA"
export AWS_DEFAULT_REGION="eu-central-1"
```

### 3. Deploy Infrastructure via Terraform

Initialize and apply the Terraform configuration:

```bash
terraform init
terraform plan
terraform apply
```

> **Save the Output:** Once `terraform apply` finishes successfully, copy the **Lambda Function URL** provided in the terminal output.

---

### 4. Create and Configure Slack App

1. Go to [Slack API Apps](https://api.slack.com/apps) and click **Create New App**.
2. **Disable Socket Mode:** In the *Socket Mode* section, ensure the toggle is set to `Disabled`.
3. **Add Slash Command:**
    * Navigate to **Slash Commands** -> **Create New Command**.
    * Enter your preferred command name (e.g., `/restart-ec2`).
    * In the **Request URL** field, paste the URL obtained from **Step 3**:
      `https://<YOUR-LAMBDA-URL>.lambda-url.eu-central-1.on.aws/`

---

### 5. Install the Slack App

1. Navigate to **Install App** in the left sidebar menu of the Slack API dashboard.
2. Click **Install to Workspace** and authorize the permissions.
3. Done! You can now trigger `/restart-ec2` directly from your Slack channels.

> **Troubleshooting Note:** If Slack returns `403 Forbidden` or `Internal Server Error`, go to the AWS Lambda Console -> **Configuration** -> **Function URL**, click **Edit**, ensure Auth type is set to **NONE**, and save the settings to refresh the resource policy.
