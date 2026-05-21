const { onRequest } = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const stripe = require("stripe")(process.env.STRIPE_SECRET_KEY);

exports.createStripePaymentIntent = onRequest({ cors: true }, async (req, res) => {
    // Solo permitir POST
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
            amount: parseInt(amount), // Stripe requiere centavos como entero
            currency: currency,
            payment_method_types: ['card'],
        });

        res.status(200).send({
            client_secret: paymentIntent.client_secret,
        });
    } catch (error) {
        logger.error("Error en Stripe:", error);
        res.status(500).send({ error: error.message });
    }
});
