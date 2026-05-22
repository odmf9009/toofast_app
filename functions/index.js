const { onRequest } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");
const axios = require("axios");

admin.initializeApp();

exports.createStripePaymentIntent = onRequest({ cors: true, secrets: ["STRIPE_SECRET_KEY"] }, async (req, res) => {
    // 1. Limpiar y validar la clave secreta
    const rawKey = process.env.STRIPE_SECRET_KEY || "";
    const cleanKey = rawKey.trim().replace(/['"]+/g, '');

    const stripe = require("stripe")(cleanKey, {
        timeout: 20000, // 20 segundos de timeout
        maxNetworkRetries: 3,
    });

    if (req.method !== 'POST') {
        res.status(405).send('Método no permitido');
        return;
    }

    try {
        const { amount, currency } = req.body;

        if (!amount || !currency) {
            res.status(400).send({ error: 'Faltan parámetros: amount o currency' });
            return;
        }

        logger.info("Iniciando cobro:", { amount, currency });

        const paymentIntent = await stripe.paymentIntents.create({
            amount: parseInt(amount),
            currency: currency,
            payment_method_types: ['card'],
        });

        res.status(200).send({
            client_secret: paymentIntent.client_secret,
        });
    } catch (error) {
        logger.error("Error crítico en conexión con Stripe:", {
            message: error.message,
            type: error.type,
            stack: error.stack
        });
        res.status(500).send({ error: "Error de conexión con la pasarela de pagos. Inténtelo de nuevo." });
    }
});

// Función para activar el scraping manualmente desde una URL
exports.triggerScraper = onRequest({ cors: true }, async (req, res) => {
    try {
        const cantidad = await ejecutarScrapingBanners();
        res.status(200).send(`✅ Scraping completado. Encontradas ${cantidad} imágenes. Revisa tu app.`);
    } catch (error) {
        res.status(500).send("❌ Error: " + error.message);
    }
});

// Función programada (Cada 1 hora)
exports.revolicoScraper = onSchedule("every 1 hours", async (event) => {
    await ejecutarScrapingBanners();
});

async function ejecutarScrapingBanners() {
    logger.info("Iniciando scraping con identidad humana avanzada...");
    try {
        const url = "https://www.revolico.com/";
        const response = await axios.get(url, {
            headers: {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
                'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
                'Accept-Language': 'es-ES,es;q=0.9,en;q=0.8',
                'Cache-Control': 'max-age=0',
                'Sec-Ch-Ua': '"Chromium";v="124", "Google Chrome";v="124", "Not-A.Brand";v="99"',
                'Sec-Ch-Ua-Mobile': '?0',
                'Sec-Ch-Ua-Platform': '"Windows"',
                'Sec-Fetch-Dest': 'document',
                'Sec-Fetch-Mode': 'navigate',
                'Sec-Fetch-Site': 'none',
                'Sec-Fetch-User': '?1',
                'Upgrade-Insecure-Requests': '1',
                'Referer': 'https://www.google.com/'
            }
        });

        const html = response.data;
        let images = [];

        // ESCÁNER DE FUERZA BRUTA
        const regexBroad = /https:\/\/pic\.revolico\.com\/pics\/[^"'\s>]+/g;
        const matches = html.match(regexBroad);

        if (matches) {
            matches.forEach(img => {
                const cleanImg = img.split(' ')[0].split('"')[0].split("'")[0];
                if (cleanImg.includes('.jpg') || cleanImg.includes('.jpeg') || cleanImg.includes('.png')) {
                    if (!images.includes(cleanImg)) images.push(cleanImg);
                }
            });
        }

        if (images.length > 0) {
            const finalUrls = [...new Set(images)].slice(0, 15);
            await admin.firestore().collection('stats').doc('banners').set({
                urls: finalUrls,
                ultima_actualizacion: admin.firestore.FieldValue.serverTimestamp()
            });
            return finalUrls.length;
        }
        return 0;
    } catch (error) {
        logger.error("Error en ejecutarScrapingBanners:", error);
        throw error;
    }
}
