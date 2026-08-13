# Lambda Cloudflare Cache Purger

## Overview
This tool automates the process of purging Cloudflare cache for `leobit.com` and `leobit.design` directly from Slack. This reduces manual overhead and prevents bottlenecks in infrastructure operations.

## Setup Instructions

### 1. Slack App Configuration
1.  Go to [your Slack Apps dashboard](https://api.slack.com/apps).
2.  Create a new app or select your existing one.
3.  **Disable Socket Mode:** Navigate to **Settings > Socket Mode** and ensure it is **Disabled**.
4.  **Add Slash Command:**
    *   Go to **Features > Slash Commands**.
    *   Click **Create New Command**.
    *   Set the **Command** (e.g., `/purge-cache`).
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
*   `CLOUDFARE_API_TOKEN`: Token with 'Cache Purge' zone permissions.
*   `ZONE_ID`: The specific Zone ID for the domain you are targeting.

## Usage
Once configured, use the slash command in the designated Slack channel:
`/purge-cache`