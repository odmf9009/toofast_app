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

// Función programada para escaneos cada 1 hora
exports.revolicoScraper = onSchedule("every 1 hours", async (event) => {
    logger.info("Iniciando scraping programado de Revolico para banners...");

    try {
        const categories = ['vehiculos', 'tecnologia', 'electrodomesticos', 'hogar'];
        const randomCat = categories[Math.floor(Math.random() * categories.length)];
        const url = `https://www.revolico.com/search?category=${randomCat}`;

        const response = await axios.get(url, {
            headers: {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
            }
        });

        const html = response.data;
        if (!html.includes('id="__NEXT_DATA__"')) {
            throw new Error("No se encontró el bloque de datos __NEXT_DATA__");
        }

        const jsonString = html.split('id="__NEXT_DATA__"')[1].split('>')[1].split('</script>')[0].trim();
        const data = JSON.parse(jsonString);

        const apolloState = data.props.pageProps.__APOLLO_STATE__;
        const images = [];

        // Extraer imágenes de los anuncios que tengan permalink e imagen
        for (const key in apolloState) {
            const item = apolloState[key];
            if (item.typename === 'Ad' || (item.title && item.price)) {
                // Buscamos algo que parezca una URL de imagen
                // En Revolico a veces vienen en campos como images o se construyen
                // Por sencillez, buscaremos los anuncios destacados que suelen tener imagen
                if (item.images && item.images.length > 0) {
                    const imgUrl = item.images[0].url || item.images[0];
                    if (imgUrl && typeof imgUrl === 'string' && imgUrl.startsWith('http')) {
                        images.push(imgUrl);
                    }
                }
                if (images.length >= 15) break;
            }
        }

        if (images.length > 0) {
            // Guardar en Firestore
            await admin.firestore().collection('stats').doc('banners').set({
                urls: images.slice(0, 10),
                ultima_actualizacion: admin.firestore.FieldValue.serverTimestamp()
            });
            logger.info(`Scraping exitoso: ${images.length} imágenes guardadas.`);
        } else {
            logger.warn("No se encontraron imágenes en este ciclo.");
        }

    } catch (error) {
        logger.error("Error en revolicoScraper:", error);
    }
});
