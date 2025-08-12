import '../services/navigation_service.dart';
/**
 * TIP_DETAIL_SCREEN.DART - CONVERSION FIDÈLE DE TipDetail.vue
 * 
 * FIDÉLITÉ VISUELLE :
 * - Hero image identique avec overlay et badges
 * - Tip stats identiques : difficulté, type, likes, commentaires
 * - Accordions identiques : contenu, galerie, commentaires
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
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

// Components
import '../components/common/badge.dart' as dinor_badge;
import '../components/common/like_button.dart';
import '../components/common/unified_like_button.dart';
import '../components/common/share_modal.dart';
import '../components/common/auth_modal.dart';
import '../components/common/accordion.dart';
import '../components/common/image_lightbox.dart';
import '../components/common/image_gallery_carousel.dart';
import '../components/dinor_icon.dart';

// Services et composables
import '../services/api_service.dart';
import '../services/image_service.dart';
import '../services/comments_service.dart';
import '../composables/use_comments.dart';
import '../composables/use_auth_handler.dart';
import '../composables/use_social_share.dart';

class TipDetailScreen extends ConsumerStatefulWidget {
  final String id;
  
  const TipDetailScreen({Key? key, required this.id}) : super(key: key);

  @override
  ConsumerState<TipDetailScreen> createState() => _TipDetailScreenState();
}

class _TipDetailScreenState extends ConsumerState<TipDetailScreen> with AutomaticKeepAliveClientMixin {
  // État identique au setup() Vue
  bool _showAuthModal = false;
  bool _showShareModal = false;
  bool _showLightbox = false;
  int _lightboxIndex = 0;
  
  // Données de l'astuce
  Map<String, dynamic>? _tip;
  List<dynamic> _comments = [];
  
  // États de chargement
  bool _loading = true;
  bool _userLiked = false;
  bool _userFavorited = false;
  
  // Erreurs
  String? _error;

  // Commentaires
  final TextEditingController _commentController = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    
    print('💡 [TipDetailScreen] Écran détail astuce initialisé ID: ${widget.id}');
    _loadTip();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // REPRODUCTION EXACTE du chargement de données Vue
  Future<void> _loadTip({bool forceRefresh = false}) async {
    try {
      print('🔄 [TipDetailScreen] Chargement astuce ID: ${widget.id}, ForceRefresh: $forceRefresh');
      setState(() => _loading = true);
      
      // Utiliser l'API service (même que React Native)
      final apiService = ref.read(apiServiceProvider);
      final data = forceRefresh 
        ? await apiService.request('/tips/${widget.id}', forceRefresh: true)
        : await apiService.get('/tips/${widget.id}');
        
      if (data['success']) {
        setState(() {
          _tip = data['data'];
          _loading = false;
        });
        
        // Charger les commentaires
        await _loadComments();
        await _checkUserLike();
        await _checkUserFavorite();
        
        print('✅ [TipDetailScreen] Astuce chargée avec succès');
      }
    } catch (error) {
      print('❌ [TipDetailScreen] Erreur lors du chargement de l\'astuce: $error');
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadComments() async {
    try {
      await ref.read(commentsServiceProvider.notifier).loadComments('tip', widget.id);
      final commentsState = ref.read(commentsServiceProvider)[('tip_${widget.id}')];
      if (commentsState != null) {
        setState(() => _comments = commentsState.comments.map((c) => c.toJson()).toList());
      }
    } catch (error) {
      print('❌ [TipDetailScreen] Erreur chargement commentaires: $error');
    }
  }

  Future<void> _checkUserLike() async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final data = await apiService.get('/likes/check', params: {
        'type': 'tip',
        'id': widget.id
      });
      setState(() => _userLiked = data['success'] && data['is_liked']);
    } catch (error) {
      print('❌ [TipDetailScreen] Erreur vérification like: $error');
    }
  }

  Future<void> _checkUserFavorite() async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final data = await apiService.get('/favorites/check', params: {
        'type': 'tip',
        'id': widget.id
      });
      setState(() => _userFavorited = data['success'] && data['is_favorited']);
    } catch (error) {
      print('❌ [TipDetailScreen] Erreur vérification favori: $error');
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;
    
    try {
      print('📝 [TipDetailScreen] Envoi du commentaire pour Tip: ${widget.id}');
      
      final success = await ref.read(commentsServiceProvider.notifier).addComment(
        'tip', 
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
        
        print('✅ [TipDetailScreen] Commentaire ajouté avec succès');
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
      print('❌ [TipDetailScreen] Erreur lors de l\'ajout du commentaire: $error');
      
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
      print('❌ [TipDetailScreen] Erreur suppression commentaire: $error');
    }
  }

  Future<void> _forceRefresh() async {
    print('🔄 [TipDetailScreen] Rechargement forcé demandé');
    setState(() => _loading = true);
    try {
      await _loadTip(forceRefresh: true);
      print('✅ [TipDetailScreen] Rechargement forcé terminé');
    } catch (error) {
      print('❌ [TipDetailScreen] Erreur lors du rechargement forcé: $error');
    }
  }

  void _goBack() {
    NavigationService.pop();
  }

  void _callShare() {
    if (_tip == null) return;
    
    setState(() {
      _showShareModal = true;
    });
  }

  void _closeShareModal() {
    setState(() {
      _showShareModal = false;
    });
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

  String _formatDate(String date) {
    return DateTime.parse(date).toLocal().toString().split(' ')[0];
  }

  void _openVideo(String videoUrl) {
    print('🎥 [TipDetail] _openVideo appelé avec URL: $videoUrl');
    
    if (videoUrl.isEmpty) {
      print('❌ [TipDetail] URL vidéo vide');
      _showSnackBar('URL de la vidéo non disponible', Colors.red);
      return;
    }
    
    print('🎬 [TipDetail] Ouverture vidéo intégrée avec autoplay');
    
    // Afficher la modal vidéo YouTube intégrée avec autoplay
    showDialog(
      context: context,
      barrierDismissible: true,
      useRootNavigator: true,
      builder: (context) => YouTubeVideoModal(
        isOpen: true,
        videoUrl: videoUrl,
        title: _tip?['title'] ?? 'Vidéo de l\'astuce',
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

  void _openGalleryModal(int index) {
    if (_tip?['gallery_urls']?[index] != null) {
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
              : _tip == null
                ? _buildNotFoundState()
                : _buildTipContent(),
        ),
        
        // Share Modal
        if (_showShareModal && _tip != null)
          ShareModal(
            isOpen: _showShareModal,
            shareData: {
              'title': _tip!['title'],
              'text': _tip!['short_description'] ?? 'Découvrez cette astuce : ${_tip!['title']}',
              'url': 'https://new.dinorapp.com/pwa/tip/${widget.id}',
              'image': _tip!['featured_image_url'],
            },
            onClose: _closeShareModal,
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
          Text(
            'L\'astuce demandée n\'existe pas ou a été supprimée.',
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

  Widget _buildTipContent() {
    return CustomScrollView(
      slivers: [
        // Hero Image
        SliverToBoxAdapter(
          child: _buildHeroImage(),
        ),

        // Tip Info
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tip Stats
                _buildTipStats(),
                const SizedBox(height: 24),

                // Description
                if (_tip!['short_description'] != null) ...[
                  _buildSection(
                    'Description',
                    Text(_tip!['short_description']),
                  ),
                  const SizedBox(height: 24),
                ],

                // Content Video
                if (_tip!['video_url'] != null) ...[
                  _buildSection(
                    'Vidéo explicative',
                    _buildVideoContainer(_tip!['video_url']),
                  ),
                  const SizedBox(height: 24),
                ],

                // Tip Sections
                _buildTipSections(),

                // Tip Header Actions
                const SizedBox(height: 24),
                _buildTipActions(),
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
            imageUrl: _tip!['featured_image_url'] ?? '',
            contentType: 'tip',
            fit: BoxFit.cover,
          ),
        ),
        // Tip Overlay
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
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
        // Tip Badges
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Row(
            children: [
              if (_tip!['difficulty'] != null)
                dinor_badge.Badge(
                  text: _getDifficultyLabel(_tip!['difficulty']),
                  icon: 'star',
                  variant: 'secondary',
                  size: 'medium',
                ),
              const SizedBox(width: 8),
              if (_tip!['type'] != null)
                dinor_badge.Badge(
                  text: _getTypeLabel(_tip!['type']),
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

  Widget _buildTipStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4D03F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Seulement afficher la difficulté si elle existe
          if (_tip!['difficulty'] != null)
            _buildStatItem(
              LucideIcons.star,
              _getDifficultyLabel(_tip!['difficulty']),
            ),
          // Seulement afficher le type si il existe
          if (_tip!['type'] != null)
            _buildStatItem(
              LucideIcons.tag,
              _getTypeLabel(_tip!['type']),
            ),
          _buildStatItem(
            LucideIcons.heart,
            '${_tip!['likes_count'] ?? 0}',
          ),
          _buildStatItem(
            LucideIcons.messageCircle,
            '${_tip!['comments_count'] ?? 0}',
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
          textAlign: TextAlign.center,
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
                    decoration: BoxDecoration(
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

        // Comments Accordion
        Accordion(
          title: 'Commentaires (${_comments.length})',
          initiallyOpen: false,
          child: _buildCommentsSection(),
        ),
      ],
    );
  }

  String _formatTipContent(dynamic content) {
    if (content == null) return '';
    
    // Si c'est déjà une chaîne, la retourner
    if (content is String) return content;
    
    // Si c'est un Map avec une propriété 'text'
    if (content is Map && content['text'] != null) {
      return content['text'];
    }
    
    // Si c'est un Map avec une propriété 'content'
    if (content is Map && content['content'] != null) {
      return content['content'];
    }
    
    // Si c'est un Map avec une propriété 'description'
    if (content is Map && content['description'] != null) {
      return content['description'];
    }
    
    // Si c'est une liste, joindre les éléments
    if (content is List) {
      return content.map((item) => _formatTipContent(item)).join('\n\n');
    }
    
    return content.toString();
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

  Widget _buildTipActions() {
    return Row(
      children: [
        // Like Button
        Expanded(
          child: UnifiedLikeButton(
            type: 'tip',
            itemId: widget.id,
            initialLiked: _userLiked,
            initialCount: _tip!['likes_count'] ?? 0,
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
          tooltip: 'Partager cette astuce',
        ),
      ],
    );
  }
}