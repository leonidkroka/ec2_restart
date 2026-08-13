# Lambda EC2 instance restarter

## Overview
This tool automates the process of EC2 instance restarting

## Setup Instructions

### 1. Slack App Configuration
1.  Go to [your Slack Apps dashboard](https://api.slack.com/apps).
2.  Create a new app or select your existing one.
3.  **Disable Socket Mode:** Navigate to **Settings > Socket Mode** and ensure it is **Disabled**.
4.  **Add Slash Command:**
    *   Go to **Features > Slash Commands**.
    *   Click **Create New Command**.
    *   Set the **Command** (e.g., `/ec2-restart`).
    *   In the **Request URL** field, paste the Lambda URL obtained from the deployment pipeline (see Section 3).
5.  **Get Signing Secret:**
    *   Navigate to **Settings > Basic Information**.
    *   Scroll to **App Credentials** and copy the **Signing Secret**. You will need this for the Lambda environment variables.

### 2. Install App to Workspace
1.  Go to **Settings > Install App**.
2.  Click **Install to Workspace**.
3.  Authorize the permissions as prompted.

### 3. Get Required IDs
*   **Channel ID:** Open the Slack channel where you intend to trigger the command, click on the channel name/header, and copy the **Channel ID** from the bottom of the popup.
*   **Lambda URL:** Trigger your deployment pipeline for the `cicd_lambda` role. Once the deployment is successful, copy the generated **Function URL** from the AWS Lambda console or pipeline output.

### 4. Configuration
Ensure the following variables are set in your Lambda environment:
*   `SLACK_SIGNING_SECRET`: From Slack App Credentials.
*   `SLACK_CHANNEL_ID`: Authorized Slack channel ID for triggering Lambda.
*   `EC2_INSTANCE_ID`: AWS EC2 instance ID to be restarted.

## Usage
Once configured, use the slash command in the designated Slack channel:
`/ec2-restart`

> **Troubleshooting Note:** If Slack returns `403 Forbidden` or `Internal Server Error`, go to the AWS Lambda Console -> **Configuration** -> **Function URL**, click **Edit**, ensure Auth type is set to **NONE**, and save the settings to refresh the resource policy.