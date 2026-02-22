const { onRequest } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const axios = require("axios");
const https = require("https");

admin.initializeApp();

// Create a shared axios instance
// explicit IPv4 to avoid "name resolver error" in some GC environments
const axiosInstance = axios.create({
    timeout: 30000, // 30s timeout
    family: 4,      // Force IPv4
});

// Proxy function to call Stability AI API
// Increased timeout to 300s to handle multiple retries
exports.generateStabilityImage = onRequest({ cors: true, timeoutSeconds: 300, memory: "1GiB" }, async (req, res) => {
    try {
        // 1. Validate Method
        if (req.method !== "POST") {
            return res.status(405).send("Method Not Allowed");
        }

        // 2. Get API Key
        const apiKey = process.env.STABILITY_KEY;
        if (!apiKey) {
            console.error("Missing process.env.STABILITY_KEY");
            return res.status(500).json({ error: "Server Configuration Error: API Key missing." });
        }

        // 3. Extract and Sanitize Payload
        const body = req.body || {};
        const rawModelId = body.modelId;
        console.log("Received Payload:", JSON.stringify(body)); // DIAGNOSTIC LOG

        // Sanitize modelId
        const targetModel = (rawModelId ? String(rawModelId).trim() : "stable-diffusion-xl-1024-v1-0");
        console.log(`Target Model (Sanitized): "${targetModel}"`);

        // Construct URL
        const url = `https://api.stability.ai/v1/generation/${targetModel}/text-to-image`;

        // Prepare Stability Payload (exclude modelId, ensure types)
        const { modelId, ...rest } = body;
        const payload = {
            text_prompts: rest.text_prompts || [],
            cfg_scale: Number(rest.cfg_scale || 7),
            height: Number(rest.height || 1024),
            width: Number(rest.width || 1024),
            samples: Number(rest.samples || 1),
            steps: Number(rest.steps || 30),
        };

        // [FIX] Explicitly forward style_preset (do NOT rely on ...rest spread)
        if (rest.style_preset) {
            payload.style_preset = String(rest.style_preset).trim();
            console.log(`Style Preset: "${payload.style_preset}"`);
        } else {
            console.log("No style_preset provided.");
        }

        // Forward seed if provided
        if (rest.seed !== undefined && rest.seed !== null) {
            payload.seed = Number(rest.seed);
        }

        console.log("Final Payload to Stability:", JSON.stringify(payload));

        // Retry logic for 503 Service Unavailable (upstream flakes)
        const MAX_RETRIES = 3;
        let attempt = 0;
        let successData;

        while (attempt < MAX_RETRIES) {
            try {
                const response = await fetch(url, {
                    method: 'POST',
                    headers: {
                        "Authorization": `Bearer ${apiKey}`,
                        "Content-Type": "application/json",
                        "Accept": "application/json",
                        "User-Agent": "Tellulu-App/1.0 (Firebase/Node)"
                    },
                    body: JSON.stringify(payload)
                });

                if (!response.ok) {
                    // Check for retryable status codes
                    if (response.status === 503 || response.status === 504) {
                        const text = await response.text(); // consume body to avoid leaks?
                        throw new Error(`Stability API Error: ${response.status} - ${text}`);
                    }

                    // Non-retryable error
                    const errorJson = await response.json().catch(() => ({}));
                    return res.status(response.status).json(errorJson);
                }

                successData = await response.json();
                break; // Success

            } catch (error) {
                // Network errors (fetch throws on network failure, DNS, etc.) or our thrown 503s
                attempt++;
                console.warn(`Attempt ${attempt} failed: ${error.message}. RetryingIn ${attempt * 1000}ms...`);

                if (attempt < MAX_RETRIES) {
                    await new Promise(resolve => setTimeout(resolve, attempt * 1000));
                    continue;
                }
                // If max retries reached, throw request error
                throw error;
            }
        }

        // 4. Return Response
        res.status(200).json(successData);

    } catch (error) {
        console.error("Global Catch Error:", error.message);
        res.status(500).json({
            error: "Stability API Error",
            details: { message: error.message }
        });
    }
});
