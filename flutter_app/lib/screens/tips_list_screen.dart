import '../services/navigation_service.dart';
/**
 * TIPS_LIST_SCREEN.DART - CONVERSION FIDÈLE DE TipsList.vue
 * 
 * FIDÉLITÉ VISUELLE :
 * - BannerSection identique : bannières avec gradients
 * - SearchAndFilters identique : recherche et filtres avancés
 * - Tip cards identiques : design et layout
 * - Couleurs identiques : #FFFFFF fond, #F4D03F doré, #FF6B35 orange
 * - Polices identiques : Roboto textes, Open Sans titres
 * 
 * FIDÉLITÉ FONCTIONNELLE :
 * - Setup() identique : composables pour données
 * - Computed identiques : filteredTips, hasActiveFilters
 * - Handlers identiques : goToTip, clearAllFilters
 * - AuthModal : même gestion d'authentification
 * - Refresh system : même système de rafraîchissement
 */

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';

// Components
import '../components/common/banner_section.dart';
import '../components/common/search_and_filters.dart';
import '../components/common/like_button.dart';
import '../components/common/auth_modal.dart';
import '../components/common/share_modal.dart';
import '../components/dinor_icon.dart';

// Services et composables
import '../services/api_service.dart';
import '../services/image_service.dart';
import '../composables/use_tips.dart';
import '../composables/use_banners.dart';
import '../composables/use_auth_handler.dart';
import '../composables/use_social_share.dart';

class TipsListScreen extends ConsumerStatefulWidget {
  const TipsListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<TipsListScreen> createState() => _TipsListScreenState();
}

class _TipsListScreenState extends ConsumerState<TipsListScreen>
    with AutomaticKeepAliveClientMixin {
  // État identique au setup() Vue
  bool _showAuthModal = false;
  bool _showShareModal = false;
  Map<String, dynamic>? _shareData;

  // Données
  List<dynamic> _tips = [];
  List<dynamic> _categories = [];
  List<dynamic> _banners = [];

  // États de chargement
  bool _loading = true;
  bool _loadingBanners = true;
  bool _loadingCategories = true;

  // Erreurs
  String? _error;
  String? _bannersError;
  String? _categoriesError;

  // Filtres et recherche
  String _searchQuery = '';
  String? _selectedCategory;
  Map<String, dynamic> _selectedFilters = {};

  // Filtres additionnels
  final List<Map<String, dynamic>> _additionalFilters = [
    {
      'key': 'difficulty',
      'label': 'Difficulté',
      'icon': 'star',
      'allLabel': 'Toutes',
      'options': [
        {'value': 'beginner', 'label': 'Débutant'},
        {'value': 'easy', 'label': 'Facile'},
        {'value': 'medium', 'label': 'Intermédiaire'},
        {'value': 'hard', 'label': 'Difficile'},
        {'value': 'expert', 'label': 'Expert'},
      ],
    },
    {
      'key': 'type',
      'label': 'Type',
      'icon': 'tag',
      'allLabel': 'Tous',
      'options': [
        {'value': 'cooking', 'label': 'Cuisine'},
        {'value': 'preparation', 'label': 'Préparation'},
        {'value': 'storage', 'label': 'Conservation'},
        {'value': 'technique', 'label': 'Technique'},
        {'value': 'equipment', 'label': 'Équipement'},
      ],
    },
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    print('💡 [TipsListScreen] Écran liste astuces initialisé');
    _loadData();
  }

  // REPRODUCTION EXACTE du chargement de données Vue
  Future<void> _loadData() async {
    print('🔄 [TipsListScreen] Chargement des données');

    // Charger en parallèle (identique Vue)
    await Future.wait([
      _loadTips(),
      _loadBanners(),
      _loadCategories(),
    ]);

    print('✅ [TipsListScreen] Toutes les données chargées');
  }

  Future<void> _loadTips({bool forceRefresh = false}) async {
    try {
      print(
          '💡 [TipsListScreen] Chargement astuces ForceRefresh: $forceRefresh');
      setState(() => _loading = true);

      final tips = forceRefresh
          ? await ref.read(useTipsProvider.notifier).fetchTipsFresh()
          : await ref.read(useTipsProvider.notifier).fetchTips();

      setState(() {
        _tips = tips;
        _loading = false;
      });

      print('✅ [TipsListScreen] ${tips.length} astuces chargées');
    } catch (error) {
      print('❌ [TipsListScreen] Erreur chargement astuces: $error');
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadBanners() async {
    try {
      print('🖼️ [TipsListScreen] Chargement bannières pour tips');
      setState(() => _loadingBanners = true);

      final banners = await ref
          .read(useBannersProvider.notifier)
          .loadBannersForContentType('Tip');

      setState(() {
        _banners = banners;
        _loadingBanners = false;
      });

      print('✅ [TipsListScreen] ${banners.length} bannières chargées');
    } catch (error) {
      print('❌ [TipsListScreen] Erreur chargement bannières: $error');
      setState(() {
        _bannersError = error.toString();
        _loadingBanners = false;
      });
    }
  }

  Future<void> _loadCategories() async {
    try {
      print('📂 [TipsListScreen] Chargement catégories astuces');
      setState(() => _loadingCategories = true);

      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.get('/tip-categories');

      if (response['success']) {
        final categories = response['data'] as List<dynamic>;
        setState(() {
          _categories = categories;
          _loadingCategories = false;
        });

        print('✅ [TipsListScreen] ${categories.length} catégories chargées');
      }
    } catch (error) {
      print('❌ [TipsListScreen] Erreur chargement catégories: $error');
      setState(() {
        _categoriesError = error.toString();
        _loadingCategories = false;
      });
    }
  }

  Future<void> _forceRefresh() async {
    print('🔄 [TipsListScreen] Rechargement forcé demandé');
    setState(() => _loading = true);
    try {
      await _loadTips(forceRefresh: true);
      await _loadBanners();
      print('✅ [TipsListScreen] Rechargement forcé terminé');
    } catch (error) {
      print('❌ [TipsListScreen] Erreur lors du rechargement forcé: $error');
    }
  }

  void _goToTip(String id) {
    print('💡 [TipsListScreen] Navigation vers astuce ID: $id');
    NavigationService.pushNamed('/tips/$id');
  }

  void _onSearchQueryChanged(String query) {
    setState(() => _searchQuery = query);
    print('🔍 [TipsListScreen] Recherche mise à jour: $query');
  }

  void _onSelectedCategoryChanged(String? categoryId) {
    setState(() => _selectedCategory = categoryId);
    print('📂 [TipsListScreen] Catégorie sélectionnée: $categoryId');
  }

  void _onAdditionalFilterChanged(String key, dynamic value) {
    setState(() {
      if (value == null) {
        _selectedFilters.remove(key);
      } else {
        _selectedFilters[key] = value;
      }
    });
    print('🔧 [TipsListScreen] Filtre $key mis à jour: $value');
  }

  void _clearAllFilters() {
    setState(() {
      _searchQuery = '';
      _selectedCategory = null;
      _selectedFilters.clear();
    });
    print('🧹 [TipsListScreen] Tous les filtres effacés');
  }

  void _callShare(dynamic tip) {
    final shareData = {
      'title': tip['title'],
      'text': tip['short_description'] ??
          'Découvrez cette astuce : ${tip['title']}',
      'url': 'https://new.dinorapp.com/pwa/tip/${tip['id']}',
      'image': tip['featured_image_url'],
    };

    setState(() {
      _shareData = shareData;
      _showShareModal = true;
    });
  }

  void _closeShareModal() {
    setState(() => _showShareModal = false);
  }

  void _closeAuthModal() {
    setState(() => _showAuthModal = false);
  }

  void _onAuthenticated() {
    setState(() => _showAuthModal = false);
    print('🔐 [TipsListScreen] Utilisateur authentifié');
  }

  // Computed properties (équivalent Vue)
  List<dynamic> get _filteredTips {
    List<dynamic> filtered = _tips;

    // Recherche
    if (_searchQuery.isNotEmpty) {
      filtered = ref.read(useTipsProvider.notifier).searchTips(_searchQuery);
    }

    // Filtre par catégorie
    if (_selectedCategory != null) {
      filtered = ref
          .read(useTipsProvider.notifier)
          .filterTipsByCategory(_selectedCategory!);
    }

    // Filtres additionnels
    _selectedFilters.forEach((key, value) {
      if (value != null) {
        switch (key) {
          case 'difficulty':
            filtered = ref
                .read(useTipsProvider.notifier)
                .filterTipsByDifficulty(value);
            break;
          case 'type':
            filtered = filtered.where((tip) => tip['type'] == value).toList();
            break;
        }
      }
    });

    return filtered;
  }

  bool get _hasActiveFilters {
    return _searchQuery.isNotEmpty ||
        _selectedCategory != null ||
        _selectedFilters.isNotEmpty;
  }

  // Compter le nombre de filtres actifs
  int get _activeFiltersCount {
    int count = 0;
    if (_searchQuery.isNotEmpty) count++;
    if (_selectedCategory != null) count++;
    count += _selectedFilters.values.where((filter) => filter != null).length;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        title: const Text('Astuces'),
      ),
      body: _loading && _tips.isEmpty
          ? _buildLoadingState()
          : _error != null && _tips.isEmpty
              ? _buildErrorState()
              : _buildTipsContent(),
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
            'Chargement des astuces...',
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
            onPressed: () => _loadData(),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsContent() {
    return CustomScrollView(
      slivers: [
        // Banners Section
        if (_banners.isNotEmpty)
          SliverToBoxAdapter(
            child: BannerSection(
              type: 'Tip',
              section: 'main',
              banners: _banners,
            ),
          ),

        // Search and Filters
        SliverToBoxAdapter(
          child: SearchAndFilters(
            searchQuery: _searchQuery,
            onSearchQueryChanged: _onSearchQueryChanged,
            selectedCategory: _selectedCategory,
            onSelectedCategoryChanged: _onSelectedCategoryChanged,
            categories: _categories,
            additionalFilters: _additionalFilters,
            selectedFilters: _selectedFilters,
            onAdditionalFilterChanged: _onAdditionalFilterChanged,
            resultsCount: _filteredTips.length,
            itemType: 'astuce',
            searchPlaceholder: 'Rechercher une astuce...',
          ),
        ),

        // Clear Filters Button
        if (_hasActiveFilters)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton(
                onPressed: _clearAllFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF4D03F),
                  foregroundColor: const Color(0xFF2D3748),
                ),
                child: const Text('Effacer tous les filtres'),
              ),
            ),
          ),

        // Tips List (1 colonne)
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: _filteredTips.isEmpty
              ? SliverToBoxAdapter(
                  child: _buildEmptyState(),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildTipCard(_filteredTips[index]),
                    ),
                    childCount: _filteredTips.length,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            LucideIcons.lightbulb,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune astuce trouvée',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Essayez de modifier vos critères de recherche',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTipCard(dynamic tip) {
    return GestureDetector(
      onTap: () => _goToTip(tip['id'].toString()),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Container(
              height:
                  160, // Hauteur fixe pour un meilleur centrage comme sur la page d'accueil
              decoration: BoxDecoration(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                image: DecorationImage(
                  image: CachedNetworkImageProvider(
                      ImageService.getTipImageUrl(tip)),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    tip['title'] ?? 'Astuce sans titre',
                    style: const TextStyle(
                      fontFamily: 'OpenSans',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D3748),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Description
                  if (tip['short_description'] != null) ...[
                    Text(
                      tip['short_description'],
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 14,
                        color: Color(0xFF4A5568),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Like Button
                      Expanded(
                        child: LikeButton(
                          type: 'tip',
                          itemId: tip['id'].toString(),
                          initialLiked: tip['user_liked'] ?? false,
                          initialCount: tip['likes_count'] ?? 0,
                          showCount: true,
                          size: 'small',
                          onAuthRequired: () =>
                              setState(() => _showAuthModal = true),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Share Button
                      IconButton(
                        onPressed: () => _callShare(tip),
                        icon: const Icon(
                          LucideIcons.share,
                          size: 16,
                          color: Color(0xFF49454F),
                        ),
                        tooltip: 'Partager cette astuce',
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
}
