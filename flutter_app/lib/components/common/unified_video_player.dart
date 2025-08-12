import 'package:flutter/material.dart';
import 'youtube_video_modal.dart';

class UnifiedVideoPlayer extends StatelessWidget {
  final String videoUrl;
  final String title;
  final String subtitle;
  final double height;
  final VoidCallback? onTap;

  const UnifiedVideoPlayer({
    super.key,
    required this.videoUrl,
    this.title = 'Regarder la vidéo',
    this.subtitle = 'Appuyez pour ouvrir',
    this.height = 200,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => _openVideo(context),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFF7FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Stack(
          children: [
            // Arrière-plan avec dégradé
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF1A202C),
                    const Color(0xFF2D3748),
                  ],
                ),
              ),
            ),
            // Contenu centré
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'OpenSans',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openVideo(BuildContext context) {
    if (videoUrl.isEmpty) {
      if (context.mounted) {
        _showSnackBar(context, 'URL de la vidéo non disponible', Colors.red);
      }
      return;
    }
    
    // Afficher la modal vidéo YouTube intégrée
    showDialog(
      context: context,
      barrierDismissible: true,
      useRootNavigator: true,
      builder: (context) => YouTubeVideoModal(
        isOpen: true,
        videoUrl: videoUrl,
        title: title,
        onClose: () {
          if (Navigator.of(context, rootNavigator: true).canPop()) {
            Navigator.of(context, rootNavigator: true).pop();
          }
        },
      ),
    );
  }
  

  void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}