import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../themes/app_colors.dart';
import 'oferta_placeholder.dart';

class OfertaCard extends StatelessWidget {
  final Map<String, String> item;
  final bool guardado;
  final bool isLocked;
  final VoidCallback? onFavoriteTap;
  final bool showDeleteIcon;

  const OfertaCard({
    super.key,
    required this.item,
    required this.guardado,
    this.isLocked = false,
    this.onFavoriteTap,
    this.showDeleteIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: isLocked ? null : () async {
        final String? urlString = item['enlace'];
        if (urlString != null && urlString.isNotEmpty) {
          final Uri url = Uri.parse(urlString);
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface, 
          borderRadius: BorderRadius.circular(12), 
          border: Border.all(color: AppColors.border)
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: (item['imagen'] != null && item['imagen']!.isNotEmpty)
                  ? Image.network(
                      item['imagen']!,
                      width: 85,
                      height: 85,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => buildPlaceholder(),
                    )
                  : buildPlaceholder(),
              ),
            ),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(item['titulo'] ?? 'Sin título', 
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white), 
                          maxLines: 2, 
                          overflow: TextOverflow.ellipsis
                        )
                      ),
                      const SizedBox(width: 10),
                      Text('\$${item['precio'] ?? '0'}', 
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.secondary)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(item['detalles'] ?? '',
                    style: const TextStyle(fontSize: 12, color: AppColors.textLightGrey, height: 1.4), 
                    maxLines: 2, 
                    overflow: TextOverflow.ellipsis
                  ),
                  

                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.access_time, color: AppColors.premiumGold, size: 13),
                                const SizedBox(width: 4),
                                Text(item['tiempo'] ?? '', 
                                  style: const TextStyle(color: AppColors.textGrey, fontSize: 10)),
                                if (item['visitas'] != null && item['visitas']!.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  const Icon(Icons.remove_red_eye_outlined, color: AppColors.secondary, size: 13),
                                  const SizedBox(width: 4),
                                  Text('${item['visitas']}', style: const TextStyle(color: AppColors.textGrey, fontSize: 10)),
                                ],
                                const SizedBox(width: 8),
                                const Icon(Icons.open_in_new, color: AppColors.primary, size: 12),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined, color: AppColors.shieldBlue, size: 13),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(item['ubicacion'] ?? '', 
                                    style: const TextStyle(color: AppColors.textGrey, fontSize: 10, overflow: TextOverflow.ellipsis))
                                ),
                              ],
                            ),
                            if ((item['whatsapp'] != null && item['whatsapp']!.isNotEmpty) || (item['telefono'] != null && item['telefono']!.isNotEmpty)) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  if (item['whatsapp'] != null && item['whatsapp']!.isNotEmpty)
                                    GestureDetector(
                                      onTap: () async {
                                        final number = item['whatsapp'];
                                        final url = Uri.parse("https://wa.me/$number");
                                        if (await canLaunchUrl(url)) {
                                          await launchUrl(url, mode: LaunchMode.externalApplication);
                                        }
                                      },
                                      child: const Padding(
                                        padding: EdgeInsets.only(right: 12.0),
                                        child: Icon(Icons.forum_outlined, color: Colors.greenAccent, size: 16),
                                      ),
                                    ),
                                  if (item['telefono'] != null && item['telefono']!.isNotEmpty)
                                    GestureDetector(
                                      onTap: () async {
                                        final String number = item['telefono']!;
                                        // Aseguramos que el número tenga el formato tel: para el dialer
                                        final Uri url = Uri.parse("tel:$number");
                                        if (await canLaunchUrl(url)) {
                                          await launchUrl(url);
                                        } else {
                                          // Intento forzado si canLaunchUrl falla
                                          await launchUrl(url);
                                        }
                                      },
                                      child: const Icon(Icons.phone_enabled, color: AppColors.primary, size: 15),
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                            showDeleteIcon ? Icons.delete_outline : (guardado ? Icons.favorite : Icons.favorite_border),
                            color: showDeleteIcon ? AppColors.errorRed : (guardado ? AppColors.primary : AppColors.textGrey),
                            size: 20
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: isLocked ? null : onFavoriteTap,
                      )
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
