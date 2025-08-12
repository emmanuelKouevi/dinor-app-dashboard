import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import '../services/navigation_service.dart';
import '../services/cache_service.dart';
import '../services/offline_service.dart';
import '../services/image_service.dart';
import '../services/tutorial_service.dart';
import '../components/app_header.dart';
import '../components/common/home_video_modal.dart';
import 'cache_management_screen.dart';

class WorkingHomeScreen extends StatefulWidget {
  const WorkingHomeScreen({Key? key}) : super(key: key);

  @override
  State<WorkingHomeScreen> createState() => _WorkingHomeScreenState();
}

class _WorkingHomeScreenState extends State<WorkingHomeScreen> {
  List<dynamic> recipes = [];
  List<dynamic> tips = [];
  List<dynamic> events = [];
  List<dynamic> videos = [];

  bool isLoadingRecipes = true;
  bool isLoadingTips = true;
  bool isLoadingEvents = true;
  bool isLoadingVideos = true;

  String? errorRecipes;
  String? errorTips;
  String? errorEvents;
  String? errorVideos;

  final CacheService _cacheService = CacheService();
  final OfflineService _offlineService = OfflineService();

  // Helper pour tronquer le contenu HTML pour les cartes
  String _stripHtmlAndTruncate(String htmlContent, int maxLength) {
    // Supprimer les balises HTML de base
    String text = htmlContent
        .replaceAll(RegExp(r'<[^>]*>'), '') // Supprimer toutes les balises HTML
        .replaceAll(RegExp(r'\s+'), ' ') // Normaliser les espaces
        .trim();

    // Tronquer si nécessaire
    if (text.length > maxLength) {
      text = '${text.substring(0, maxLength)}...';
    }

    return text;
  }

  @override
  void initState() {
    super.initState();
    _loadAllData();
    
    // Afficher le tutoriel de la page d'accueil si nécessaire (désactivé temporairement)
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   if (mounted) {
    //     TutorialService.showHomePageTutorialIfNeeded(context);
    //   }
    // });
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _loadRecipes(),
      _loadTips(),
      _loadEvents(),
      _loadVideos(),
    ]);
  }

  Future<void> _loadRecipes() async {
    try {
      final result = await _offlineService.loadDataWithOfflineSupport(
        endpoint: 'https://new.dinorapp.com/api/v1/recipes',
        cacheKey: 'home_recipes',
        params: {'limit': '4'},
      );

      if (result['success']) {
        final data = result['data'];
        final newRecipes = data['data'] is List ? data['data'] : [data['data']];

        setState(() {
          recipes = newRecipes;
          isLoadingRecipes = false;
          errorRecipes = null;
        });

        // Afficher un indicateur si en mode hors ligne
        if (result['offline'] == true) {
          _showOfflineIndicator();
        }
      } else {
        setState(() {
          isLoadingRecipes = false;
          errorRecipes = result['error'];
        });
      }
    } catch (e) {
      print('❌ [Home] Erreur chargement recettes: $e');
      setState(() {
        isLoadingRecipes = false;
        errorRecipes = e.toString();
      });
    }
  }

  Future<void> _loadTips() async {
    try {
      final result = await _offlineService.loadDataWithOfflineSupport(
        endpoint: 'https://new.dinorapp.com/api/v1/tips',
        cacheKey: 'home_tips',
        params: {'limit': '4'},
      );

      if (result['success']) {
        final data = result['data'];
        final newTips = data['data'] is List ? data['data'] : [data['data']];

        setState(() {
          tips = newTips;
          isLoadingTips = false;
          errorTips = null;
        });

        // Afficher un indicateur si en mode hors ligne
        if (result['offline'] == true) {
          _showOfflineIndicator();
        }
      } else {
        setState(() {
          isLoadingTips = false;
          errorTips = result['error'];
        });
      }
    } catch (e) {
      print('❌ [Home] Erreur chargement astuces: $e');
      setState(() {
        isLoadingTips = false;
        errorTips = e.toString();
      });
    }
  }

  Future<void> _loadEvents() async {
    try {
      final result = await _offlineService.loadDataWithOfflineSupport(
        endpoint: 'https://new.dinorapp.com/api/v1/events',
        cacheKey: 'home_events',
        params: {'limit': '4'},
      );

      if (result['success']) {
        final data = result['data'];
        final newEvents = data['data'] is List ? data['data'] : [data['data']];

        setState(() {
          events = newEvents;
          isLoadingEvents = false;
          errorEvents = null;
        });

        // Afficher un indicateur si en mode hors ligne
        if (result['offline'] == true) {
          _showOfflineIndicator();
        }
      } else {
        setState(() {
          isLoadingEvents = false;
          errorEvents = result['error'];
        });
      }
    } catch (e) {
      print('❌ [Home] Erreur chargement événements: $e');
      setState(() {
        isLoadingEvents = false;
        errorEvents = e.toString();
      });
    }
  }

  Future<void> _loadVideos() async {
    try {
      final result = await _offlineService.loadDataWithOfflineSupport(
        endpoint: 'https://new.dinorapp.com/api/v1/dinor-tv',
        cacheKey: 'home_videos',
        params: {'limit': '4'},
      );

      if (result['success']) {
        final data = result['data'];
        final newVideos = data['data'] is List ? data['data'] : [data['data']];

        setState(() {
          videos = newVideos;
          isLoadingVideos = false;
          errorVideos = null;
        });

        // Afficher un indicateur si en mode hors ligne
        if (result['offline'] == true) {
          _showOfflineIndicator();
        }
      } else {
        setState(() {
          isLoadingVideos = false;
          errorVideos = result['error'];
        });
      }
    } catch (e) {
      print('❌ [Home] Erreur chargement vidéos: $e');
      setState(() {
        isLoadingVideos = false;
        errorVideos = e.toString();
      });
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

  void _openVideo(Map<String, dynamic> video) {
    final videoUrl = video['video_url'] as String?;
    final title = video['title'] as String? ?? 'Vidéo Dinor TV';
    final description = video['description'] as String?;

    if (videoUrl != null && videoUrl.isNotEmpty) {
      print('🎬 [WorkingHome] Ouverture vidéo intégrée: $title');
      print('🎬 [WorkingHome] URL: $videoUrl');

      // Afficher la modal vidéo optimisée pour la page d'accueil
      showDialog(
        context: context,
        barrierDismissible: true,
        useRootNavigator: true,
        builder: (context) => HomeVideoModal(
          isOpen: true,
          videoUrl: videoUrl,
          title: title,
          description: description,
          onClose: () {
            if (Navigator.of(context, rootNavigator: true).canPop()) {
              Navigator.of(context, rootNavigator: true).pop();
            }
          },
        ),
      );
    } else {
      print('⚠️ [WorkingHome] URL vidéo manquante pour: $title');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('URL de vidéo non disponible'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // Contenu principal avec pull-to-refresh
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadAllData,
              color: const Color(0xFFE53E3E),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // En-tête de bienvenue
                    _buildWelcomeHeader(),
                    const SizedBox(height: 24),

                    // Événements d'abord
                    _buildSection(
                      'Événements',
                      '/events',
                      events,
                      isLoadingEvents,
                      errorEvents,
                      _buildEventCard,
                      Icons.event,
                      const Color(0xFF38A169),
                    ),
                    const SizedBox(height: 24),

                    // Recettes
                    _buildSection(
                      'Recettes',
                      '/recipes',
                      recipes,
                      isLoadingRecipes,
                      errorRecipes,
                      _buildRecipeCard,
                      Icons.restaurant,
                      const Color(0xFFE53E3E),
                    ),
                    const SizedBox(height: 24),

                    // Astuces
                    _buildSection(
                      'Astuces',
                      '/tips',
                      tips,
                      isLoadingTips,
                      errorTips,
                      _buildTipCard,
                      Icons.lightbulb,
                      const Color(0xFFF4D03F),
                    ),
                    const SizedBox(height: 24),

                    // Vidéos
                    _buildSection(
                      'Dinor TV',
                      '/dinor-tv',
                      videos,
                      isLoadingVideos,
                      errorVideos,
                      _buildVideoCard,
                      Icons.play_circle,
                      const Color(0xFF9B59B6),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return const SizedBox.shrink();
  }

  Widget _buildSection(
    String title,
    String route,
    List<dynamic> items,
    bool isLoading,
    String? error,
    Widget Function(Map<String, dynamic>) cardBuilder,
    IconData icon,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête de section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'OpenSans',
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748),
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () => NavigationService.pushNamed(route),
              child: Text(
                'Voir tout',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Contenu
        if (isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE53E3E)),
              ),
            ),
          )
        else if (error != null)
          _buildErrorWidget(error)
        else if (items.isEmpty)
          _buildEmptyWidget()
        else
          SizedBox(
            height: 280,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              itemBuilder: (context, index) {
                return Container(
                  width: 280,
                  margin: const EdgeInsets.only(right: 16),
                  child: cardBuilder(items[index]),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildRecipeCard(Map<String, dynamic> recipe) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          NavigationService.goToRecipeDetail(recipe['id'].toString());
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: ImageService.buildNetworkImage(
                  imageUrl: recipe['featured_image_url'] ?? '',
                  contentType: 'recipe',
                  fit: BoxFit.cover,
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
                    recipe['title'] ?? 'Sans titre',
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
                      if (recipe['total_time'] != null) ...[
                        const Icon(Icons.schedule,
                            size: 16, color: Color(0xFF718096)),
                        const SizedBox(width: 4),
                        Text(
                          '${recipe['total_time']} min',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF718096),
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                      if (recipe['likes_count'] != null) ...[
                        const Icon(Icons.favorite,
                            size: 16, color: Color(0xFFE53E3E)),
                        const SizedBox(width: 4),
                        Text(
                          '${recipe['likes_count']}',
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

  Widget _buildTipCard(Map<String, dynamic> tip) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          NavigationService.goToTipDetail(tip['id'].toString());
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: ImageService.buildNetworkImage(
                  imageUrl: tip['featured_image_url'] ?? '',
                  contentType: 'tip',
                  fit: BoxFit.cover,
                  errorWidget: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFF4D03F), Color(0xFFFF6B35)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.lightbulb,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                  ),
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
                    tip['title'] ?? 'Sans titre',
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
                  // if (tip['content'] != null) ...[
                  //   HtmlWidget(
                  //     _stripHtmlAndTruncate(tip['content'] ?? '', 100),
                  //     textStyle: const TextStyle(
                  //       fontFamily: 'Roboto',
                  //       fontSize: 14,
                  //       color: Color(0xFF718096),
                  //     ),
                  //   ),
                  //   const SizedBox(height: 8),
                  // ],
                  Row(
                    children: [
                      if (tip['estimated_time'] != null) ...[
                        const Icon(Icons.schedule,
                            size: 16, color: Color(0xFF718096)),
                        const SizedBox(width: 4),
                        Text(
                          '${tip['estimated_time']} min',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF718096),
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                      if (tip['likes_count'] != null) ...[
                        const Icon(Icons.favorite,
                            size: 16, color: Color(0xFFE53E3E)),
                        const SizedBox(width: 4),
                        Text(
                          '${tip['likes_count']}',
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

  Widget _buildEventCard(Map<String, dynamic> event) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          NavigationService.goToEventDetail(event['id'].toString());
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: ImageService.buildNetworkImage(
                  imageUrl: event['image'] ?? event['thumbnail'] ?? event['image_url'] ?? '',
                  contentType: 'event',
                  fit: BoxFit.cover,
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
                    event['title'] ?? 'Sans titre',
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
                      if (event['start_date'] != null) ...[
                        const Icon(Icons.calendar_today,
                            size: 16, color: Color(0xFFE53E3E)),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(event['start_date']),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF718096),
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                      if (event['likes_count'] != null) ...[
                        const Icon(Icons.favorite,
                            size: 16, color: Color(0xFFE53E3E)),
                        const SizedBox(width: 4),
                        Text(
                          '${event['likes_count']}',
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

  Widget _buildVideoCard(Map<String, dynamic> video) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          _openVideo(video);
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail avec overlay
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ImageService.buildNetworkImage(
                      imageUrl: video['thumbnail_url'] ?? '',
                      contentType: 'video',
                      fit: BoxFit.cover,
                    ),
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
                    video['title'] ?? 'Sans titre',
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
                      if (video['views_count'] != null) ...[
                        const Icon(Icons.visibility,
                            size: 16, color: Color(0xFF718096)),
                        const SizedBox(width: 4),
                        Text(
                          '${video['views_count']}',
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

  Widget _buildErrorWidget(String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE53E3E).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline,
            size: 32,
            color: Color(0xFFE53E3E),
          ),
          const SizedBox(height: 8),
          Text(
            'Erreur de chargement',
            style: const TextStyle(
              fontFamily: 'OpenSans',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            error,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 12,
              color: Color(0xFF718096),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.inbox_outlined,
            size: 32,
            color: Color(0xFFCBD5E0),
          ),
          const SizedBox(height: 8),
          Text(
            'Aucun contenu disponible',
            style: const TextStyle(
              fontFamily: 'OpenSans',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3748),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}
