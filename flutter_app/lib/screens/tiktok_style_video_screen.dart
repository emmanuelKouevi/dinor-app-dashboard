/**
 * TIKTOK_STYLE_VIDEO_SCREEN.DART - INTERFACE VIDÉO PLEIN ÉCRAN TYPE TIKTOK
 * 
 * FONCTIONNALITÉS :
 * - Lecteur vidéo en mode portrait plein écran
 * - Défilement vertical PageView pour navigation entre vidéos
 * - Lecture automatique de la vidéo visible
 * - Pause automatique des vidéos hors écran
 * - Contrôles superposés : play/pause, progression, interactions
 * - Informations du contenu en bas à gauche
 * - Gestes : tap pour pause/lecture, swipe vertical
 * - Optimisation performances avec préchargement
 * - Support formats vidéo courants (MP4, MOV, etc.)
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:async';

import '../services/navigation_service.dart';
import '../components/common/like_button.dart';
import '../components/common/youtube_video_player.dart';
import '../components/common/unified_comments_section.dart';
import '../services/likes_service.dart';
import '../composables/use_auth_handler.dart';
import '../components/common/auth_modal.dart';

// Modèle pour les données vidéo
class VideoData {
  final String id;
  final String title;
  final String description;
  final String author;
  final String? authorAvatar;
  final String videoUrl;
  final String? thumbnailUrl;
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final int views;
  final bool isLiked;
  final Duration? duration;

  VideoData({
    required this.id,
    required this.title,
    required this.description,
    required this.author,
    this.authorAvatar,
    required this.videoUrl,
    this.thumbnailUrl,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.sharesCount = 0,
    this.views = 0,
    this.isLiked = false,
    this.duration,
  });

  factory VideoData.fromJson(Map<String, dynamic> json) {
    return VideoData(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      author: json['author'] ?? json['user_name'] ?? 'Dinor',
      authorAvatar: json['author_avatar'] ?? json['user_avatar'],
      videoUrl: json['video_url'] ?? json['url'] ?? '',
      thumbnailUrl: json['thumbnail_url'] ?? json['thumbnail'] ?? json['image'],
      likesCount: json['likes_count'] ?? 0,
      commentsCount: json['comments_count'] ?? 0,
      sharesCount: json['shares_count'] ?? 0,
      views: json['views'] ?? 0,
      isLiked: json['is_liked'] ?? false,
      duration: json['duration'] != null ? 
        Duration(seconds: int.tryParse(json['duration'].toString()) ?? 0) : null,
    );
  }
}

// État global pour la gestion des vidéos
class VideoPlayerState {
  final List<VideoData> videos;
  final int currentIndex;
  final bool isLoading;
  final String? error;

  const VideoPlayerState({
    this.videos = const [],
    this.currentIndex = 0,
    this.isLoading = false,
    this.error,
  });

  VideoPlayerState copyWith({
    List<VideoData>? videos,
    int? currentIndex,
    bool? isLoading,
    String? error,
  }) {
    return VideoPlayerState(
      videos: videos ?? this.videos,
      currentIndex: currentIndex ?? this.currentIndex,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Service de gestion des vidéos
class VideoPlayerService extends StateNotifier<VideoPlayerState> {
  VideoPlayerService() : super(const VideoPlayerState());

  void loadVideos(List<VideoData> videos) {
    state = state.copyWith(videos: videos, isLoading: false);
  }

  void setCurrentIndex(int index) {
    state = state.copyWith(currentIndex: index);
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void setError(String? error) {
    state = state.copyWith(error: error);
  }
}

final videoPlayerProvider = StateNotifierProvider<VideoPlayerService, VideoPlayerState>((ref) {
  return VideoPlayerService();
});

// Écran principal TikTok
class TikTokStyleVideoScreen extends ConsumerStatefulWidget {
  final List<VideoData> videos;
  final int initialIndex;

  const TikTokStyleVideoScreen({
    Key? key,
    required this.videos,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  ConsumerState<TikTokStyleVideoScreen> createState() => _TikTokStyleVideoScreenState();
}

class _TikTokStyleVideoScreenState extends ConsumerState<TikTokStyleVideoScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  int _currentIndex = 0;
  bool _showAuthModal = false;
  
  // Animation des contrôles
  late AnimationController _controlsAnimationController;
  late Animation<double> _controlsAnimation;
  bool _showControls = false;
  Timer? _hideControlsTimer;
  
  // Gestion des lecteurs YouTube
  final Map<int, GlobalKey<YouTubeVideoPlayerState>> _playerKeys = {};

  @override
  void initState() {
    super.initState();
    
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    
    _controlsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _controlsAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controlsAnimationController,
      curve: Curves.easeInOut,
    ));

    // Charger les vidéos dans le provider après la construction
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(videoPlayerProvider.notifier).loadVideos(widget.videos);
      ref.read(videoPlayerProvider.notifier).setCurrentIndex(_currentIndex);
    });

    // Mettre en plein écran
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    // Nettoyer les références aux lecteurs
    _playerKeys.clear();
    
    _pageController.dispose();
    _controlsAnimationController.dispose();
    _hideControlsTimer?.cancel();
    
    // Restaurer l'interface système
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    
    super.dispose();
  }

  // Pauser tous les autres lecteurs sauf le courant
  void _pauseOtherPlayers(int currentIndex) {
    for (final entry in _playerKeys.entries) {
      if (entry.key != currentIndex) {
        entry.value.currentState?.pause();
      }
    }
  }

  // Changer de vidéo
  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    
    // Modifier le provider de manière sécurisée
    Future(() {
      ref.read(videoPlayerProvider.notifier).setCurrentIndex(index);
    });

    // Pauser tous les autres lecteurs
    _pauseOtherPlayers(index);
    
    print('🎬 [TikTokVideo] Changement vers vidéo $index: ${widget.videos[index].title}');
  }

  // Toggle play/pause pour le lecteur YouTube courant
  void _togglePlayPause() {
    final playerKey = _playerKeys[_currentIndex];
    if (playerKey?.currentState != null) {
      // Note: YouTubeVideoPlayer gère son propre toggle via les contrôles intégrés
      print('🎵 [TikTokVideo] Toggle play/pause via contrôles YouTube');
    }
    
    _showControlsTemporarily();
  }

  // Afficher les contrôles temporairement
  void _showControlsTemporarily() {
    setState(() {
      _showControls = true;
    });
    
    _controlsAnimationController.forward();
    
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
        _controlsAnimationController.reverse();
      }
    });
  }

  // Partager la vidéo
  void _shareVideo() {
    final video = widget.videos[_currentIndex];
    Share.share(
      'Regardez cette vidéo sur Dinor : ${video.title}\n\nhttps://new.dinorapp.com/video/${video.id}',
      subject: video.title,
    );
  }

  // Gérer l'action de like
  Future<void> _handleLikeAction(VideoData video, WidgetRef ref) async {
    final authState = ref.read(useAuthHandlerProvider);
    
    print('🎯 [TikTokVideo] Tentative de like pour vidéo: ID=${video.id}, Auth=${authState.isAuthenticated}');
    
    if (!authState.isAuthenticated) {
      print('⚠️ [TikTokVideo] Utilisateur non authentifié, ouverture modal auth');
      setState(() => _showAuthModal = true);
      return;
    }

    try {
      print('🔄 [TikTokVideo] Envoi requête like: type=video, id=${video.id}');
      
      // Utiliser 'video' qui est le type de contenu reconnu par l'API
      final result = await ref.read(likesProvider.notifier).toggleLike('video', video.id);
      
      if (result) {
        print('✅ [TikTokVideo] Like toggleé avec succès');
        
        // Afficher un feedback visuel seulement si le widget est encore monté
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.favorite, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    ref.read(likesProvider.notifier).isLiked('video', video.id) 
                      ? '❤️ Ajouté aux favoris' 
                      : '💔 Retiré des favoris',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFFE53E3E),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } else {
        print('❌ [TikTokVideo] Échec du like');
        if (mounted) {
          _showErrorSnackBar('Impossible de mettre à jour le like');
        }
      }
    } catch (error) {
      print('❌ [TikTokVideo] Exception lors du like: $error');
      if (mounted) {
        _showErrorSnackBar('Erreur de connexion: ${error.toString()}');
      }
    }
  }
  
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[600],
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: 'Réessayer',
          textColor: Colors.white,
          onPressed: () => _handleLikeAction(widget.videos[_currentIndex], ref),
        ),
      ),
    );
  }

  // Naviguer vers les commentaires
  void _openComments() {
    final video = widget.videos[_currentIndex];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildCommentsSheet(video),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // PageView principal avec vidéos
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            onPageChanged: _onPageChanged,
            itemCount: widget.videos.length,
            itemBuilder: (context, index) {
              return _buildVideoPage(index);
            },
          ),

          // Interface superposée
          _buildOverlayInterface(),

          // Modal d'authentification
          if (_showAuthModal)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: AuthModal(
                  isOpen: _showAuthModal,
                  onClose: () => setState(() => _showAuthModal = false),
                  onAuthenticated: () => setState(() => _showAuthModal = false),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Page vidéo individuelle
  Widget _buildVideoPage(int index) {
    final video = widget.videos[index];
    
    // Créer une clé unique pour ce lecteur
    if (!_playerKeys.containsKey(index)) {
      _playerKeys[index] = GlobalKey<YouTubeVideoPlayerState>();
    }

    return GestureDetector(
      onTap: _togglePlayPause,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Lecteur YouTube
            if (video.videoUrl.isNotEmpty)
              Center(
                child: AspectRatio(
                  aspectRatio: 9 / 16, // Format portrait pour TikTok
                  child: YouTubeVideoPlayer(
                    key: _playerKeys[index],
                    videoUrl: video.videoUrl,
                    title: '', // Pas de titre sur le player
                    autoPlay: index == _currentIndex, // Auto-play seulement pour la vidéo courante
                    showControls: true,
                    onReady: () {
                      print('✅ [TikTokVideo] Player $index ready: ${video.title}');
                    },
                    onPause: () {
                      print('⏸️ [TikTokVideo] Player $index paused');
                    },
                  ),
                ),
              )
            else if (video.thumbnailUrl != null)
              // Thumbnail si pas d'URL vidéo
              Image.network(
                video.thumbnailUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildVideoPlaceholder(),
              )
            else
              _buildVideoPlaceholder(),
          ],
        ),
      ),
    );
  }

  // Placeholder pour vidéo
  Widget _buildVideoPlaceholder() {
    return Container(
      color: Colors.grey[900],
      child: const Center(
        child: Icon(
          LucideIcons.play,
          size: 64,
          color: Colors.white54,
        ),
      ),
    );
  }

  // Note: Le bouton play/pause central n'est plus nécessaire 
  // car YouTubeVideoPlayer a ses propres contrôles intégrés

  // Interface superposée
  Widget _buildOverlayInterface() {
    final video = widget.videos[_currentIndex];

    return Positioned.fill(
      child: Stack(
        children: [
          // Bouton retour en haut à gauche
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: GestureDetector(
              onTap: () => NavigationService.pop(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  LucideIcons.arrowLeft,
                  color: Color(0xFF2D3748),
                  size: 24,
                ),
              ),
            ),
          ),

          // Boutons d'interaction à droite
          Positioned(
            right: 16,
            bottom: 100,
            child: _buildActionButtons(video),
          ),

          // Informations du contenu en bas à gauche
          Positioned(
            left: 16,
            right: 80,
            bottom: 100,
            child: _buildVideoInfo(video),
          ),

          // Note: Barre de progression gérée par YouTubeVideoPlayer
        ],
      ),
    );
  }

  // Boutons d'action à droite
  Widget _buildActionButtons(VideoData video) {
    return Consumer(
      builder: (context, ref, _) {
        return Column(
          children: [
            // Like avec état reactif
            _buildActionButton(
              child: Consumer(
                builder: (context, ref, _) {
                  final isLiked = ref.watch(likesProvider.notifier).isLiked('video', video.id);
                  final likeCount = ref.watch(likesProvider.notifier).getLikeCount('video', video.id);
                  
                  return GestureDetector(
                    onTap: () => _handleLikeAction(video, ref),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isLiked ? const Color(0xFFE53E3E) : Colors.black,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${likeCount > 0 ? likeCount : video.likesCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 24),

            // Commentaires
            _buildActionButton(
              onTap: _openComments,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.messageCircle,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${video.commentsCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Partage
            _buildActionButton(
              onTap: _shareVideo,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.share,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${video.sharesCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // Bouton d'action générique
  Widget _buildActionButton({
    VoidCallback? onTap,
    required Widget child,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        child: child,
      ),
    );
  }

  // Informations de la vidéo
  Widget _buildVideoInfo(VideoData video) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Auteur
        Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white24,
              backgroundImage: video.authorAvatar != null 
                ? NetworkImage(video.authorAvatar!)
                : null,
              child: video.authorAvatar == null
                ? const Icon(LucideIcons.user, size: 18, color: Colors.white)
                : null,
            ),
            const SizedBox(width: 8),
            Text(
              '@${video.author}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),

        // Titre
        Text(
          video.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),

        const SizedBox(height: 4),

        // Description
        if (video.description.isNotEmpty)
          Text(
            video.description,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),

        const SizedBox(height: 8),

        // Stats
        Row(
          children: [
            const Icon(LucideIcons.eye, size: 16, color: Colors.white70),
            const SizedBox(width: 4),
            Text(
              '${video.views} vues',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Note: Barre de progression maintenant gérée par YouTubeVideoPlayer

  // Sheet des commentaires avec composant unifié
  Widget _buildCommentsSheet(VideoData video) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header avec bouton fermer
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Text(
                      'Commentaires',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4D03F),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${video.commentsCount}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close,
                        color: Color(0xFF718096),
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
              
              const Divider(height: 1),
              
              // Section commentaires unifiée
              Expanded(
                child: UnifiedCommentsSection(
                  contentType: 'video',
                  contentId: video.id,
                  contentTitle: video.title,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
} 