const axios = require("axios");
const https = require("https");

const apiKey = "sk-HRE8NYqwregvjykkelrM2Cv7kvgoJziUdcafULRoeYjEjCda"; // Key from .env

const axiosInstance = axios.create({
    httpsAgent: new https.Agent({
        keepAlive: true,
        maxSockets: Infinity
    }),
    timeout: 30000
});

async function testStability() {
    const targetModel = "stable-diffusion-xl-1024-v1-0";
    const url = `https://api.stability.ai/v1/generation/${targetModel}/text-to-image`;

    console.log(`Hitting ${url}...`);

    const payload = {
        "text_prompts": [
            {
                "text": "A majestic lion",
                "weight": 1
            }
        ],
        "cfg_scale": 7,
        "height": 1024,
        "width": 1024,
        "samples": 1,
        "steps": 30
    };

    try {
        const response = await axiosInstance.post(url, payload, {
            headers: {
                "Authorization": `Bearer ${apiKey}`,
                "Content-Type": "application/json",
                "Accept": "application/json",
            },
        });
        console.log("Success! Status:", response.status);
        // console.log("Data length:", JSON.stringify(response.data).length);
    } catch (error) {
        console.error("Error Status:", error.response ? error.response.status : "No Response");
        console.error("Error Data:", error.response ? JSON.stringify(error.response.data) : error.message);
    }
}

testStability();
