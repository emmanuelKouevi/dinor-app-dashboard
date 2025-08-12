/**
 * UNIFIED_CONTENT_NAVIGATION.DART - NAVIGATION UNIFIÉE POUR CONTENU
 * - Flèches de navigation précédent/suivant
 * - Compatible avec tous les types de contenu (recettes, astuces, événements)
 * - Position au-dessus de la zone de commentaires
 * - Design cohérent avec les autres composants unifiés
 */

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

class UnifiedContentNavigation extends ConsumerWidget {
  final String contentType; // 'recipe', 'tip', 'event'
  final String currentId;
  final String? previousId;
  final String? nextId;
  final String? previousTitle;
  final String? nextTitle;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const UnifiedContentNavigation({
    super.key,
    required this.contentType,
    required this.currentId,
    this.previousId,
    this.nextId,
    this.previousTitle,
    this.nextTitle,
    this.onPrevious,
    this.onNext,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ne pas afficher le composant s'il n'y a ni précédent ni suivant
    if (previousId == null && nextId == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFF0F0F0),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre de la section
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _getContentColor(),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  _getContentIcon(),
                  color: _getContentColor(),
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _getNavigationTitle(),
                style: const TextStyle(
                  fontFamily: 'OpenSans',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3748),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Boutons de navigation
          Row(
            children: [
              // Bouton Précédent
              Expanded(
                child: _buildNavigationButton(
                  onPressed: previousId != null ? onPrevious : null,
                  icon: LucideIcons.chevronLeft,
                  label: 'Précédent',
                  title: previousTitle,
                  isNext: false,
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Bouton Suivant
              Expanded(
                child: _buildNavigationButton(
                  onPressed: nextId != null ? onNext : null,
                  icon: LucideIcons.chevronRight,
                  label: 'Suivant',
                  title: nextTitle,
                  isNext: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required String? title,
    required bool isNext,
  }) {
    final isEnabled = onPressed != null;
    
    return InkWell(
      onTap: isEnabled ? onPressed : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isEnabled 
              ? _getContentColor()
              : const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isEnabled 
                ? _getContentColor()
                : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: isNext ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Label et icône
            Row(
              mainAxisAlignment: isNext ? MainAxisAlignment.end : MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isNext) ...[
                  Icon(
                    icon,
                    size: 16,
                    color: isEnabled ? _getContentColor() : const Color(0xFF9CA3AF),
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'OpenSans',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isEnabled ? _getContentColor() : const Color(0xFF9CA3AF),
                  ),
                ),
                if (isNext) ...[
                  const SizedBox(width: 6),
                  Icon(
                    icon,
                    size: 16,
                    color: isEnabled ? _getContentColor() : const Color(0xFF9CA3AF),
                  ),
                ],
              ],
            ),
            
            // Titre du contenu (si disponible)
            if (title != null && title!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                title!,
                style: TextStyle(
                  fontFamily: 'OpenSans',
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: isEnabled ? const Color(0xFF4A5568) : const Color(0xFF9CA3AF),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: isNext ? TextAlign.end : TextAlign.start,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getNavigationTitle() {
    switch (contentType) {
      case 'recipe':
        return 'Autres recettes';
      case 'tip':
        return 'Autres astuces';
      case 'event':
        return 'Autres événements';
      case 'video':
        return 'Autres vidéos';
      default:
        return 'Autres contenus';
    }
  }

  IconData _getContentIcon() {
    switch (contentType) {
      case 'recipe':
        return LucideIcons.chefHat;
      case 'tip':
        return LucideIcons.lightbulb;
      case 'event':
        return LucideIcons.calendar;
      case 'video':
        return LucideIcons.play;
      default:
        return LucideIcons.bookmark;
    }
  }

  Color _getContentColor() {
    switch (contentType) {
      case 'recipe':
        return const Color(0xFFE53E3E); // Rouge
      case 'tip':
        return const Color(0xFFF4D03F); // Jaune
      case 'event':
        return const Color(0xFF38A169); // Vert
      case 'video':
        return const Color(0xFF9B59B6); // Violet
      default:
        return const Color(0xFF4A5568); // Gris
    }
  }
}