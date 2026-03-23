import '../services/navigation_service.dart';
/**
 * DINOR_TV_SCREEN.DART - ÉCRAN DINOR TV
 * 
 * FIDÉLITÉ VISUELLE :
 * - Design moderne avec cards vidéo
 * - Pull-to-refresh pour rafraîchir
 * - Loading states et error handling
 * - Navigation vers détail vidéo
 * 
 * FIDÉLITÉ FONCTIONNELLE :
 * - Chargement des vidéos via API
 * - Gestion d'état avec Riverpod
 * - Like/Favorite functionality
 * - Pagination si nécessaire
 */

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';


import '../services/image_service.dart';

// Composables
import '../composables/use_dinor_tv.dart';
import '../composables/use_auth_handler.dart';
import '../components/common/youtube_video_modal.dart';
import '../components/common/auth_modal.dart';



class DinorTVScreen extends ConsumerStatefulWidget {
  const DinorTVScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DinorTVScreen> createState() => _DinorTVScreenState();
}

class _DinorTVScreenState extends ConsumerState<DinorTVScreen> with AutomaticKeepAliveClientMixin {
  bool _showAuthModal = false;
  String _authModalMessage = '';


  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    print('📺 [DinorTVScreen] Écran DinorTV initialisé');
    _loadVideos();
  }



  Future<void> _loadVideos() async {
    await ref.read(dinorTVProvider.notifier).loadVideos(
      params: {
        'limit': '20',
        'sort_by': 'created_at',
        'sort_order': 'desc',
      },
    );
  }

  Future<void> _handleRefresh() async {
    print('🔄 [DinorTVScreen] Rafraîchissement des vidéos...');
    await ref.read(dinorTVProvider.notifier).refresh();
  }



  void _handleVideoTap(dynamic video) {
    final videoUrl = video['video_url'] as String?;
    final title = video['title'] as String? ?? 'Vidéo Dinor TV';
    final description = video['description'] as String?;

    if (videoUrl != null && videoUrl.isNotEmpty) {
      print('🎬 [DinorTV] Ouverture vidéo: $title');
      print('🎬 [DinorTV] URL: $videoUrl');

      // TODO: Implémenter la modal vidéo pour Dinor TV
      // Pour l'instant, juste des logs pour debug
    } else {
      print('⚠️ [DinorTV] URL vidéo manquante pour: $title');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('URL de vidéo non disponible'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleLikeTap(dynamic video) async {
    final authHandler = ref.read(useAuthHandlerProvider.notifier);
    
    if (!authHandler.isAuthenticated) {
      setState(() {
        _showAuthModal = true;
        _authModalMessage = 'Connectez-vous pour liker cette vidéo';
      });
      return;
    }

    try {
      // TODO: Implémenter toggle like
      print('👍 [DinorTVScreen] Like vidéo: ${video['id']}');
    } catch (error) {
      print('❌ [DinorTVScreen] Erreur like: $error');
    }
  }

  void _handleFavoriteTap(dynamic video) async {
    final authHandler = ref.read(useAuthHandlerProvider.notifier);
    
    if (!authHandler.isAuthenticated) {
      setState(() {
        _showAuthModal = true;
        _authModalMessage = 'Connectez-vous pour ajouter aux favoris';
      });
      return;
    }

    try {
      // TODO: Implémenter toggle favorite
      print('⭐ [DinorTVScreen] Favorite vidéo: ${video['id']}');
    } catch (error) {
      print('❌ [DinorTVScreen] Erreur favorite: $error');
    }
  }

  void _closeAuthModal() {
    setState(() {
      _showAuthModal = false;
      _authModalMessage = '';
    });
  }

  void _displayAuthModal() {
    // Vérifier que le contexte est prêt avant d'afficher la modale
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _showAuthModal) {
        showDialog(
          context: context,
          barrierDismissible: true,
          useRootNavigator: true,
          builder: (BuildContext context) {
            return AuthModal(
              isOpen: true,
              onClose: () {
                Navigator.of(context, rootNavigator: true).pop();
                setState(() => _showAuthModal = false);
              },
              onAuthenticated: () {
                Navigator.of(context, rootNavigator: true).pop();
                setState(() => _showAuthModal = false);
              },
            );
          },
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    

    
    final dinorTVState = ref.watch(dinorTVProvider);
    final videos = dinorTVState.videos;
    final loading = dinorTVState.loading;
    final error = dinorTVState.error;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Dinor TV'),
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: _buildBody(videos, loading, error),
      ),
    );
  }

  Widget _buildBody(List<dynamic> videos, bool loading, String? error) {
    if (loading && videos.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF4D03F)),
            ),
            SizedBox(height: 16),
            Text(
              'Chargement des vidéos...',
              style: TextStyle(
                fontFamily: 'OpenSans',
                fontSize: 16,
                color: Color(0xFF718096),
              ),
            ),
          ],
        ),
      );
    }

    if (error != null && videos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Color(0xFFE53E3E),
            ),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: const TextStyle(
                fontFamily: 'OpenSans',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(
                fontFamily: 'OpenSans',
                fontSize: 14,
                color: Color(0xFF718096),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadVideos,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF4D03F),
                foregroundColor: const Color(0xFF2D3748),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (videos.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.video_library_outlined,
              size: 64,
              color: Color(0xFFCBD5E0),
            ),
            SizedBox(height: 16),
            Text(
              'Aucune vidéo disponible',
              style: TextStyle(
                fontFamily: 'OpenSans',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3748),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Les nouvelles vidéos apparaîtront ici',
              style: TextStyle(
                fontFamily: 'OpenSans',
                fontSize: 14,
                color: Color(0xFF718096),
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final video = videos[index];
        return _buildVideoCard(video);
      },
    );
  }

  Widget _buildVideoCard(dynamic video) {
    final thumbnail = video['thumbnail_url'] ?? video['thumbnail'] ?? video['image'] ?? '';
    final title = video['title'] ?? 'Sans titre';
    final views = video['views'] ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _handleVideoTap(video),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image avec overlay play button
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ImageService.buildNetworkImage(
                      imageUrl: thumbnail,
                      contentType: 'video',
                      fit: BoxFit.cover,
                      errorWidget: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF9B59B6), Color(0xFFE53E3E)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.play_circle,
                            size: 48,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    // Gradient overlay d'arrière-plan
                    Container(
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
                    // Play button centré
                    const Center(
                      child: Icon(
                        Icons.play_circle_outline,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Contenu
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'OpenSans',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D3748),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (views > 0) ...[
                        const Icon(Icons.visibility, size: 16, color: Color(0xFF718096)),
                        const SizedBox(width: 4),
                        Text(
                          '$views',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF718096),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}