import 'package:flutter/material.dart';

import '../common/badge.dart' as dinor_badge;
import '../../services/image_service.dart';

class UnifiedContentHeader extends StatelessWidget {
  final String imageUrl;
  final String contentType;
  final List<Map<String, String>> badges;
  final double height;
  final BoxFit fit;
  final Widget? customOverlay;

  const UnifiedContentHeader({
    super.key,
    required this.imageUrl,
    required this.contentType,
    this.badges = const [],
    this.height = 300,
    this.fit = BoxFit.cover,
    this.customOverlay,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Image principale
        SizedBox(
          height: height,
          width: double.infinity,
          child: ImageService.buildCachedNetworkImage(
            imageUrl: imageUrl,
            contentType: contentType,
            fit: fit,
          ),
        ),
        
        // Overlay avec dégradé
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black,
                ],
              ),
            ),
          ),
        ),
        
        // Custom overlay si fourni
        if (customOverlay != null)
          Positioned.fill(child: customOverlay!),
        
        // Badges en bas
        if (badges.isNotEmpty)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Row(
              children: badges.map((badge) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: dinor_badge.Badge(
                  text: badge['text']!,
                  icon: badge['icon'] ?? 'tag',
                  variant: badge['variant'] ?? 'secondary',
                  size: badge['size'] ?? 'medium',
                ),
              )).toList(),
            ),
          ),
      ],
    );
  }
}

class UnifiedContentStats extends StatelessWidget {
  final List<Map<String, dynamic>> stats;
  final Color backgroundColor;
  final Color textColor;
  final Color iconColor;

  const UnifiedContentStats({
    super.key,
    required this.stats,
    this.backgroundColor = const Color(0xFFF4D03F),
    this.textColor = const Color(0xFF2D3748),
    this.iconColor = const Color(0xFF2D3748),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            blurRadius: 8,
            offset:Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: stats.map((stat) => _buildStatItem(
          stat['icon'] as IconData,
          stat['text'] as String,
        )).toList(),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String text) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: iconColor,
        ),
        const SizedBox(height: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}