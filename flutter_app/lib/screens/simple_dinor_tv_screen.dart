import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/navigation_service.dart';
import '../components/common/youtube_video_modal.dart';
import '../components/app_header.dart';

class SimpleDinorTVScreen extends StatefulWidget {
  const SimpleDinorTVScreen({Key? key}) : super(key: key);

  @override
  State<SimpleDinorTVScreen> createState() => _SimpleDinorTVScreenState();
}

class _SimpleDinorTVScreenState extends State<SimpleDinorTVScreen> {
  List<dynamic> videos = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    try {
      print('🔄 [SimpleDinorTV] Chargement des vidéos...');
      
      final response = await http.get(
        Uri.parse('https://new.dinorapp.com/api/v1/dinor-tv'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      print('📡 [SimpleDinorTV] Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ [SimpleDinorTV] Data reçue: ${data.toString().substring(0, 100)}...');
        
        setState(() {
          if (data['data'] != null) {
            videos = data['data'] is List ? data['data'] : [data['data']];
          } else {
            videos = [];
          }
          isLoading = false;
          error = null;
        });
        
        print('📺 [SimpleDinorTV] ${videos.length} vidéos chargées');
        
        // Debug: Afficher les URLs des vidéos
        for (int i = 0; i < videos.length; i++) {
          final video = videos[i];
          print('🎥 [SimpleDinorTV] Vidéo $i:');
          print('   - ID: ${video['id']}');
          print('   - Title: ${video['title']}');
          print('   - Video URL: ${video['video_url']}');
          print('   - YouTube URL: ${video['youtube_url']}');
          print('   - All keys: ${video.keys.toList()}');
        }
      } else {
        throw Exception('Erreur API: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [SimpleDinorTV] Erreur: $e');
      setState(() {
        isLoading = false;
        error = e.toString();
      });
    }
  }

  void _openVideo(Map<String, dynamic> video) {
    print('🎥 [SimpleDinorTV] _openVideo appelé pour vidéo: ${video['title']}');
    
    // Chercher une URL de vidéo dans différents champs possibles
    String? videoUrl = video['video_url'] ?? video['youtube_url'] ?? video['url'];
    
    print('🎥ِ [SimpleDinorTV] URL trouvée: $videoUrl');
    
    if (videoUrl == null || videoUrl.isEmpty) {
      print('❌ [SimpleDinorTV] Aucune URL de vidéo trouvée');
      _showSnackBar('Aucune URL de vidéo disponible', Colors.red);
      return;
    }
    
    print('🎬 [SimpleDinorTV] Ouverture vidéo intégrée');
    
    // Afficher la modal vidéo YouTube intégrée
    showDialog(
      context: context,
      barrierDismissible: true,
      useRootNavigator: true,
      builder: (context) => YouTubeVideoModal(
        isOpen: true,
        videoUrl: videoUrl,
        title: video['title'] ?? 'Vidéo Dinor TV',
        onClose: () {
          if (Navigator.of(context, rootNavigator: true).canPop()) {
            Navigator.of(context, rootNavigator: true).pop();
          }
        },
      ),
    );
  }
  
  String _convertEmbedToNormalUrl(String url) {
    // Si c'est une URL embed, la convertir en URL normale
    if (url.contains('/embed/')) {
      final regex = RegExp(r'/embed/([a-zA-Z0-9_-]+)');
      final match = regex.firstMatch(url);
      if (match != null) {
        final videoId = match.group(1);
        return 'https://www.youtube.com/watch?v=$videoId';
      }
    }
    
    // Si c'est déjà une URL normale, la retourner telle quelle
    return url;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: const AppHeader(
        title: 'Dinor TV',
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE53E3E)),
            ),
            SizedBox(height: 16),
            Text(
              'Chargement des vidéos...',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 16,
                color: Color(0xFF4A5568),
              ),
            ),
          ],
        ),
      );
    }

    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Color(0xFFE53E3E),
              ),
              const SizedBox(height: 16),
              const Text(
                'Erreur de connexion',
                style: TextStyle(
                  fontFamily: 'OpenSans',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error!,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 14,
                  color: Color(0xFF4A5568),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    isLoading = true;
                    error = null;
                  });
                  _loadVideos();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53E3E),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (videos.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.play_circle,
              size: 64,
              color: Color(0xFF718096),
            ),
            SizedBox(height: 16),
            Text(
              'Aucune vidéo trouvée',
              style: TextStyle(
                fontFamily: 'OpenSans',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3748),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadVideos,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: videos.length,
        itemBuilder: (context, index) {
          final video = videos[index];
          return _buildVideoCard(video);
        },
      ),
    );
  }

  Widget _buildVideoCard(Map<String, dynamic> video) {
    final title = video['title'] ?? video['name'] ?? 'Vidéo sans titre';
    final description = video['description'] ?? video['excerpt'] ?? 'Aucune description';
    final imageUrl = video['image'] ?? video['thumbnail'] ?? video['featured_image'];
    final duration = video['duration'] ?? video['length'] ?? '5:00';
    
    return GestureDetector(
      onTap: () {
        print('🎥 [SimpleDinorTV] Card cliquée pour: $title');
        _openVideo(video);
      },
      child: Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail avec bouton play
          Stack(
            children: [
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  color: const Color(0xFFF7FAFC),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: imageUrl != null 
                    ? Image.network(
                        imageUrl,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildDefaultThumbnail();
                        },
                      )
                    : _buildDefaultThumbnail(),
                ),
              ),
              // Bouton play overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.play_circle_fill,
                      size: 64,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              // Durée
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    duration,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
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
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 14,
                    color: Color(0xFF4A5568),
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.play_circle_outline,
                      size: 16,
                      color: Color(0xFF718096),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      video['views'] != null ? '${video['views']} vues' : 'Nouveau',
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 12,
                        color: Color(0xFF718096),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3182CE).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Vidéo',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF3182CE),
                        ),
                      ),
                    ),
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

  Widget _buildDefaultThumbnail() {
    return Container(
      height: 200,
      color: const Color(0xFFF7FAFC),
      child: const Center(
        child: Icon(
          Icons.play_circle,
          size: 48,
          color: Color(0xFF3182CE),
        ),
      ),
    );
  }
}