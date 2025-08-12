/**
 * SWIPEABLE_DETAIL_SCREEN.DART - ÉCRAN DE DÉTAIL AVEC NAVIGATION PAR SWIPE
 * 
 * FONCTIONNALITÉS :
 * - Navigation par swipe entre les fiches de détail
 * - Support des recettes, astuces, événements, vidéos
 * - Indicateur de position (dots)
 * - Navigation par boutons
 * - Animations fluides
 * - Analytics tracking
 */

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

// Écrans de détail
import 'recipe_detail_screen.dart';
import 'tip_detail_screen.dart';
import 'event_detail_screen.dart';

// Services
import '../services/analytics_service.dart';
import '../services/analytics_tracker.dart';
import '../services/api_service.dart';

// Types de contenu supportés
enum ContentType {
  recipe,
  tip,
  event,
  video,
}

class SwipeableDetailScreen extends ConsumerStatefulWidget {
  final String initialId;
  final ContentType initialType;
  final List<Map<String, dynamic>>? items; // Liste optionnelle d'items pour navigation
  
  const SwipeableDetailScreen({
    Key? key,
    required this.initialId,
    required this.initialType,
    this.items,
  }) : super(key: key);

  @override
  ConsumerState<SwipeableDetailScreen> createState() => _SwipeableDetailScreenState();
}

class _SwipeableDetailScreenState extends ConsumerState<SwipeableDetailScreen> 
    with TickerProviderStateMixin, AnalyticsScreenMixin {
  
  @override
  String get screenName => 'swipeable_detail';
  
  late PageController _pageController;
  late TabController _tabController;
  
  // État de navigation
  int _currentIndex = 0;
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;
  
  // Animation
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Analytics
  DateTime _screenStartTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    
    print('🔄 [SwipeableDetail] Initialisation avec type: ${widget.initialType}, ID: ${widget.initialId}');
    
    // Initialiser les contrôleurs
    _pageController = PageController();
    _tabController = TabController(length: 4, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    // Charger les données
    _loadItems();
    
    // Démarrer l'animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Charger les items pour la navigation
  Future<void> _loadItems() async {
    try {
      setState(() => _loading = true);
      
      if (widget.items != null) {
        // Utiliser les items fournis
        _items = widget.items!;
        _currentIndex = _findInitialIndex();
      } else {
        // Charger les items depuis l'API
        await _loadItemsFromApi();
      }
      
      setState(() => _loading = false);
      
      // Analytics: écran chargé
      AnalyticsService.logScreenView(
        screenName: 'swipeable_detail_${widget.initialType.name}',
        parameters: {
          'content_type': widget.initialType.name,
          'content_id': widget.initialId,
          'total_items': _items.length,
        },
      );
      
    } catch (error) {
      print('❌ [SwipeableDetail] Erreur chargement items: $error');
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  // Charger les items depuis l'API
  Future<void> _loadItemsFromApi() async {
    final apiService = ref.read(apiServiceProvider);
    
    // Charger les items selon le type initial
    switch (widget.initialType) {
      case ContentType.recipe:
        final data = await apiService.get('/recipes', params: {
          'limit': '20',
          'sort_by': 'created_at',
          'sort_order': 'desc',
        });
        if (data['success']) {
          _items = List<Map<String, dynamic>>.from(data['data']);
        }
        break;
        
      case ContentType.tip:
        final data = await apiService.get('/tips', params: {
          'limit': '20',
          'sort_by': 'created_at',
          'sort_order': 'desc',
        });
        if (data['success']) {
          _items = List<Map<String, dynamic>>.from(data['data']);
        }
        break;
        
      case ContentType.event:
        final data = await apiService.get('/events', params: {
          'limit': '20',
          'sort_by': 'created_at',
          'sort_order': 'desc',
        });
        if (data['success']) {
          _items = List<Map<String, dynamic>>.from(data['data']);
        }
        break;
        
      case ContentType.video:
        final data = await apiService.get('/dinor-tv', params: {
          'limit': '20',
          'sort_by': 'created_at',
          'sort_order': 'desc',
        });
        if (data['success']) {
          _items = List<Map<String, dynamic>>.from(data['data']);
        }
        break;
    }
    
    _currentIndex = _findInitialIndex();
  }

  // Trouver l'index de l'item initial
  int _findInitialIndex() {
    for (int i = 0; i < _items.length; i++) {
      if (_items[i]['id'].toString() == widget.initialId) {
        return i;
      }
    }
    return 0;
  }

  // Navigation vers l'item suivant
  void _nextItem() {
    if (_currentIndex < _items.length - 1) {
      _goToItem(_currentIndex + 1);
    }
  }

  // Navigation vers l'item précédent
  void _previousItem() {
    if (_currentIndex > 0) {
      _goToItem(_currentIndex - 1);
    }
  }

  // Aller à un item spécifique
  void _goToItem(int index) {
    if (index >= 0 && index < _items.length) {
      setState(() => _currentIndex = index);
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      
      // Analytics: navigation
      final item = _items[index];
      AnalyticsTracker.trackNavigation(
        fromScreen: 'swipeable_detail_${widget.initialType.name}',
        toScreen: 'swipeable_detail_${widget.initialType.name}',
        method: 'swipe',
      );
      
      AnalyticsService.logViewContent(
        contentType: widget.initialType.name,
        contentId: item['id'].toString(),
        contentName: item['title'] ?? 'Contenu',
      );
    }
  }

  // Obtenir le type de contenu d'un item
  ContentType _getContentType(Map<String, dynamic> item) {
    if (item.containsKey('ingredients') || item.containsKey('instructions')) {
      return ContentType.recipe;
    } else if (item.containsKey('difficulty_level')) {
      return ContentType.tip;
    } else if (item.containsKey('event_date')) {
      return ContentType.event;
    } else if (item.containsKey('video_url')) {
      return ContentType.video;
    }
    return widget.initialType;
  }

  // Construire l'écran de détail approprié
  Widget _buildDetailScreen(Map<String, dynamic> item) {
    final contentType = _getContentType(item);
    final itemId = item['id'].toString();
    
    switch (contentType) {
      case ContentType.recipe:
        return RecipeDetailScreen(id: itemId);
        
      case ContentType.tip:
        return TipDetailScreen(id: itemId);
        
      case ContentType.event:
        return EventDetailScreen(id: itemId);
        
      case ContentType.video:
        // Pour les vidéos, on peut créer un écran de détail vidéo
        return _buildVideoDetailScreen(item);
    }
  }

  // Écran de détail pour les vidéos
  Widget _buildVideoDetailScreen(Map<String, dynamic> video) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 56,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          video['title'] ?? 'Vidéo',
          style: const TextStyle(
            fontFamily: 'OpenSans',
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vidéo
            if (video['video_url'] != null)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.black,
                  ),
                  child: Center(
                    child: Icon(
                      LucideIcons.play,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Titre
            Text(
              video['title'] ?? 'Vidéo',
              style: const TextStyle(
                fontFamily: 'OpenSans',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Description
            if (video['description'] != null)
              Text(
                video['description'],
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 16,
                  color: Color(0xFF4A5568),
                  height: 1.5,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    //super.build(context);
    
    if (_loading) {
      return _buildLoadingState();
    }
    
    if (_error != null) {
      return _buildErrorState();
    }
    
    if (_items.isEmpty) {
      return _buildEmptyState();
    }
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // PageView principal
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
                
                // Analytics: changement de page
                final item = _items[index];
                AnalyticsService.logScreenView(
                  screenName: 'swipeable_detail_${widget.initialType.name}',
                  parameters: {
                    'content_type': widget.initialType.name,
                    'content_id': item['id'].toString(),
                    'page_index': index,
                  },
                );
              },
              itemCount: _items.length,
              itemBuilder: (context, index) {
                return _buildDetailScreen(_items[index]);
              },
            ),
            
            // Indicateur de position (dots)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 0,
              right: 0,
              child: _buildPageIndicator(),
            ),
            
            // Boutons de navigation
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 16,
              left: 16,
              right: 16,
              child: _buildNavigationButtons(),
            ),
            
            // Bouton fermer
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: _buildCloseButton(),
            ),
          ],
        ),
      ),
    );
  }

  // Indicateur de position
  Widget _buildPageIndicator() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            _items.length,
            (index) => Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: index == _currentIndex 
                  ? Colors.white 
                  : Colors.white.withOpacity(0.4),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Boutons de navigation
  Widget _buildNavigationButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Bouton précédent
        if (_currentIndex > 0)
          FloatingActionButton(
            onPressed: _previousItem,
            backgroundColor: Colors.orange,
            child: const Icon(LucideIcons.chevronLeft, color: Colors.white),
          )
        else
          const SizedBox(width: 56),
        
        // Indicateur de position
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${_currentIndex + 1} / ${_items.length}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        
        // Bouton suivant
        if (_currentIndex < _items.length - 1)
          FloatingActionButton(
            onPressed: _nextItem,
            backgroundColor: Colors.orange,
            child: const Icon(LucideIcons.chevronRight, color: Colors.white),
          )
        else
          const SizedBox(width: 56),
      ],
    );
  }

  // Bouton fermer
  Widget _buildCloseButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(LucideIcons.x, color: Colors.white),
      ),
    );
  }

  // État de chargement
  Widget _buildLoadingState() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
            ),
            const SizedBox(height: 16),
            Text(
              'Chargement...',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // État d'erreur
  Widget _buildErrorState() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.alertCircle,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: TextStyle(
                fontFamily: 'OpenSans',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Une erreur est survenue',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadItems,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  // État vide
  Widget _buildEmptyState() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.inbox,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun contenu disponible',
              style: TextStyle(
                fontFamily: 'OpenSans',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Aucun ${widget.initialType.name} trouvé',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 