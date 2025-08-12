import '../services/navigation_service.dart';
/**
 * EVENT_DETAIL_SCREEN.DART - ÉCRAN DÉTAIL ÉVÉNEMENT
 * 
 * FIDÉLITÉ VISUELLE :
 * - Design moderne avec image hero
 * - Informations complètes de l'événement
 * - Section commentaires
 * - Like/Favorite functionality
 * 
 * FIDÉLITÉ FONCTIONNELLE :
 * - Chargement des détails via API
 * - Gestion d'état avec Riverpod
 * - Système de commentaires
 * - Partage social
 */

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

// Composables
import '../composables/use_auth_handler.dart';
import '../composables/use_comments.dart';
import '../composables/use_social_share.dart';

// Components
import '../components/common/like_button.dart';
import '../components/common/unified_like_button.dart';
import '../components/common/auth_modal.dart';
import '../components/common/share_modal.dart';
import '../components/common/image_gallery_carousel.dart';
import '../components/common/maps_modal.dart';

// Services
import '../services/api_service.dart';

class EventDetailScreen extends ConsumerStatefulWidget {
  final String id;
  
  const EventDetailScreen({Key? key, required this.id}) : super(key: key);

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen> with AutomaticKeepAliveClientMixin {
  bool _showAuthModal = false;
  String _authModalMessage = '';
  bool _showShareModal = false;
  Map<String, dynamic>? _event;
  bool _loading = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    print('📅 [EventDetailScreen] Écran détail événement initialisé: ${widget.id}');
    _loadEventDetails();
  }

  Future<void> _loadEventDetails() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      print('📅 [EventDetailScreen] Chargement détails événement: ${widget.id}');
      final apiService = ref.read(apiServiceProvider);
      final data = await apiService.get('/events/${widget.id}');

      if (data['success'] == true) {
        print('📅 [EventDetailScreen] Données reçues: ${data['data']}');
        setState(() {
          _event = data['data'];
          _loading = false;
        });
        print('✅ [EventDetailScreen] Détails événement chargés');
      } else {
        throw Exception(data['message'] ?? 'Erreur lors du chargement de l\'événement');
      }
    } catch (error) {
      print('❌ [EventDetailScreen] Erreur: $error');
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  // Note: _handleLikeTap removed - now handled by UnifiedLikeButton

  void _handleFavoriteTap() async {
    final authHandler = ref.read(useAuthHandlerProvider.notifier);
    
    // Vérifier si l'utilisateur est connecté
    final authState = ref.read(useAuthHandlerProvider);
    if (!authState.isAuthenticated) {
      _authModalMessage = 'Connectez-vous pour ajouter aux favoris';
      _displayAuthModal();
      return;
    }

    try {
      // TODO: Implémenter toggle favorite
      print('⭐ [EventDetailScreen] Favorite événement: ${widget.id}');
    } catch (error) {
      print('❌ [EventDetailScreen] Erreur favorite: $error');
    }
  }

  void _handleShareTap() async {
    if (_event == null) return;
    
    setState(() {
      _showShareModal = true;
    });
  }

  void _closeShareModal() {
    setState(() {
      _showShareModal = false;
    });
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
    
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8F9FA),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF4D03F)),
              ),
              SizedBox(height: 16),
              Text(
                'Chargement de l\'événement...',
                style: TextStyle(
                  fontFamily: 'OpenSans',
                  fontSize: 16,
                  color: Color(0xFF718096),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: const Text('Erreur'),
          backgroundColor: Colors.white,
          elevation: 0,
          toolbarHeight: 56,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF2D3748)),
            onPressed: () => NavigationService.pop(),
          ),
        ),
        body: Center(
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
                'Erreur de chargement',
                style: TextStyle(
                  fontFamily: 'OpenSans',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(
                  fontFamily: 'OpenSans',
                  fontSize: 14,
                  color: Color(0xFF718096),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadEventDetails,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF4D03F),
                  foregroundColor: const Color(0xFF2D3748),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (_event == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8F9FA),
        body: Center(
          child: Text(
            'Événement non trouvé',
            style: TextStyle(
              fontFamily: 'OpenSans',
              fontSize: 18,
              color: Color(0xFF2D3748),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // App bar avec image
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: Colors.white,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => NavigationService.pop(),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.share, color: Colors.white),
                    onPressed: _handleShareTap,
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildHeroImage(),
                ),
              ),
              // Contenu
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildEventInfo(),
                      const SizedBox(height: 24),
                      _buildEventDescription(),
                      const SizedBox(height: 24),
                      _buildEventGallery(),
                      _buildEventDetails(),
                      const SizedBox(height: 24),
                      _buildCommentsSection(),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Share Modal
          if (_showShareModal && _event != null)
            ShareModal(
              isOpen: _showShareModal,
              shareData: {
                'title': _event!['title'],
                'text': _event!['description'],
                'url': 'https://new.dinorapp.com/pwa/event/${widget.id}',
                'image': _event!['image'] ?? _event!['thumbnail'],
              },
              onClose: _closeShareModal,
            ),
        ],
      ),
    );
  }

  Widget _buildHeroImage() {
    final image = _event!['image'] ?? _event!['thumbnail'] ?? '';
    
    return Stack(
      children: [
        // Image de fond
        Positioned.fill(
          child: image.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: image,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: const Color(0xFFE2E8F0),
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF4D03F)),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: const Color(0xFFE2E8F0),
                    child: const Icon(
                      Icons.event_outlined,
                      size: 64,
                      color: Color(0xFFCBD5E0),
                    ),
                  ),
                )
              : Container(
                  color: const Color(0xFFE2E8F0),
                  child: const Icon(
                    Icons.event_outlined,
                    size: 64,
                    color: Color(0xFFCBD5E0),
                  ),
                ),
        ),
        // Gradient overlay
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
      ],
    );
  }

  Widget _buildEventInfo() {
    final title = _event!['title'] ?? 'Sans titre';
    final category = _event!['category']?['name'] ?? '';
    final likes = _event!['likes_count'] ?? 0;
    final isLiked = _event!['is_liked'] ?? false;
    final isFavorited = _event!['is_favorited'] ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category badge
        if (category.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF4D03F),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              category,
              style: const TextStyle(
                fontFamily: 'OpenSans',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFFF4D03F),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        // Title
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'OpenSans',
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 16),
        // Actions
        Row(
          children: [
            // Like button with count - Using unified component
            UnifiedLikeButton(
              type: 'event',
              itemId: widget.id,
              initialLiked: isLiked,
              initialCount: likes,
              showCount: true,
              size: 'medium',
              variant: 'standard',
              autoFetch: true,
              onAuthRequired: () => setState(() => _showAuthModal = true),
            ),
            // Favorite button
            IconButton(
              onPressed: _handleFavoriteTap,
              icon: Icon(
                isFavorited ? Icons.favorite : Icons.favorite_border,
                color: isFavorited ? const Color(0xFFE53E3E) : Colors.grey[600],
                size: 24,
              ),
            ),
            const Spacer(),
            // Share button
            IconButton(
              onPressed: _handleShareTap,
              icon: Icon(
                Icons.share,
                color: Colors.grey[600],
                size: 24,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEventDescription() {
    final description = _event!['description'] ?? '';
    
    if (description.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Description',
          style: TextStyle(
            fontFamily: 'OpenSans',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: const TextStyle(
            fontFamily: 'OpenSans',
            fontSize: 16,
            color: Color(0xFF4A5568),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      print('❌ [EventDetailScreen] Erreur parsing date: $dateString');
      return dateString;
    }
  }

  String _getEventDate() {
    if (_event == null) return '';
    
    // Essayer différents champs possibles pour la date
    final possibleDateFields = ['date', 'event_date', 'start_date', 'scheduled_date'];
    for (final field in possibleDateFields) {
      final value = _event![field];
      if (value != null && value.toString().isNotEmpty) {
        print('📅 [EventDetailScreen] Date trouvée dans $field: $value');
        return _formatDate(value.toString());
      }
    }
    
    print('⚠️ [EventDetailScreen] Aucune date trouvée dans: ${_event!.keys.toList()}');
    return '';
  }

  String _getEventTime() {
    if (_event == null) return '';
    
    // Essayer différents champs possibles pour l'heure
    final possibleTimeFields = ['time', 'event_time', 'start_time', 'scheduled_time'];
    for (final field in possibleTimeFields) {
      final value = _event![field];
      if (value != null && value.toString().isNotEmpty) {
        print('🕐 [EventDetailScreen] Heure trouvée dans $field: $value');
        return _formatTime(value.toString());
      }
    }
    
    print('⚠️ [EventDetailScreen] Aucune heure trouvée dans: ${_event!.keys.toList()}');
    return 'Non défini';
  }

  String _formatTime(String timeString) {
    // Si c'est déjà au bon format (HH:mm), le retourner
    if (RegExp(r'^\d{1,2}:\d{2}$').hasMatch(timeString)) {
      return timeString;
    }
    
    // Essayer de parser comme DateTime ISO pour extraire l'heure
    try {
      final dateTime = DateTime.parse(timeString);
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      // Si ce n'est pas parsable, retourner tel quel
      return timeString;
    }
  }

  Widget _buildEventGallery() {
    // Vérifier si l'événement a des images de galerie
    if (_event!['gallery_urls'] != null && (_event!['gallery_urls'] as List).isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: ImageGalleryCarousel(
          images: List<String>.from(_event!['gallery_urls']),
          title: 'Galerie photos',
          height: 240,
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildEventDetails() {
    final date = _getEventDate();
    final time = _getEventTime();
    final location = _event!['location'] ?? _event!['venue'] ?? '';
    final organizer = _event!['organizer'] ?? _event!['organiser'] ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Détails de l\'événement',
            style: TextStyle(
              fontFamily: 'OpenSans',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 16),
          if (date.isNotEmpty) ...[
            _buildDetailRow(Icons.calendar_today_outlined, 'Date', date),
            const SizedBox(height: 12),
          ],
          if (time != 'Non défini') ...[
            _buildDetailRow(Icons.access_time_outlined, 'Heure', time),
            const SizedBox(height: 12),
          ],
          if (location.isNotEmpty) ...[
            _buildLocationRow(location),
            const SizedBox(height: 12),
          ],
          if (organizer.isNotEmpty) ...[
            _buildDetailRow(Icons.person_outlined, 'Organisateur', organizer),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: const Color(0xFFF4D03F),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'OpenSans',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF718096),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'OpenSans',
                  fontSize: 14,
                  color: Color(0xFF2D3748),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationRow(String location) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.location_on_outlined,
          size: 20,
          color: const Color(0xFFF4D03F),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Lieu',
                style: const TextStyle(
                  fontFamily: 'OpenSans',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF718096),
                ),
              ),
              const SizedBox(height: 2),
              GestureDetector(
                onTap: () => showMapsModal(context, location),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        location,
                        style: const TextStyle(
                          fontFamily: 'OpenSans',
                          fontSize: 14,
                          color: Color(0xFF3182CE), // Bleu pour indiquer que c'est cliquable
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.map_outlined,
                      size: 16,
                      color: const Color(0xFF3182CE),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openGoogleMaps(String location) async {
    try {
      // Encoder l'adresse pour l'URL
      final encodedLocation = Uri.encodeComponent(location);
      
      // URLs pour différentes plateformes
      final googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=$encodedLocation';
      final appleMapsUrl = 'http://maps.apple.com/?q=$encodedLocation';
      
      // Essayer d'abord Google Maps
      final googleMapsUri = Uri.parse(googleMapsUrl);
      if (await canLaunchUrl(googleMapsUri)) {
        await launchUrl(googleMapsUri, mode: LaunchMode.externalApplication);
        print('📍 [EventDetailScreen] Ouverture Google Maps: $location');
        return;
      }
      
      // Fallback vers Apple Maps (iOS)
      final appleMapsUri = Uri.parse(appleMapsUrl);
      if (await canLaunchUrl(appleMapsUri)) {
        await launchUrl(appleMapsUri, mode: LaunchMode.externalApplication);
        print('📍 [EventDetailScreen] Ouverture Apple Maps: $location');
        return;
      }
      
      // Fallback vers navigateur web
      final webUri = Uri.parse(googleMapsUrl);
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
      print('📍 [EventDetailScreen] Ouverture navigateur: $location');
      
    } catch (e) {
      print('❌ [EventDetailScreen] Erreur ouverture Maps: $e');
      
      // Afficher un message d'erreur à l'utilisateur
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Impossible d\'ouvrir la carte pour: $location'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildCommentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Commentaires',
          style: TextStyle(
            fontFamily: 'OpenSans',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 16),
        // TODO: Implémenter la section commentaires
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Colors.black,
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'Section commentaires à implémenter',
              style: TextStyle(
                fontFamily: 'OpenSans',
                fontSize: 14,
                color: Color(0xFF718096),
              ),
            ),
          ),
        ),
      ],
    );
  }
}