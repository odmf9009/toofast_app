import 'package:flutter/material.dart';
import '../themes/app_colors.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preguntas Frecuentes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Centro de Ayuda TooFast',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Encuentra respuestas rápidas sobre el funcionamiento de tu radar de ofertas.',
              style: TextStyle(color: AppColors.textGrey, fontSize: 14),
            ),
            const SizedBox(height: 32),
            
            _buildFaqSection('Conceptos Básicos', [
              _buildFaqItem(
                '¿Qué es TooFast?',
                'Es una plataforma inteligente que escanea automáticamente sitios de clasificados (como Revolico) para avisarte en tiempo real cuando alguien publica algo que te interesa.',
              ),
              _buildFaqItem(
                '¿Cómo funciona el radar?',
                'Una vez que configuras tu categoría y palabra clave, la app se conecta de forma invisible a la web cada pocos minutos. Si detecta anuncios nuevos, te envía una notificación inmediata.',
              ),
            ]),

            _buildFaqSection('Membresías y Trial', [
              _buildFaqItem(
                '¿Cuál es la diferencia entre Free y Premium?',
                'Los usuarios FREE escanean cada 1 hora y tienen límites en filtros. Los usuarios PREMIUM disfrutan de escaneos cada 5 minutos, búsqueda exhaustiva en 5 páginas, auto-guardado y filtrado avanzado por frases.',
              ),
              _buildFaqItem(
                '¿Cómo funciona la prueba gratuita de 3 días?',
                'Ofrecemos acceso total Premium por 3 días. Esta prueba es de un solo uso por dispositivo físico (hardware locked) para asegurar un sistema justo para todos.',
              ),
            ]),

            _buildFaqSection('Uso del Radar', [
              _buildFaqItem(
                '¿Por qué no veo los anuncios Destacados?',
                'TooFast ignora automáticamente los anuncios destacados y Premium de la web para centrarse en los anuncios orgánicos de usuarios reales, que es donde suelen estar las verdaderas oportunidades.',
              ),
              _buildFaqItem(
                '¿Qué es la búsqueda exhaustiva?',
                'Cuando usas una palabra clave, el radar navega por las primeras 5 páginas de la categoría elegida buscando coincidencias exactas, en lugar de mirar solo los anuncios más recientes.',
              ),
              _buildFaqItem(
                '¿Cómo contacto a un vendedor?',
                'Cada anuncio detectado muestra iconos de WhatsApp o Teléfono. Al tocarlos, se abrirá directamente el chat o el marcador de tu móvil con el número del vendedor.',
              ),
            ]),

            _buildFaqSection('Soporte y Pagos', [
              _buildFaqItem(
                '¿Es seguro pagar con Stripe?',
                'Sí, TooFast utiliza la pasarela de pagos oficial de Stripe. Tus datos bancarios nunca se guardan en nuestros servidores; todo el proceso es gestionado de forma encriptada por Stripe y Google Pay.',
              ),
              _buildFaqItem(
                '¿Qué hago si el radar no encuentra nada?',
                'Verifica que tu palabra clave no sea demasiado larga (los usuarios FREE tienen límite de 1 palabra) y asegúrate de que el rango de precio sea realista para el producto buscado.',
              ),
            ]),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Text(
            title,
            style: const TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        ...items,
      ],
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Theme(
      data: ThemeData.dark().copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Text(
          question,
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
        ),
        iconColor: AppColors.primary,
        collapsedIconColor: Colors.white54,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              answer,
              style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
