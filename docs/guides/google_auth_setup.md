# Google Auth Setup Guide (Fixing Redirect URI Mismatch)

> [!NOTE]
> This step-by-step guide was extracted from the main Technical Design Document (Appendix A2). It documents the exact steps to configure Google OAuth credentials for Tellulu.

## Step 1: Open the Google Cloud Console
1.  Click this link: [Google Cloud Console - Credentials](https://console.cloud.google.com/apis/credentials)
2.  If asked, sign in with the Google account you used to create the Firebase project.

## Step 2: Select Your Project
1.  Look at the top blue bar, next to the "Google Cloud" logo.
2.  Click the **Project Selector** dropdown (it might say "Select a project" or show a project name).
3.  In the popup window, click the **All** tab.
4.  Find and click on **tellulu** (or `tellulu-12345`).
5.  Click **Open**.

## Step 3: Find the "Web Client"
1.  On the main "Credentials" page, look for the section titled **OAuth 2.0 Client IDs**.
2.  You should see a list of clients. Look for one named:
    - `Web client (auto created by Google Service)` 
    - OR `tellulu (Web)`
    - *Hint: The Client ID will match the one in your error message (`6083...`).*
3.  Click the **Pencil Icon** (Edit) on the right side of that row.

## Step 4: Add Your Website URL
1.  Scroll down to the section **Authorized JavaScript origins**.
2.  Click the **+ ADD URI** button.
3.  In the box that appears, type exactly:
    `https://tellulu.web.app`
4.  (Recommended) Click **+ ADD URI** again and add:
    `https://tellulu.firebaseapp.com`

## Step 5: Add Redirect URI (Crucial for some flows)
1.  Scroll down to the section **Authorized redirect URIs**.
2.  Click the **+ ADD URI** button.
3.  Type exactly:
    `https://tellulu.web.app/__/auth/handler`
4.  Click **+ ADD URI** again and add:
    `https://tellulu.firebaseapp.com/__/auth/handler`

## Step 6: Save and Wait
1.  Scroll to the very bottom and click the blue **SAVE** button.
2.  **Wait 5 Minutes.** Google's servers take a moment to update.
3.  Go back to your deployed app (`https://tellulu.web.app`) in your browser.
4.  **Refresh the page** and try logging in again.
