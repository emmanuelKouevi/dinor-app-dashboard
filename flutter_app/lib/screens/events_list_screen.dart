import '../services/navigation_service.dart';
/**
 * EVENTS_LIST_SCREEN.DART - ÉCRAN LISTE DES ÉVÉNEMENTS
 * 
 * FIDÉLITÉ VISUELLE :
 * - Design moderne avec cards événement
 * - Pull-to-refresh pour rafraîchir
 * - Loading states et error handling
 * - Navigation vers détail événement
 * 
 * FIDÉLITÉ FONCTIONNELLE :
 * - Chargement des événements via API
 * - Gestion d'état avec Riverpod
 * - Like/Favorite functionality
 * - Filtrage par catégorie
 */

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';

// Composables
import '../composables/use_events.dart';
import '../composables/use_auth_handler.dart';

// Components
import '../components/common/like_button.dart';
import '../components/common/auth_modal.dart';

class EventsListScreen extends ConsumerStatefulWidget {
  const EventsListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<EventsListScreen> createState() => _EventsListScreenState();
}

class _EventsListScreenState extends ConsumerState<EventsListScreen> with AutomaticKeepAliveClientMixin {
  bool _showAuthModal = false;
  String _authModalMessage = '';
  String? _selectedCategory;

  // Compter le nombre de filtres actifs
  int get _activeFiltersCount {
    int count = 0;
    if (_selectedCategory != null) count++;
    return count;
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    print('📅 [EventsListScreen] Écran événements initialisé');
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final params = <String, dynamic>{
      'limit': '20',
      'sort_by': 'date',
      'sort_order': 'desc',
    };
    
    if (_selectedCategory != null) {
      params['category'] = _selectedCategory;
    }

    await ref.read(eventsProvider.notifier).loadEvents(params: params);
  }

  Future<void> _handleRefresh() async {
    print('🔄 [EventsListScreen] Rafraîchissement des événements...');
    await ref.read(eventsProvider.notifier).refresh();
  }

  void _handleEventTap(dynamic event) {
    print('📅 [EventsListScreen] Clic sur événement: ${event['id']}');
    NavigationService.pushNamed('/events/${event['id']}');
  }

  void _handleLikeTap(dynamic event) async {
    final authHandler = ref.read(useAuthHandlerProvider.notifier);
    
    // Vérifier si l'utilisateur est connecté
    final authState = ref.read(useAuthHandlerProvider);
    if (!authState.isAuthenticated) {
      _authModalMessage = 'Connectez-vous pour liker cet événement';
      _displayAuthModal();
      return;
    }

    try {
      // TODO: Implémenter toggle like
      print('👍 [EventsListScreen] Like événement: ${event['id']}');
    } catch (error) {
      print('❌ [EventsListScreen] Erreur like: $error');
    }
  }

  void _handleFavoriteTap(dynamic event) async {
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
      print('⭐ [EventsListScreen] Favorite événement: ${event['id']}');
    } catch (error) {
      print('❌ [EventsListScreen] Erreur favorite: $error');
    }
  }

  void _handleCategoryFilter(String? category) {
    setState(() {
      _selectedCategory = category;
    });
    _loadEvents();
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
    
    final eventsState = ref.watch(eventsProvider);
    final events = eventsState.events;
    final loading = eventsState.loading;
    final error = eventsState.error;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Événements'),
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: _buildBody(events, loading, error),
      ),
    );
  }

  Widget _buildBody(List<dynamic> events, bool loading, String? error) {
    if (loading && events.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF4D03F)),
            ),
            SizedBox(height: 16),
            Text(
              'Chargement des événements...',
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

    if (error != null && events.isEmpty) {
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
              onPressed: _loadEvents,
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

    if (events.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_outlined,
              size: 64,
              color: Color(0xFFCBD5E0),
            ),
            SizedBox(height: 16),
            Text(
              'Aucun événement disponible',
              style: TextStyle(
                fontFamily: 'OpenSans',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3748),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Les nouveaux événements apparaîtront ici',
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

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return _buildEventCard(event);
      },
    );
  }

  Widget _buildEventCard(dynamic event) {
    final image = event['image'] ?? event['thumbnail'] ?? '';
    final title = event['title'] ?? 'Sans titre';
    final description = event['description'] ?? '';
    final date = event['date'] ?? '';
    final location = event['location'] ?? '';
    final category = event['category']?['name'] ?? '';
    final likes = event['likes_count'] ?? 0;
    final isLiked = event['is_liked'] ?? false;
    final isFavorited = event['is_favorited'] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          GestureDetector(
            onTap: () => _handleEventTap(event),
            child: Container(
              height: 180, // Hauteur fixe pour un meilleur centrage comme sur la page d'accueil
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                image: image.isNotEmpty 
                  ? DecorationImage(
                      image: CachedNetworkImageProvider(image),
                      fit: BoxFit.cover,
                    )
                  : null,
                color: image.isEmpty ? const Color(0xFFE2E8F0) : null,
              ),
              child: image.isEmpty 
                ? const Center(
                    child: Icon(
                      Icons.event_outlined,
                      size: 48,
                      color: Color(0xFFCBD5E0),
                    ),
                  )
                : null,
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category badge
                if (category.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4D03F).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
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
                  const SizedBox(height: 8),
                ],
                // Title
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
                // Description
                if (description.isNotEmpty) ...[
                  Text(
                    description,
                    style: const TextStyle(
                      fontFamily: 'OpenSans',
                      fontSize: 14,
                      color: Color(0xFF718096),
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                ],
                // Date and location
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      date,
                      style: TextStyle(
                        fontFamily: 'OpenSans',
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (location.isNotEmpty) ...[
                      const SizedBox(width: 16),
                      Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          style: TextStyle(
                            fontFamily: 'OpenSans',
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                // Stats and actions
                Row(
                  children: [
                    // Likes
                    Icon(
                      Icons.thumb_up_outlined,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$likes',
                      style: TextStyle(
                        fontFamily: 'OpenSans',
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const Spacer(),
                    // Action buttons
                    IconButton(
                      onPressed: () => _handleLikeTap(event),
                      icon: Icon(
                        isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                        color: isLiked ? const Color(0xFFE53E3E) : Colors.grey[600],
                        size: 20,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _handleFavoriteTap(event),
                      icon: Icon(
                        isFavorited ? Icons.favorite : Icons.favorite_border,
                        color: isFavorited ? const Color(0xFFE53E3E) : Colors.grey[600],
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCategoryFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filtrer par catégorie',
              style: TextStyle(
                fontFamily: 'OpenSans',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Toutes les catégories'),
              leading: Radio<String?>(
                value: null,
                groupValue: _selectedCategory,
                onChanged: _handleCategoryFilter,
              ),
              onTap: () => _handleCategoryFilter(null),
            ),
            // TODO: Ajouter les catégories dynamiques
            const ListTile(
              title: Text('Sport'),
              leading: Radio<String?>(value: 'sport', groupValue: null, onChanged: null),
            ),
            const ListTile(
              title: Text('Culture'),
              leading: Radio<String?>(value: 'culture', groupValue: null, onChanged: null),
            ),
            const ListTile(
              title: Text('Musique'),
              leading: Radio<String?>(value: 'music', groupValue: null, onChanged: null),
            ),
          ],
        ),
      ),
    );
  }
}