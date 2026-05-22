import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import '../themes/app_colors.dart';

class StripeService {
  StripeService._();

  static final StripeService instance = StripeService._();

  Future<void> makePayment({
    required String amount,
    required String currency,
    required Function(bool) onPaymentResult,
  }) async {
    try {
      print("🚀 Iniciando proceso de pago para: $amount $currency");
      // 1. Crear el Payment Intent en el servidor
      print("📡 Conectando al servidor: https://createstripepaymentintent-lsnpzrbzvq-uc.a.run.app");
      Map<String, dynamic>? paymentIntentData = await _createPaymentIntent(amount, currency);

      if (paymentIntentData != null && paymentIntentData.containsKey('client_secret')) {
        print("✅ Ticket de pago recibido. Inicializando pasarela...");
        // 2. Inicializar la hoja de pago (Payment Sheet)
        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            paymentIntentClientSecret: paymentIntentData['client_secret'],
            merchantDisplayName: 'Toofast App',
            style: ThemeMode.dark,
            // Configuración de Google Pay
            googlePay: const PaymentSheetGooglePay(
              merchantCountryCode: 'US',
              currencyCode: 'USD',
              testEnv: false, // Cambiar a true si estás en modo test
            ),
            appearance: const PaymentSheetAppearance(
              colors: PaymentSheetAppearanceColors(
                primary: AppColors.primary,
              ),
            ),
          ),
        );

        print("💳 Mostrando ventana de pago...");
        await _displayPaymentSheet(onPaymentResult);
      } else {
        print("❌ Error: No se recibió el client_secret del servidor.");
        onPaymentResult(false);
      }
    } catch (e) {
      print("Error detallado en makePayment: $e");
      onPaymentResult(false);
    }
  }

  Future<void> _displayPaymentSheet(Function(bool) onPaymentResult) async {
    try {
      await Stripe.instance.presentPaymentSheet();
      onPaymentResult(true);
    } catch (e) {
      if (e is StripeException) {
        print("Error de Stripe: ${e.error.localizedMessage}");
      } else {
        print("Error inesperado: $e");
      }
      onPaymentResult(false);
    }
  }

  // --- ✅ SEGURIDAD: La Secret Key ha sido movida al servidor ---
  Future<Map<String, dynamic>?> _createPaymentIntent(String amount, String currency) async {
    try {
      const String backendUrl = 'https://createstripepaymentintent-lsnpzrbzvq-uc.a.run.app';

      final response = await http.post(
        Uri.parse(backendUrl),
        body: jsonEncode({
          'amount': _calculateAmount(amount),
          'currency': currency,
        }),
        headers: {
          'Content-Type': 'application/json'
        },
      );

      print("📡 Respuesta del servidor: ${response.statusCode}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print("❌ Error del servidor (${response.statusCode}): ${response.body}");
        return null;
      }
    } catch (e) {
      print("Error conectando al backend: $e");
      return null;
    }
  }

  String _calculateAmount(String amount) {
    final calculatedAmount = (int.parse(amount)) * 100;
    return calculatedAmount.toString();
  }
}
