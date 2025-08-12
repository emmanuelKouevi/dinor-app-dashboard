import '../services/navigation_service.dart';
/**
 * RECIPE_DETAIL_SCREEN.DART - CONVERSION FIDÈLE DE RecipeDetail.vue
 * 
 * FIDÉLITÉ VISUELLE :
 * - Hero image identique avec overlay et badges
 * - Recipe stats identiques : temps, personnes, likes, commentaires
 * - Accordions identiques : ingrédients, instructions, galerie, commentaires
 * - Vidéos embarquées : YouTube et Vimeo
 * - Couleurs identiques : #FFFFFF fond, #F4D03F doré, #FF6B35 orange
 * - Polices identiques : Roboto textes, Open Sans titres
 * 
 * FIDÉLITÉ FONCTIONNELLE :
 * - Setup() identique : composables pour données
 * - Handlers identiques : like, commentaire, partage
 * - AuthModal : même gestion d'authentification
 * - Refresh system : même système de rafraîchissement
 */

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../components/common/youtube_video_modal.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

// Components unifiés
import '../components/common/accordion.dart';
import '../components/common/image_lightbox.dart';
import '../components/common/image_gallery_carousel.dart';
import '../components/common/unified_content_header.dart';
import '../components/common/unified_video_player.dart';
import '../components/common/unified_comments_section.dart';
import '../components/common/unified_content_actions.dart';
import '../components/common/unified_like_button.dart';
import '../components/common/badge.dart' as DinorBadge;

// Services et composables
import '../services/api_service.dart';
import '../services/offline_service.dart';
import '../services/image_service.dart';
import '../services/comments_service.dart';
import '../composables/use_comments.dart';
import '../composables/use_auth_handler.dart';
import '../composables/use_social_share.dart';

class RecipeDetailScreen extends ConsumerStatefulWidget {
  final String id;
  
  const RecipeDetailScreen({Key? key, required this.id}) : super(key: key);

  @override
  ConsumerState<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends ConsumerState<RecipeDetailScreen> with AutomaticKeepAliveClientMixin {
  // État identique au setup() Vue
  bool _showAuthModal = false;
  bool _showShareModal = false;
  bool _showLightbox = false;
  int _lightboxIndex = 0;
  
  // Données de la recette
  Map<String, dynamic>? _recipe;
  List<dynamic> _comments = [];
  
  // États de chargement
  bool _loading = true;
  bool _userLiked = false;
  bool _userFavorited = false;
  
  // Erreurs
  String? _error;
  bool _isOffline = false;

  // Commentaires
  final TextEditingController _commentController = TextEditingController();
  
  // Services
  final OfflineService _offlineService = OfflineService();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    
    print('🍳 [RecipeDetailScreen] Écran détail recette initialisé ID: ${widget.id}');
    _loadRecipe();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // REPRODUCTION EXACTE du chargement de données Vue avec support hors ligne
  Future<void> _loadRecipe({bool forceRefresh = false}) async {
    try {
      print('🔄 [RecipeDetailScreen] Chargement recette ID: ${widget.id}, ForceRefresh: $forceRefresh');
      setState(() => _loading = true);
      
      final result = await _offlineService.loadDetailWithOfflineSupport(
        endpoint: 'https://new.dinorapp.com/api/v1/recipes/${widget.id}',
        cacheKey: 'recipe_detail',
        id: widget.id,
      );
        
      if (result['success']) {
        setState(() {
          _recipe = result['data'];
          _loading = false;
          _isOffline = result['offline'] ?? false;
        });
        
        // Charger les commentaires
        await _loadComments();
        await _checkUserLike();
        await _checkUserFavorite();
        
        // Afficher un indicateur si en mode hors ligne
        if (result['offline'] == true) {
          _showOfflineIndicator();
        }
        
        print('✅ [RecipeDetailScreen] Recette chargée avec succès');
      } else {
        setState(() {
          _error = result['error'];
          _loading = false;
        });
      }
    } catch (error) {
      print('❌ [RecipeDetailScreen] Erreur lors du chargement de la recette: $error');
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadComments() async {
    try {
      await ref.read(commentsServiceProvider.notifier).loadComments('recipe', widget.id);
      final commentsState = ref.read(commentsServiceProvider)[('recipe_${widget.id}')];
      if (commentsState != null) {
        setState(() => _comments = commentsState.comments.map((c) => c.toJson()).toList());
      }
    } catch (error) {
      print('❌ [RecipeDetailScreen] Erreur chargement commentaires: $error');
    }
  }

  Future<void> _checkUserLike() async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final data = await apiService.get('/likes/check', params: {
        'type': 'recipe',
        'id': widget.id
      });
      setState(() => _userLiked = data['success'] && data['is_liked']);
    } catch (error) {
      print('❌ [RecipeDetailScreen] Erreur vérification like: $error');
    }
  }

  Future<void> _checkUserFavorite() async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final data = await apiService.get('/favorites/check', params: {
        'type': 'recipe',
        'id': widget.id
      });
      setState(() => _userFavorited = data['success'] && data['is_favorited']);
    } catch (error) {
      print('❌ [RecipeDetailScreen] Erreur vérification favori: $error');
    }
  }

  void _showOfflineIndicator() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text('Mode hors ligne - Données en cache'),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;
    
    try {
      print('📝 [RecipeDetailScreen] Envoi du commentaire pour Recipe: ${widget.id}');
      
      final success = await ref.read(commentsServiceProvider.notifier).addComment(
        'recipe', 
        widget.id, 
        _commentController.text.trim()
      );
      
      if (success) {
        _commentController.clear();
        await _loadComments(); // Recharger les commentaires
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Commentaire ajouté avec succès'),
              backgroundColor: Color(0xFF38A169),
              duration: Duration(seconds: 2),
            ),
          );
        }
        
        print('✅ [RecipeDetailScreen] Commentaire ajouté avec succès');
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors de l\'ajout du commentaire'),
              backgroundColor: Color(0xFFE53E3E),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (error) {
      print('❌ [RecipeDetailScreen] Erreur lors de l\'ajout du commentaire: $error');
      
      // Si erreur 401, demander connexion
      if (error.toString().contains('401') || error.toString().contains('connecté')) {
        setState(() => _showAuthModal = true);
      }
    }
  }

  Future<void> _deleteComment(String commentId) async {
    try {
      await ref.read(useCommentsProvider.notifier).deleteComment(commentId);
      await _loadComments(); // Recharger les commentaires
    } catch (error) {
      print('❌ [RecipeDetailScreen] Erreur suppression commentaire: $error');
    }
  }

  Future<void> _forceRefresh() async {
    print('🔄 [RecipeDetailScreen] Rechargement forcé demandé');
    setState(() => _loading = true);
    try {
      await _loadRecipe(forceRefresh: true);
      print('✅ [RecipeDetailScreen] Rechargement forcé terminé');
    } catch (error) {
      print('❌ [RecipeDetailScreen] Erreur lors du rechargement forcé: $error');
    }
  }

  void _goBack() {
    NavigationService.pop();
  }

  void _callShare() {
    if (_recipe == null) return;
    
    final shareData = {
      'title': _recipe!['title'],
      'text': _recipe!['description'] ?? 'Découvrez cette délicieuse recette : ${_recipe!['title']}',
      'url': 'https://new.dinorapp.com/pwa/recipe/${widget.id}',
      'image': _recipe!['featured_image_url'],
    };
    
    Share.share(
      '${shareData['title']}\n\n${shareData['text']}\n\n${shareData['url']}',
      subject: shareData['title'],
    );
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

  String _formatDate(String date) {
    return DateTime.parse(date).toLocal().toString().split(' ')[0];
  }

  void _openVideo(String videoUrl) {
    print('🎥 [RecipeDetail] _openVideo appelé avec URL: $videoUrl');
    
    if (videoUrl.isEmpty) {
      print('❌ [RecipeDetail] URL vidéo vide');
      _showSnackBar('URL de la vidéo non disponible', Colors.red);
      return;
    }
    
    print('🎬 [RecipeDetail] Ouverture vidéo intégrée avec autoplay');
    
    // Afficher la modal vidéo YouTube intégrée avec autoplay
    showDialog(
      context: context,
      barrierDismissible: true,
      useRootNavigator: true,
      builder: (context) => YouTubeVideoModal(
        isOpen: true,
        videoUrl: videoUrl,
        title: _recipe?['title'] ?? 'Vidéo de la recette',
        onClose: () {
          if (Navigator.of(context, rootNavigator: true).canPop()) {
            Navigator.of(context, rootNavigator: true).pop();
          }
        },
      ),
    );
  }
  

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatIngredientDisplay(dynamic ingredient) {
    if (ingredient == null) return '';
    
    String result = '';
    
    // Ajouter la quantité si elle existe
    if (ingredient['quantity'] != null) {
      result += '${ingredient['quantity']} ';
    }
    
    // Ajouter l'unité si elle existe
    if (ingredient['unit'] != null) {
      result += '${ingredient['unit']} ';
    }
    
    // Ajouter le nom de l'ingrédient
    if (ingredient['name'] != null) {
      result += 'de ${ingredient['name']}';
    }
    
    // Ajouter les notes si elles existent
    if (ingredient['notes'] != null) {
      result += ' (${ingredient['notes']})';
    }
    
    // Ajouter la marque recommandée si elle existe
    if (ingredient['recommended_brand'] != null) {
      result += ' [${ingredient['recommended_brand']}]';
    }
    
    return result.trim();
  }

  String _formatInstructions(dynamic instructions) {
    if (instructions == null) return '';
    
    // Si c'est déjà une chaîne, la retourner
    if (instructions is String) return instructions;
    
    // Si c'est un array d'objets, les formater
    if (instructions is List) {
      return instructions.asMap().entries.map((entry) {
        final index = entry.key;
        final instruction = entry.value;
        
        if (instruction is Map && instruction['step'] != null) {
          return '<div class="instruction-step"><h4>Étape ${index + 1}</h4><p>${instruction['step']}</p></div>';
        } else if (instruction is String) {
          return '<div class="instruction-step"><h4>Étape ${index + 1}</h4><p>$instruction</p></div>';
        }
        return '<div class="instruction-step"><p>$instruction</p></div>';
      }).join('');
    }
    
    return instructions.toString();
  }

  void _openGalleryModal(int index) {
    if (_recipe?['gallery_urls']?[index] != null) {
      setState(() {
        _lightboxIndex = index;
        _showLightbox = true;
      });
    }
  }
  
  void _closeLightbox() {
    setState(() => _showLightbox = false);
  }

  bool _canDeleteComment(dynamic comment) {
    // Logique pour vérifier si l'utilisateur peut supprimer le commentaire
    // À implémenter selon votre logique d'authentification
    return false;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFFFFFFFF),
          body: _loading
            ? _buildLoadingState()
            : _error != null
              ? _buildErrorState()
              : _recipe == null
                ? _buildNotFoundState()
                : _buildRecipeContent(),
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
            'Chargement de la recette...',
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
            onPressed: () => _loadRecipe(),
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
            'Recette introuvable',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'La recette demandée n\'existe pas ou a été supprimée.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _goBack,
            child: const Text('Retour'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeContent() {
    return CustomScrollView(
      slivers: [
        // Hero Image avec composant unifié
        SliverToBoxAdapter(
          child: UnifiedContentHeader(
            imageUrl: _recipe!['featured_image_url'] ?? '',
            contentType: 'recipe',
            customOverlay: Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  if (_recipe!['difficulty'] != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4D03F),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getDifficultyLabel(_recipe!['difficulty']),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (_recipe!['category'] != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _recipe!['category']['name'],
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        // Recipe Info
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Recipe Stats avec composant unifié
                UnifiedContentStats(
                  stats: [
                    {
                      'icon': LucideIcons.clock,
                      'text': '${_recipe!['cooking_time'] ?? 0}min',
                    },
                    {
                      'icon': LucideIcons.users,
                      'text': '${_recipe!['servings'] ?? 0} pers.',
                    },
                    {
                      'icon': LucideIcons.heart,
                      'text': '${_recipe!['likes_count'] ?? 0}',
                    },
                    {
                      'icon': LucideIcons.messageCircle,
                      'text': '${_recipe!['comments_count'] ?? 0}',
                    },
                  ],
                ),
                const SizedBox(height: 16),
                
                // Indicateur hors ligne
                if (_isOffline) _buildOfflineIndicator(),
                if (_isOffline) const SizedBox(height: 16),
                
                const SizedBox(height: 24),

                // Description
                if (_recipe!['description'] != null) ...[
                  _buildSection(
                    'Description',
                    HtmlWidget(_recipe!['description']),
                  ),
                  const SizedBox(height: 24),
                ],

                // Summary Video avec composant unifié
                if (_recipe!['summary_video_url'] != null) ...[
                  _buildSection(
                    'Résumé en vidéo',
                    UnifiedVideoPlayer(
                      videoUrl: _recipe!['summary_video_url'],
                      title: 'Voir le résumé en vidéo',
                      subtitle: 'Appuyez pour ouvrir',
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Main Video avec composant unifié
                if (_recipe!['video_url'] != null) ...[
                  _buildSection(
                    'Vidéo de la recette',
                    UnifiedVideoPlayer(
                      videoUrl: _recipe!['video_url'],
                      title: 'Voir la recette en vidéo',
                      subtitle: 'Appuyez pour ouvrir',
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Recipe Sections
                _buildRecipeSections(),

                // Recipe Actions avec composant unifié
                const SizedBox(height: 24),
                UnifiedContentActions(
                  contentType: 'recipe',
                  contentId: widget.id,
                  title: _recipe!['title'] ?? 'Recette',
                  description: _recipe!['description'] ?? 'Découvrez cette délicieuse recette : ${_recipe!['title']}',
                  shareUrl: 'https://new.dinorapp.com/pwa/recipe/${widget.id}',
                  imageUrl: _recipe!['featured_image_url'],
                  initialLiked: _userLiked,
                  initialLikeCount: _recipe!['likes_count'] ?? 0,
                  onAuthRequired: () => setState(() => _showAuthModal = true),
                  onRefresh: _forceRefresh,
                  isLoading: _loading,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroImage() {
    return Stack(
      children: [
        SizedBox(
          height: 300,
          width: double.infinity,
          child: ImageService.buildCachedNetworkImage(
            imageUrl: _recipe!['featured_image_url'] ?? '',
            contentType: 'recipe',
            fit: BoxFit.cover,
          ),
        ),
        // Recipe Overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
          ),
        ),
        // Recipe Badges
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Row(
            children: [
              if (_recipe!['difficulty'] != null)
                DinorBadge.Badge(
                  text: _getDifficultyLabel(_recipe!['difficulty']),
                  icon: 'restaurant',
                  variant: 'secondary',
                  size: 'medium',
                ),
              const SizedBox(width: 8),
              if (_recipe!['category'] != null)
                DinorBadge.Badge(
                  text: _recipe!['category']['name'],
                  icon: 'tag',
                  variant: 'neutral',
                  size: 'medium',
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecipeStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4D03F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            LucideIcons.clock,
            '${_recipe!['cooking_time'] ?? 0}min',
          ),
          _buildStatItem(
            LucideIcons.users,
            '${_recipe!['servings'] ?? 0} pers.',
          ),
          _buildStatItem(
            LucideIcons.heart,
            '${_recipe!['likes_count'] ?? 0}',
          ),
          _buildStatItem(
            LucideIcons.messageCircle,
            '${_recipe!['comments_count'] ?? 0}',
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String text) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: const Color(0xFF2D3748),
        ),
        const SizedBox(height: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2D3748),
          ),
        ),
      ],
    );
  }

  Widget _buildOfflineIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.wifi_off,
            size: 16,
            color: Colors.orange[700],
          ),
          const SizedBox(width: 8),
          Text(
            'Mode hors ligne - Données en cache',
            style: TextStyle(
              fontSize: 12,
              color: Colors.orange[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
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

  Widget _buildVideoContainer(String videoUrl) {
    return GestureDetector(
      onTap: () => _openVideo(videoUrl),
      child: Container(
        height: 200,
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
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF1A202C).withOpacity(0.8),
                    const Color(0xFF2D3748).withOpacity(0.6),
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
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Regarder la vidéo',
                    style: TextStyle(
                      fontFamily: 'OpenSans',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Appuyez pour ouvrir',
                    style: TextStyle(
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

  Widget _buildRecipeSections() {
    return Column(
      children: [
        // Ingredients Accordion
        if (_recipe!['ingredients'] != null && (_recipe!['ingredients'] as List).isNotEmpty)
          Accordion(
            title: 'Ingrédients',
            initiallyOpen: true,
            child: Column(
              children: (_recipe!['ingredients'] as List).map((ingredient) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Puce (bullet point)
                      Container(
                        margin: const EdgeInsets.only(top: 6, right: 12),
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE53E3E),
                          shape: BoxShape.circle,
                        ),
                      ),
                      // Texte de l'ingrédient
                      Expanded(
                        child: Text(
                          _formatIngredientDisplay(ingredient),
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 16,
                            color: Color(0xFF4A5568),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

        // Instructions Accordion
        if (_recipe!['instructions'] != null)
          Accordion(
            title: 'Instructions',
            initiallyOpen: true,
            child: HtmlWidget(
              _formatInstructions(_recipe!['instructions']),
            ),
          ),

        // Gallery Carousel
        if (_recipe!['gallery_urls'] != null && (_recipe!['gallery_urls'] as List).isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: ImageGalleryCarousel(
              images: List<String>.from(_recipe!['gallery_urls']),
              title: 'Galerie photos',
              height: 240,
            ),
          ),

        // Comments avec composant unifié
        UnifiedCommentsSection(
          contentType: 'recipe',
          contentId: widget.id,
          contentTitle: _recipe!['title'] ?? 'Recette',
          onAuthRequired: () => setState(() => _showAuthModal = true),
        ),
      ],
    );
  }

  Widget _buildCommentsSection() {
    return Column(
      children: [
        // Add Comment Form
        _buildAddCommentForm(),
        const SizedBox(height: 16),

        // Comments List
        if (_comments.isNotEmpty)
          Column(
            children: _comments.map((comment) => _buildCommentItem(comment)).toList(),
          )
        else
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Aucun commentaire pour le moment.',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 16,
                color: Color(0xFF4A5568),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAddCommentForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info or auth prompt
          if (!ref.read(useAuthHandlerProvider).isAuthenticated) ...[
            const Text(
              'Connectez-vous pour laisser un commentaire',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 16,
                color: Color(0xFF4A5568),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => setState(() => _showAuthModal = true),
              child: const Text('Se connecter'),
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Connecté en tant que ${ref.read(useAuthHandlerProvider).userName}',
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 14,
                    color: Color(0xFF4A5568),
                  ),
                ),
                TextButton(
                  onPressed: () => ref.read(useAuthHandlerProvider.notifier).logout(),
                  child: const Text('Déconnexion'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Ajoutez votre commentaire...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _commentController.text.trim().isEmpty ? null : _addComment,
              child: const Text('Publier'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCommentItem(dynamic comment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment['author_name'] ?? 'Anonyme',
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    Text(
                      _formatDate(comment['created_at']),
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 14,
                        color: Color(0xFF4A5568),
                      ),
                    ),
                  ],
                ),
              ),
              if (_canDeleteComment(comment))
                IconButton(
                  onPressed: () => _deleteComment(comment['id'].toString()),
                  icon: const Icon(LucideIcons.trash2, size: 16),
                  tooltip: 'Supprimer le commentaire',
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            comment['content'] ?? '',
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 16,
              color: Color(0xFF4A5568),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeActions() {
    return Row(
      children: [
        // Like Button
        Expanded(
          child: UnifiedLikeButton(
            type: 'recipe',
            itemId: widget.id,
            initialLiked: _userLiked,
            initialCount: _recipe!['likes_count'] ?? 0,
            showCount: true,
            size: 'medium',
            autoFetch: true,
            onAuthRequired: () => setState(() => _showAuthModal = true),
          ),
        ),
        const SizedBox(width: 12),

        // Refresh Button
        IconButton(
          onPressed: _loading ? null : _forceRefresh,
          icon: Icon(
            LucideIcons.refreshCw,
            size: 20,
            color: _loading ? Colors.grey : const Color(0xFF49454F),
          ),
          tooltip: 'Actualiser les données',
        ),

        // Share Button
        IconButton(
          onPressed: _callShare,
          icon: const Icon(
            LucideIcons.share,
            size: 20,
            color: Color(0xFF49454F),
          ),
          tooltip: 'Partager cette recette',
        ),
      ],
    );
  }
}