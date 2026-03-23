import '../services/navigation_service.dart';
/**
 * RECIPES_LIST_SCREEN.DART - CONVERSION FIDÈLE DE RecipesList.vue
 * 
 * FIDÉLITÉ VISUELLE :
 * - BannerSection identique : bannières avec gradients
 * - SearchAndFilters identique : recherche et filtres avancés
 * - Recipe cards identiques : design et layout
 * - Couleurs identiques : #FFFFFF fond, #F4D03F doré, #FF6B35 orange
 * - Polices identiques : Roboto textes, Open Sans titres
 * 
 * FIDÉLITÉ FONCTIONNELLE :
 * - Setup() identique : composables pour données
 * - Computed identiques : filteredRecipes, hasActiveFilters
 * - Handlers identiques : goToRecipe, clearAllFilters
 * - AuthModal : même gestion d'authentification
 * - Refresh system : même système de rafraîchissement
 */

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';

// Components (équivalent des imports Vue)
import '../components/common/banner_section.dart';
import '../components/common/search_and_filters.dart';
import '../components/common/like_button.dart';
import '../components/common/unified_like_button.dart';
import '../components/common/auth_modal.dart';
import '../components/dinor_icon.dart';

// Services et composables
import '../services/api_service.dart';
import '../services/image_service.dart';
import '../composables/use_recipes.dart';
import '../composables/use_banners.dart';
import '../composables/use_auth_handler.dart';


class RecipesListScreen extends ConsumerStatefulWidget {
  const RecipesListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RecipesListScreen> createState() => _RecipesListScreenState();
}

class _RecipesListScreenState extends ConsumerState<RecipesListScreen> with AutomaticKeepAliveClientMixin {
  // État identique au setup() Vue
  bool _showAuthModal = false;
  String _authModalMessage = '';
  bool _showFilters = false;
  
  // Données des composables (équivalent useRecipes, useBanners, etc.)
  List<dynamic> _recipes = [];
  List<dynamic> _categories = [];
  List<dynamic> _banners = [];
  
  // États de chargement (équivalent loading refs Vue)
  bool _loadingRecipes = true;
  bool _loadingCategories = true;
  bool _loadingBanners = true;
  
  // Erreurs (équivalent error refs Vue)
  String? _errorRecipes;
  String? _errorCategories;
  String? _errorBanners;

  // Search et filtres (équivalent computed Vue)
  String _searchQuery = '';
  String? _selectedCategory;
  Map<String, dynamic> _selectedFilters = {};

  // Filtres additionnels pour recettes
  final List<Map<String, dynamic>> _recipeFilters = [
    {
      'key': 'difficulty',
      'label': 'Difficulté',
      'icon': 'star',
      'allLabel': 'Tous niveaux',
      'options': [
        {'value': 'easy', 'label': 'Facile'},
        {'value': 'medium', 'label': 'Moyen'},
        {'value': 'hard', 'label': 'Difficile'}
      ]
    },
    {
      'key': 'prep_time',
      'label': 'Temps de préparation',
      'icon': 'schedule',
      'allLabel': 'Tous temps',
      'options': [
        {'value': 'quick', 'label': '< 30 min'},
        {'value': 'medium', 'label': '30-60 min'},
        {'value': 'long', 'label': '> 60 min'}
      ]
    }
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    
    // Équivalent onMounted() Vue
    print('🍳 [RecipesListScreen] Écran liste recettes initialisé');
    _loadAllData();
  }

  // REPRODUCTION EXACTE du chargement de données Vue
  Future<void> _loadAllData() async {
    print('🔄 [RecipesListScreen] Chargement de toutes les données...');
    
    // Charger toutes les données en parallèle (équivalent composables Vue)
    await Future.wait([
      _loadBanners(),
      _loadRecipes(),
      _loadCategories(),
    ]);
    
    print('✅ [RecipesListScreen] Toutes les données chargées');
  }

  Future<void> _loadBanners() async {
    try {
      print('🖼️ [RecipesListScreen] Chargement bannières pour type: recipes');
      setState(() => _loadingBanners = true);
      
      final banners = await ref.read(useBannersProvider.notifier).loadBannersForContentType('recipes', forceRefresh: true);
      setState(() {
        _banners = banners;
        _loadingBanners = false;
      });
    } catch (error) {
      print('❌ [RecipesListScreen] Erreur chargement bannières: $error');
      setState(() {
        _errorBanners = error.toString();
        _loadingBanners = false;
      });
    }
  }

  Future<void> _loadRecipes() async {
    try {
      print('🍳 [RecipesListScreen] Chargement recettes');
      setState(() => _loadingRecipes = true);
      
      final recipes = await ref.read(useRecipesProvider.notifier).fetchRecipesFresh();
      setState(() {
        _recipes = recipes;
        _loadingRecipes = false;
      });
    } catch (error) {
      print('❌ [RecipesListScreen] Erreur chargement recettes: $error');
      setState(() {
        _errorRecipes = error.toString();
        _loadingRecipes = false;
      });
    }
  }

  Future<void> _loadCategories() async {
    try {
      print('📂 [RecipesListScreen] Chargement catégories');
      setState(() => _loadingCategories = true);
      
      final response = await ref.read(apiServiceProvider).getRecipeCategories();
      if (response['success']) {
        setState(() {
          _categories = response['data'];
          _loadingCategories = false;
        });
      }
    } catch (error) {
      print('❌ [RecipesListScreen] Erreur chargement catégories: $error');
      setState(() {
        _errorCategories = error.toString();
        _loadingCategories = false;
      });
    }
  }

  // COMPUTED PROPERTIES (équivalent Vue)
  List<dynamic> get _filteredRecipes {
    List<dynamic> filtered = List.from(_recipes);

    // Filtre par recherche textuelle
    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((recipe) =>
        (recipe['title']?.toString().toLowerCase().contains(query) ?? false) ||
        (recipe['short_description']?.toString().toLowerCase().contains(query) ?? false) ||
        (recipe['tags'] as List?)?.any((tag) => tag.toString().toLowerCase().contains(query)) == true
      ).toList();
    }

    // Filtre par catégorie
    if (_selectedCategory != null) {
      filtered = filtered.where((recipe) => recipe['category_id'] == _selectedCategory).toList();
    }

    // Filtres additionnels
    if (_selectedFilters['difficulty'] != null) {
      filtered = filtered.where((recipe) => recipe['difficulty'] == _selectedFilters['difficulty']).toList();
    }

    if (_selectedFilters['prep_time'] != null) {
      final prepTime = _selectedFilters['prep_time'];
      filtered = filtered.where((recipe) {
        final time = recipe['preparation_time'] ?? 0;
        if (prepTime == 'quick') return time < 30;
        if (prepTime == 'medium') return time >= 30 && time <= 60;
        if (prepTime == 'long') return time > 60;
        return true;
      }).toList();
    }

    return filtered;
  }

  bool get _hasActiveFilters {
    return _selectedFilters.values.any((filter) => filter != null);
  }

  // Compter le nombre de filtres actifs
  int get _activeFiltersCount {
    int count = 0;
    if (_searchQuery.isNotEmpty) count++;
    if (_selectedCategory != null) count++;
    count += _selectedFilters.values.where((filter) => filter != null).length;
    return count;
  }

  bool get _isLoading {
    return _loadingRecipes || _loadingCategories || _loadingBanners;
  }

  String? get _error {
    return _errorRecipes ?? _errorCategories ?? _errorBanners;
  }

  // HANDLERS (équivalent methods Vue)
  void _goToRecipe(String id) {
    print('🍳 [RecipesListScreen] Navigation vers recette ID: $id');
    NavigationService.pushNamed('/recipe/$id');
  }

  void _clearAllFilters() {
    setState(() {
      _searchQuery = '';
      _selectedCategory = null;
      _selectedFilters = {};
    });
  }

  void _updateSearchQuery(String query) {
    setState(() => _searchQuery = query);
  }

  void _updateSelectedCategory(String? categoryId) {
    setState(() => _selectedCategory = categoryId);
  }

  void _updateAdditionalFilter(String key, dynamic value) {
    setState(() {
      _selectedFilters[key] = value;
    });
  }

  void _toggleFilters() {
    setState(() => _showFilters = !_showFilters);
  }

  Future<void> _forceRefresh() async {
    print('🔄 [RecipesListScreen] Rechargement forcé demandé');
    try {
      // Invalider tous les caches
      ref.read(apiServiceProvider).clearCache();
      ref.read(useRecipesProvider.notifier).clearCache();
      
      // Recharger avec les données fraîches
      await _loadAllData();
      print('✅ [RecipesListScreen] Rechargement forcé terminé');
    } catch (error) {
      print('❌ [RecipesListScreen] Erreur lors du rechargement forcé: $error');
    }
  }

  void _retry() {
    setState(() {
      _errorRecipes = null;
      _errorCategories = null;
      _errorBanners = null;
    });
    _loadAllData();
  }

  String _getDifficultyLabel(String difficulty) {
    const labels = {
      'easy': 'Facile',
      'medium': 'Moyen',
      'hard': 'Difficile'
    };
    return labels[difficulty] ?? difficulty;
  }

  int _getTotalTime(dynamic recipe) {
    final prepTime = recipe['preparation_time'] ?? 0;
    final cookTime = recipe['cooking_time'] ?? 0;
    final restTime = recipe['resting_time'] ?? 0;
    return prepTime + cookTime + restTime;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        title: const Text('Recettes'),
      ),
      body: CustomScrollView(
        slivers: [
          // Bannières
          if (_banners.isNotEmpty)
            SliverToBoxAdapter(
              child: BannerSection(
                type: 'recipes',
                section: 'hero',
                banners: _banners,
              ),
            ),

          // Toggle Filters Button
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _toggleFilters,
                      icon: Icon(
                        _showFilters ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                        size: 20,
                      ),
                      label: Text(
                        _showFilters 
                          ? 'Masquer les filtres' 
                          : 'Afficher les filtres${_activeFiltersCount > 0 ? ' ($_activeFiltersCount)' : ''}',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF2D3748),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _forceRefresh,
                    icon: Icon(
                      LucideIcons.refreshCw,
                      size: 20,
                      color: _isLoading ? Colors.grey : Colors.white,
                    ),
                    label: const Text('Actualiser'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A5568),
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF4A5568)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Search and Filters
          if (_showFilters)
            SliverToBoxAdapter(
              child: SearchAndFilters(
                searchQuery: _searchQuery,
                onSearchQueryChanged: _updateSearchQuery,
                selectedCategory: _selectedCategory,
                onSelectedCategoryChanged: _updateSelectedCategory,
                categories: _categories,
                additionalFilters: _recipeFilters,
                selectedFilters: _selectedFilters,
                onAdditionalFilterChanged: _updateAdditionalFilter,
                resultsCount: _filteredRecipes.length,
                itemType: 'recette',
                searchPlaceholder: 'Rechercher une recette...',
              ),
            ),

          // Content
          if (_isLoading)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Chargement des recettes...',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            )
          else if (_error != null)
            SliverFillRemaining(
              child: Center(
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
                      _error!,
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _retry,
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Results count
                  if (_filteredRecipes.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        '${_filteredRecipes.length} recette${_filteredRecipes.length > 1 ? 's' : ''}'
                        '${_searchQuery.isNotEmpty ? ' pour "$_searchQuery"' : ''}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF49454F),
                        ),
                      ),
                    ),

                  // Empty State
                  if (_filteredRecipes.isEmpty)
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE7E0EC),
                              borderRadius: BorderRadius.circular(32),
                            ),
                            child: const Icon(
                              LucideIcons.utensils,
                              size: 32,
                              color: Color(0xFF49454F),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty || _selectedCategory != null || _hasActiveFilters
                                ? 'Aucune recette trouvée'
                                : 'Aucune recette disponible',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _searchQuery.isNotEmpty || _selectedCategory != null || _hasActiveFilters
                                ? 'Essayez de modifier vos critères de recherche.'
                                : 'Les recettes seront bientôt disponibles.',
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          if (_searchQuery.isNotEmpty || _selectedCategory != null || _hasActiveFilters)
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: ElevatedButton(
                                onPressed: _clearAllFilters,
                                child: const Text('Effacer tous les filtres'),
                              ),
                            ),
                        ],
                      ),
                    )
                  else
                    // Recipes List (1 colonne)
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemCount: _filteredRecipes.length,
                      itemBuilder: (context, index) {
                        final recipe = _filteredRecipes[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildRecipeCard(recipe),
                        );
                      },
                    ),
                ]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecipeCard(dynamic recipe) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        onTap: () => _goToRecipe(recipe['id'].toString()),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recipe Image
            Container(
              height: 200, // Hauteur fixe pour un meilleur centrage comme sur la page d'accueil
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                image: DecorationImage(
                  image: CachedNetworkImageProvider(
                    ImageService.getRecipeImageUrl(recipe)
                  ),
                  fit: BoxFit.cover,
                ),
              ),
              child: Stack(
                children: [
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
                  // Recipe Meta
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Row(
                      children: [
                        if (_getTotalTime(recipe) > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  LucideIcons.clock,
                                  size: 18,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${_getTotalTime(recipe)}min',
                                  style: const TextStyle(
                                    color: Color(0xFF2D3748),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (recipe['difficulty'] != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _getDifficultyLabel(recipe['difficulty']),
                              style: const TextStyle(
                                color: Color(0xFF2D3748),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Recipe Content
            Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe['title'] ?? '',
                      style: const TextStyle(
                        fontFamily: 'OpenSans',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D3748),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (recipe['short_description'] != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        recipe['short_description'],
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 14,
                          color: Color(0xFF4A5568),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const Spacer(),
                    // Recipe Stats
                    Row(
                      children: [
                        Expanded(
                          child: UnifiedLikeButton(
                            type: 'recipe',
                            itemId: recipe['id'].toString(),
                            initialLiked: recipe['is_liked'] ?? false,
                            initialCount: recipe['likes_count'] ?? 0,
                            showCount: true,
                            size: 'small',
                            variant: 'minimal',
                            onAuthRequired: () => setState(() => _showAuthModal = true),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Row(
                          children: [
                            const Icon(
                              LucideIcons.messageCircle,
                              size: 18,
                              color: Color(0xFF8B7000),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${recipe['comments_count'] ?? 0}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF49454F),
                              ),
                            ),
                          ],
                        ),
                        if (recipe['servings'] != null) ...[
                          const SizedBox(width: 16),
                          Row(
                            children: [
                              const Icon(
                                LucideIcons.users,
                                size: 18,
                                color: Color(0xFF8B7000),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${recipe['servings']}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF49454F),
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (recipe['required_equipment'] != null && (recipe['required_equipment'] as List).isNotEmpty)
                          const SizedBox(width: 16),
                        if (recipe['required_equipment'] != null && (recipe['required_equipment'] as List).isNotEmpty)
                          Row(
                            children: [
                              const Icon(
                                LucideIcons.chefHat,
                                size: 18,
                                color: Color(0xFFFF6B35),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${(recipe['required_equipment'] as List).length}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF49454F),
                                ),
                              ),
                            ],
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