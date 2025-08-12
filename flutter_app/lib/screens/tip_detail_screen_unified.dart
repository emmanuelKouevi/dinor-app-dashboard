import '../services/navigation_service.dart';
/**
 * TIP_DETAIL_SCREEN_UNIFIED.DART - VERSION UNIFIÉE DU DÉTAIL ASTUCE
 * - Utilise les nouveaux composants unifiés
 * - Interface cohérente avec les autres types de contenu
 * - Pagination des commentaires intégrée
 */

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

// Components unifiés
import '../components/common/accordion.dart';
import '../components/common/image_gallery_carousel.dart';
import '../components/common/unified_content_header.dart';
import '../components/common/unified_video_player.dart';
import '../components/common/unified_comments_section.dart';
import '../components/common/unified_content_actions.dart';
import '../components/common/unified_content_navigation.dart';

// Services
import '../services/api_service.dart';
import '../services/share_service.dart';
import '../services/likes_service.dart';
import '../services/content_navigation_service.dart';
import '../composables/use_auth_handler.dart';
import '../stores/header_state.dart';
import '../services/navigation_service.dart';

class TipDetailScreenUnified extends ConsumerStatefulWidget {
  final String id;
  
  const TipDetailScreenUnified({super.key, required this.id});

  @override
  ConsumerState<TipDetailScreenUnified> createState() => _TipDetailScreenUnifiedState();
}

class _TipDetailScreenUnifiedState extends ConsumerState<TipDetailScreenUnified> with AutomaticKeepAliveClientMixin {
  Map<String, dynamic>? _tip;
  bool _loading = true;
  bool _userLiked = false;
  String? _error;
  
  // Navigation entre contenus
  String? _previousId;
  String? _nextId;
  String? _previousTitle;
  String? _nextTitle;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadTip();
  }


  Future<void> _loadTip({bool forceRefresh = false}) async {
    try {
      setState(() => _loading = true);
      
      final apiService = ref.read(apiServiceProvider);
      final data = forceRefresh 
        ? await apiService.request('/tips/${widget.id}', forceRefresh: true)
        : await apiService.get('/tips/${widget.id}');
        
      if (data['success']) {
        setState(() {
          _tip = data['data'];
          _loading = false;
        });
        
        await _checkUserLike();
        await _loadNavigationInfo();

        // Mettre à jour le sous-titre de l'en-tête avec le titre de l'astuce
        if (mounted && _tip != null) {
          final title = _tip!['title']?.toString();
          if (title != null && title.isNotEmpty) {
            ref.read(headerSubtitleProvider.notifier).state = title;
          }
        }
      } else {
        setState(() {
          _error = data['message'] ?? 'Erreur lors du chargement';
          _loading = false;
        });
      }
    } catch (error) {
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    // Nettoyer le titre immédiatement lors de la destruction du widget
    ref.read(headerSubtitleProvider.notifier).state = null;
    print('🧹 [TipDetail] Titre nettoyé dans dispose()');
    super.dispose();
  }

  Future<void> _checkUserLike() async {
    if (_tip != null) {
      final isLiked = ref.read(likesProvider.notifier).isLiked('tip', widget.id);
      setState(() => _userLiked = isLiked);
    }
  }

  Future<void> _loadNavigationInfo() async {
    try {
      final navigationService = ref.read(contentNavigationServiceProvider);
      final navigationInfo = await navigationService.getNavigationInfo('tip', widget.id);
      
      if (mounted) {
        setState(() {
          _previousId = navigationInfo['previousId'];
          _nextId = navigationInfo['nextId'];
          _previousTitle = navigationInfo['previousTitle'];
          _nextTitle = navigationInfo['nextTitle'];
        });
      }
    } catch (error) {
      print('❌ [TipDetail] Erreur navigation info: $error');
    }
  }

  void _navigateToContent(String contentId) {
    // Navigation vers une autre astuce
    NavigationService.goToTipDetail(contentId);
  }

  Future<void> _handleLikeAction() async {
    final authState = ref.read(useAuthHandlerProvider);
    
    if (!authState.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connectez-vous pour liker cette astuce'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final success = await ref.read(likesProvider.notifier).toggleLike('tip', widget.id);
      
      if (success) {
        setState(() => _userLiked = !_userLiked);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_userLiked ? '❤️ Astuce ajoutée aux favoris' : '💔 Astuce retirée des favoris'),
            backgroundColor: const Color(0xFFE53E3E),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${error.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getDifficultyLabel(String difficulty) {
    const labels = {
      'beginner': 'Débutant',
      'easy': 'Facile',
      'medium': 'Intermédiaire',
      'hard': 'Difficile',
      'expert': 'Expert'
    };
    return labels[difficulty] ?? difficulty;
  }

  String _getTypeLabel(String type) {
    const labels = {
      'cooking': 'Cuisine',
      'preparation': 'Préparation',
      'storage': 'Conservation',
      'technique': 'Technique',
      'equipment': 'Équipement'
    };
    return labels[type] ?? type;
  }

  String _formatTipContent(dynamic content) {
    if (content == null) return '';
    
    if (content is String) return content;
    
    if (content is Map && content['text'] != null) {
      return content['text'];
    }
    
    if (content is Map && content['content'] != null) {
      return content['content'];
    }
    
    if (content is Map && content['description'] != null) {
      return content['description'];
    }
    
    if (content is List) {
      return content.map((item) => _formatTipContent(item)).join('\n\n');
    }
    
    return content.toString();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: _loading
        ? _buildLoadingState()
        : _error != null
          ? _buildErrorState()
          : _tip == null
            ? _buildNotFoundState()
            : _buildTipContent(),
      floatingActionButton: _buildFloatingActionButtons(),
    );
  }

  Widget _buildFloatingActionButtons() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton(
          onPressed: () => NavigationService.pop(),
          heroTag: 'back_fab',
          backgroundColor: Colors.white,
          mini: true,
          child: const Icon(LucideIcons.arrowLeft, color: Color(0xFF2D3748), size: 20),
        ),
        const SizedBox(height: 16),
        // Bouton Like flottant
        FloatingActionButton(
          onPressed: () => _handleLikeAction(),
          heroTag: 'like_fab',
          backgroundColor: _userLiked ? const Color(0xFFE53E3E) : Colors.white,
          mini: true,
          child: Icon(
            _userLiked ? LucideIcons.heart : LucideIcons.heart,
            color: _userLiked ? Colors.white : const Color(0xFFE53E3E),
            size: 20,
          ),
        ),
        const SizedBox(height: 16),
        FloatingActionButton(
          onPressed: () {
            if (_tip != null) {
              ref.read(shareServiceProvider).shareContent(
                type: 'tip',
                id: widget.id,
                title: _tip!['title'] ?? 'Astuce',
                description: _tip!['short_description'] ?? 'Découvrez cette astuce',
                shareUrl: 'https://new.dinorapp.com/pwa/tip/${widget.id}',
                imageUrl: _tip!['featured_image_url'],
              );
            }
          },
          heroTag: 'share_fab',
          backgroundColor: const Color(0xFFE53E3E),
          mini: true,
          child: const Icon(LucideIcons.share2, color: Colors.white, size: 20),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Chargement de l\'astuce...',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.alertCircle,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Erreur lors du chargement',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Une erreur est survenue',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _loadTip(),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFoundState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.alertCircle,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Astuce introuvable',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'L\'astuce demandée n\'existe pas ou a été supprimée.',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => NavigationService.pop(),
            child: const Text('Retour'),
          ),
        ],
      ),
    );
  }

  Widget _buildTipContent() {
    return CustomScrollView(
      slivers: [
        // Hero Image avec composant unifié
        SliverToBoxAdapter(
          child: UnifiedContentHeader(
            imageUrl: _tip!['featured_image_url'] ?? '',
            contentType: 'tip',
            customOverlay: Stack(
              children: [
                // Gradient overlay pour améliorer la lisibilité
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 120,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black,
                          Colors.black,
                        ],
                      ),
                    ),
                  ),
                ),
                // Badges repositionnés
                Positioned(
                  bottom: 20,
                  left: 16,
                  right: 16,
                  child: Row(
                    children: [
                      if (_tip!['difficulty'] != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4D03F),
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black,
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.signal_cellular_alt,
                                size: 14,
                                color: Color(0xFF2D3748),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _getDifficultyLabel(_tip!['difficulty']),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2D3748),
                                  fontFamily: 'Roboto',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (_tip!['category'] != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black,
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.category,
                                size: 14,
                                color: Color(0xFF4A5568),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _tip!['category']['name'] ?? _getTypeLabel(_tip!['type'] ?? ''),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2D3748),
                                  fontFamily: 'Roboto',
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Tip Info
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tip Stats avec composant unifié
                UnifiedContentStats(
                  stats: [
                    // Seulement afficher la difficulté si elle existe
                    if (_tip!['difficulty'] != null) {
                      'icon': LucideIcons.star,
                      'text': _getDifficultyLabel(_tip!['difficulty']),
                    },
                    // Seulement afficher le type si il existe
                    if (_tip!['type'] != null) {
                      'icon': LucideIcons.tag,
                      'text': _getTypeLabel(_tip!['type']),
                    },
                    {
                      'icon': LucideIcons.heart,
                      'text': '${_tip!['likes_count'] ?? 0}',
                    },
                    {
                      'icon': LucideIcons.messageCircle,
                      'text': '${_tip!['comments_count'] ?? 0}',
                    },
                  ],
                ),
                const SizedBox(height: 24),

                // Titre de l'astuce
                Text(
                  _tip!['title'] ?? 'Sans titre',
                  style: const TextStyle(
                    fontFamily: 'OpenSans',
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 16),

                // Description courte
                if (_tip!['short_description'] != null) ...[
                  _buildSection(
                    'Description',
                    Text(
                      _tip!['short_description'],
                      style: const TextStyle(
                        fontFamily: 'OpenSans',
                        fontSize: 16,
                        color: Color(0xFF4A5568),
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Vidéo explicative avec composant unifié
                if (_tip!['video_url'] != null) ...[
                  _buildSection(
                    'Vidéo explicative',
                    UnifiedVideoPlayer(
                      videoUrl: _tip!['video_url'],
                      title: 'Voir la vidéo explicative',
                      subtitle: 'Appuyez pour ouvrir',
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Tip Sections
                _buildTipSections(),

                // Tip Actions avec composant unifié
                const SizedBox(height: 24),
                UnifiedContentActions(
                  contentType: 'tip',
                  contentId: widget.id,
                  title: _tip!['title'] ?? 'Astuce',
                  description: _tip!['short_description'] ?? 'Découvrez cette astuce : ${_tip!['title']}',
                  shareUrl: 'https://new.dinorapp.com/pwa/tip/${widget.id}',
                  imageUrl: _tip!['featured_image_url'],
                  initialLiked: _userLiked,
                  initialLikeCount: _tip!['likes_count'] ?? 0,
                  onRefresh: () => _loadTip(forceRefresh: true),
                  isLoading: _loading,
                ),

                // Navigation entre contenus
                UnifiedContentNavigation(
                  contentType: 'tip',
                  currentId: widget.id,
                  previousId: _previousId,
                  nextId: _nextId,
                  previousTitle: _previousTitle,
                  nextTitle: _nextTitle,
                  onPrevious: _previousId != null ? () => _navigateToContent(_previousId!) : null,
                  onNext: _nextId != null ? () => _navigateToContent(_nextId!) : null,
                ),

                // Comments avec composant unifié
                const SizedBox(height: 24),
                UnifiedCommentsSection(
                  contentType: 'tip',
                  contentId: widget.id,
                  contentTitle: _tip!['title'] ?? 'Astuce',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'OpenSans',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 16),
        content,
      ],
    );
  }

  Widget _buildTipSections() {
    return Column(
      children: [
        // Content Accordion
        if (_tip!['content'] != null)
          Accordion(
            title: 'Contenu',
            initiallyOpen: true,
            child: HtmlWidget(
              _formatTipContent(_tip!['content']),
              textStyle: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 16,
                color: Color(0xFF4A5568),
                height: 1.6,
              ),
            ),
          ),

        // Gallery Carousel
        if (_tip!['gallery_urls'] != null && (_tip!['gallery_urls'] as List).isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: ImageGalleryCarousel(
              images: List<String>.from(_tip!['gallery_urls']),
              title: 'Galerie photos',
              height: 240,
            ),
          ),
      ],
    );
  }
}