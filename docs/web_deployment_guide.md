# Web Deployment & Configuration Guide

This guide details the steps required to configure and deploy the Firebase Cloud Functions needed for the Tellulu Web App to communicate with Stability AI.

## Prerequisites

1.  **Firebase CLI**: Ensure you have the Firebase CLI installed.
    ```bash
    npm install -g firebase-tools
    ```
2.  **Node.js**: The functions environment requires Node.js 18.

## Step 1: Initialize Cloud Functions

Navigate to the project root and install the dependencies for the functions.

```bash
cd functions
npm install
cd ..
```

This installs `firebase-functions`, `firebase-admin`, `axios`, and `cors`.

## Step 2: Configure Stability API Key (V2)

The Cloud Function (V2) retrieves your Stability AI API key from the `.env` file in the `functions/` directory.

1.  Create a file named `.env` in the `functions/` folder.
2.  Add your API key:
    ```env
    STABILITY_KEY=sk-YOUR_API_KEY_HERE
    ```

## Step 3: Deploy the Cloud Function

Deploy the functions using the Firebase CLI.

```bash
firebase deploy --only functions
```

**What happens:**
- Firebase uploads the code in `functions/`.
- It creates a Cloud Run service (Gen 2 Function).
- It provides you with a **Function URL**.
  - Example: `https://us-central1-tellulu.cloudfunctions.net/generateStabilityImage`

## Step 4: Verify Project ID (Important)

The Flutter app expects the function to be at:
`https://us-central1-tellulu.cloudfunctions.net/generateStabilityImage`

**If your Firebase project ID is NOT `tellulu`:**
1.  Check your project ID:
    ```bash
    firebase projects:list
    ```
2.  Update `lib/services/stability_service.dart`:
    - Search for `final proxyUrl`.
    - Replace `tellulu` with your actual project ID (e.g., `tellulu-12345`).

## Step 5: Test the Web App

Run the app in Chrome to verify:

```bash
flutter run -d chrome
```

1.  Open the app.
2.  Go to **Create Character** or **Weave Story**.
3.  Generate an image.
4.  Check the browser console (Inspect -> Console) for logs:
    - `🌐 Web detected: calling Cloud Function proxy...`
    - If successful, you will see the image appear.
    - If failed (CORS), ensure the deployment finished and the URL is correct.

## Troubleshooting

- **CORS Error:**
  - Verify the function is deployed.
  - Verify the function URL in `StabilityService.dart` matches your deployed URL.
  
- **500 Internal Server Error:**
  - Check the function logs:
    ```bash
    firebase functions:log
    ```
  - Likely causes: Missing API key config (Step 2) or invalid API key.
