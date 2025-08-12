import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/api_service.dart';
import '../services/favorites_service.dart';
import '../services/auth_service.dart';
import '../composables/use_auth_handler.dart';
import '../components/common/auth_modal.dart';
import '../components/common/tournament_modals.dart';
import 'favorites_screen.dart';
import 'terms_of_service_screen.dart';
import 'privacy_policy_screen.dart';
import 'cookie_policy_screen.dart';
import '../services/navigation_service.dart';
import 'professional_content_creation_screen.dart';
import 'notifications_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final PageController _pageController = PageController();
  int _currentPageIndex = 0;
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _userProfile;
  List<dynamic>? _userFavorites;
  Map<String, dynamic>? _predictionsStats;
  List<dynamic> _tournaments = [];
  bool _tournamentsLoading = false;

  bool _showAuthModal = false;
  String _activeSection = 'favorites'; // 'favorites', 'predictions', 'settings', 'legal'
  String _selectedFilter = 'all'; // 'all', 'recipes', 'tips', 'events', 'videos'
  bool _predictionsLoading = true;

  List<Map<String, dynamic>> _profileSections = [];
  List<Map<String, dynamic>> _filterTabs = [];

  List<dynamic> get _filteredFavorites {
    if (_selectedFilter == 'all') {
      return _userFavorites ?? [];
    }
    return _userFavorites?.where((f) => f['type'] == _selectedFilter).toList() ?? [];
  }

  @override
  void initState() {
    super.initState();
    _setupSections();
    _loadProfileData();

    _filterTabs = [
      {'key': 'all', 'label': 'Tous', 'icon': LucideIcons.list},
      {'key': 'recipe', 'label': 'Recettes', 'icon': LucideIcons.utensils},
      {'key': 'tip', 'label': 'Astuces', 'icon': LucideIcons.lightbulb},
      {'key': 'event', 'label': 'Événements', 'icon': LucideIcons.calendar},
      {'key': 'dinor_tv', 'label': 'Vidéos', 'icon': LucideIcons.play},
    ];
  }

  void _setupSections() {
    _profileSections = [
      {'key': 'favorites', 'label': 'Favoris', 'icon': LucideIcons.heart},
      // La section pronostics n'est affichée que s'il y a des tournois disponibles
      if (_hasActiveTournaments())
        {'key': 'predictions', 'label': 'Pronostics', 'icon': LucideIcons.trendingUp},
      {'key': 'settings', 'label': 'Paramètres', 'icon': LucideIcons.settings},
      {'key': 'legal', 'label': 'Légal', 'icon': LucideIcons.gavel},
    ];
  }

  /// Vérifie s'il y a des tournois actifs disponibles
  bool _hasActiveTournaments() {
    if (_tournaments.isEmpty) {
      print('🎯 [ProfileScreen] Aucun tournoi trouvé - section pronostics cachée');
      return false;
    }
    
    // Vérifier s'il y a au moins un tournoi avec un statut actif
    final activeTournaments = _tournaments.where((tournament) {
      final status = tournament['status']?.toString().toLowerCase();
      return status == 'active' || status == 'ongoing' || status == 'open';
    }).toList();
    
    if (activeTournaments.isEmpty) {
      print('🎯 [ProfileScreen] Aucun tournoi actif trouvé (${_tournaments.length} tournois au total) - section pronostics cachée');
      return false;
    }
    
    print('✅ [ProfileScreen] ${activeTournaments.length} tournois actifs trouvés - section pronostics affichée');
    return true;
  }

  Future<void> _loadUserData() async {
    // Alias for _loadProfileData
    await _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    print('📊 [ProfileScreen] _loadProfileData démarré');
    if (!ref.read(useAuthHandlerProvider).isAuthenticated) {
      print('❌ [ProfileScreen] Utilisateur non authentifié');
      setState(() {
        _isLoading = false;
        _predictionsLoading = false;
        _tournamentsLoading = false;
      });
      return;
    }
    try {
      print('🔄 [ProfileScreen] Chargement des données API...');
      final apiService = ref.read(apiServiceProvider);
      final profileResponse = await apiService.getUserProfile();
      final favoritesResponse = await apiService.getUserFavorites();
      final predictionsResponse = await apiService.getPredictionsStats();
      final tournamentsResponse = await apiService.getTournaments();

      print('📈 [ProfileScreen] Réponse predictions: $predictionsResponse');

      setState(() {
        _userProfile = profileResponse['success'] ? profileResponse['data'] : null;
        _userFavorites = favoritesResponse['success'] ? favoritesResponse['data'] : [];
        _predictionsStats = predictionsResponse['success'] ? predictionsResponse['data'] : null;
        _tournaments = tournamentsResponse['success'] ? (tournamentsResponse['data'] ?? []) : [];
        _isLoading = false;
        _predictionsLoading = false;
        _tournamentsLoading = false;
      });
      
      // Mettre à jour les sections après le chargement des tournois
      _setupSections();
      
      // Si la section active était 'predictions' mais qu'il n'y a plus de tournois actifs,
      // basculer vers la section 'favorites'
      if (_activeSection == 'predictions' && !_hasActiveTournaments()) {
        _activeSection = 'favorites';
        print('🔄 [ProfileScreen] Section pronostics cachée - basculement vers favoris');
      }
      print('✅ [ProfileScreen] Données chargées avec succès');
    } catch (e) {
      print('❌ [ProfileScreen] Erreur lors du chargement: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _predictionsLoading = false; // CORRECTION: s'assurer que loading est mis à false
        _tournamentsLoading = false;
      });
      
      // Mettre à jour les sections même en cas d'erreur
      _setupSections();
      
      // Si la section active était 'predictions' mais qu'il n'y a plus de tournois actifs,
      // basculer vers la section 'favorites'
      if (_activeSection == 'predictions' && !_hasActiveTournaments()) {
        _activeSection = 'favorites';
        print('🔄 [ProfileScreen] Section pronostics cachée après erreur - basculement vers favoris');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          appBar: AppBar(
            title: const Text(
              'Profil',
              style: TextStyle(
                fontFamily: 'OpenSans',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            backgroundColor: const Color(0xFFE53E3E),
            elevation: 0,
            toolbarHeight: 56,
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ref.watch(useAuthHandlerProvider).isAuthenticated
                  ? _buildAuthenticatedContent()
                  : _buildAuthRequired(),
        ),
        
        // Modal d'authentification
        if (_showAuthModal) ...[
          Positioned.fill(
            child: Container(
              color: Colors.black54,
              child: GestureDetector(
                onTap: () => setState(() => _showAuthModal = false),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          Positioned.fill(
            child: AuthModal(
              isOpen: _showAuthModal,
              onClose: () => setState(() => _showAuthModal = false),
              onAuthenticated: () async {
                setState(() => _showAuthModal = false);
                await _loadUserData(); // Recharger les données utilisateur
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAuthRequired() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFE53E3E).withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                LucideIcons.user,
                size: 48,
                color: Color(0xFFE53E3E),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Profil utilisateur',
              style: TextStyle(
                fontFamily: 'OpenSans',
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Connectez-vous pour voir votre profil et vos favoris',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 16,
                color: Color(0xFF4A5568),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => setState(() => _showAuthModal = true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53E3E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Se connecter'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthenticatedContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Info Section
          _buildUserInfoSection(),
          const SizedBox(height: 24),

          // Profile Navigation
          _buildProfileNavigation(),
          const SizedBox(height: 24),

          // Profile Sections
          _buildProfileSections(),
          
          // Account Section
          if (_activeSection == 'account') _buildAccountSection(),
          
          // Security Section
          if (_activeSection == 'security') _buildSecuritySection(),
        ],
      ),
    );
  }

  Widget _buildUserInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE53E3E), Color(0xFFC53030)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(32),
            ),
            child: const Icon(
              LucideIcons.user,
              size: 32,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userProfile?['name'] ?? ref.watch(useAuthHandlerProvider).userName ?? 'Utilisateur',
                  style: const TextStyle(
                    fontFamily: 'OpenSans',
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                if (_userProfile?['email'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _userProfile!['email'],
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
                if (_userProfile?['created_at'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Membre depuis ${_formatDate(_userProfile!['created_at'])}',
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 12,
                      color: Colors.white60,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileNavigation() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: _profileSections.map((section) {
          final isActive = _activeSection == section['key'];
          return Expanded(
            child: GestureDetector(
              onTap: () {
                print('🔄 [ProfileScreen] Changement de section vers: ${section['key']}');
                setState(() => _activeSection = section['key']);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFFE53E3E) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Icon(
                      section['icon'],
                      size: 20,
                      color: isActive ? Colors.white : const Color(0xFF4A5568),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      section['label'],
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isActive ? Colors.white : const Color(0xFF4A5568),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProfileSections() {
    print('🎯 [ProfileScreen] _buildProfileSections appelé avec _activeSection: $_activeSection');
    switch (_activeSection) {
      case 'favorites':
        print('💖 [ProfileScreen] Affichage section favoris');
        return _buildFavoritesSection();
      case 'predictions':
        print('🎲 [ProfileScreen] Affichage section pronostics');
        return _buildPredictionsSection();
      case 'settings':
        print('⚙️ [ProfileScreen] Affichage section paramètres');
        return _buildSettingsSection();
      case 'legal':
        print('⚖️ [ProfileScreen] Affichage section légal');
        return _buildLegalSection();
      default:
        print('❓ [ProfileScreen] Section inconnue: $_activeSection');
        return const SizedBox.shrink();
    }
  }

  Widget _buildFavoritesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Mes Favoris',
              style: TextStyle(
                fontFamily: 'OpenSans',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3748),
              ),
            ),
            Row(
              children: [
                if (_userFavorites?.isNotEmpty == true) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE53E3E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_filteredFavorites.length}',
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                GestureDetector(
                  onTap: _navigateToFavorites,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE53E3E).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFE53E3E),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          'Voir tout',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFE53E3E),
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          LucideIcons.chevronRight,
                          size: 14,
                          color: Color(0xFFE53E3E),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Filter Tabs
        if (_userFavorites?.isNotEmpty == true) ...[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filterTabs.map((tab) {
                final isActive = _selectedFilter == tab['key'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedFilter = tab['key']),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isActive ? const Color(0xFFE53E3E) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isActive ? const Color(0xFFE53E3E) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            tab['icon'],
                            size: 16,
                            color: isActive ? Colors.white : const Color(0xFF4A5568),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            tab['label'],
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isActive ? Colors.white : const Color(0xFF4A5568),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
        ],

        
        // Favorites List
        if (_filteredFavorites.isNotEmpty)
          _buildFavoritesList()
        else
          _buildEmptyFavorites(),
      ],
    );
  }

  Widget _buildFavoritesList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredFavorites.length,
      itemBuilder: (context, index) {
        final favorite = _filteredFavorites[index];
        return _buildFavoriteItem(favorite);
      },
    );
  }

  Widget _buildFavoriteItem(Map<String, dynamic> favorite) {
    final content = favorite['content'] ?? {};
    final type = favorite['type'];
    
    return GestureDetector(
      onTap: () => _navigateToContent(type, content['id']?.toString() ?? ''),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
        children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            ),
            child: Container(
              width: 80,
              height: 80,
              child: Image.network(
                content['image'] ?? _getDefaultImage(type),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: const Color(0xFFF4D03F),
                    child: Icon(
                      _getTypeIcon(type),
                      color: const Color(0xFF2D3748),
                    ),
                  );
                },
              ),
            ),
          ),
          
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    content['title'] ?? 'Sans titre',
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
                  Text(
                    _getShortDescription(content['description']),
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 14,
                      color: Color(0xFF4A5568),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Ajouté ${_formatDate(favorite['favorited_at'])}',
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 12,
                          color: Color(0xFF718096),
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Remove button
          IconButton(
            onPressed: () => _removeFavorite(favorite),
            icon: const Icon(
              LucideIcons.x,
              size: 16,
              color: Color(0xFF718096),
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildEmptyFavorites() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              LucideIcons.heart,
              size: 64,
              color: const Color(0xFFCBD5E0),
            ),
            const SizedBox(height: 16),
            Text(
              _getEmptyMessage(),
              style: const TextStyle(
                fontFamily: 'OpenSans',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getEmptyDescription(),
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
                // Naviguer vers la page d'accueil
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53E3E),
                foregroundColor: Colors.white,
              ),
              child: const Text('Découvrir du contenu'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionsSection() {
    print('🎲 [ProfileScreen] _buildPredictionsSection appelé');
    print('   - _predictionsLoading: $_predictionsLoading');
    print('   - _predictionsStats: $_predictionsStats');
    print('   - _predictionsStats != null: ${_predictionsStats != null}');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mes Pronostics',
          style: TextStyle(
            fontFamily: 'OpenSans',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 16),

        if (_predictionsLoading)
          const Center(
            child: Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Chargement de vos statistiques...'),
              ],
            ),
          )
        else if (_predictionsStats != null)
          _buildPredictionsDashboard()
        else
          _buildEmptyPredictions(),
      ],
    );
  }

  Widget _buildPredictionsDashboard() {
    return Column(
      children: [
        // Stats Grid
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard(
              'Total prédictions',
              '${_predictionsStats!['total_predictions'] ?? 0}',
              LucideIcons.target,
              const Color(0xFFE53E3E),
            ),
            _buildStatCard(
              'Points gagnés',
              '${_predictionsStats!['total_points'] ?? 0}',
              LucideIcons.trophy,
              const Color(0xFFF4D03F),
            ),
            _buildStatCard(
              'Précision',
              '${_predictionsStats!['accuracy_percentage'] ?? 0}%',
              LucideIcons.target,
              const Color(0xFF38A169),
            ),
            if (_predictionsStats!['current_rank'] != null)
              _buildStatCard(
                'Classement',
                '#${_predictionsStats!['current_rank']}',
                LucideIcons.activity,
                const Color(0xFF9B59B6),
              ),
          ],
        ),
        const SizedBox(height: 24),

        // Quick Actions
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushNamed('/predictions');
                },
                icon: const Icon(LucideIcons.plus),
                label: const Text('Faire un pronostic'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53E3E),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  _showLeaderboardModal();
                },
                icon: const Icon(LucideIcons.activity),
                label: const Text('Classements'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFE53E3E),
                  side: const BorderSide(color: Color(0xFFE53E3E)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Section Tournois
        _buildTournamentsSection(),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'OpenSans',
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 12,
              color: Color(0xFF4A5568),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPredictions() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              LucideIcons.target,
              size: 64,
              color: const Color(0xFFCBD5E0),
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucun pronostic',
              style: TextStyle(
                fontFamily: 'OpenSans',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Commencez à faire des pronostics pour voir vos statistiques',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 14,
                color: Color(0xFF4A5568),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Naviguer vers les pronostics
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53E3E),
                foregroundColor: Colors.white,
              ),
              child: const Text('Faire un pronostic'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Paramètres',
          style: TextStyle(
            fontFamily: 'OpenSans',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 16),

        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Afficher l'option de création de contenu seulement pour les professionnels
              if (AuthService().canCreateProfessionalContent)
                _buildSettingsItem(
                  icon: LucideIcons.plus,
                  title: 'Créer du contenu professionnel',
                  subtitle: 'Soumettre des recettes et astuces',
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'PRO',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ProfessionalContentCreationScreen(),
                      ),
                    );
                  },
                ),
              
              // Afficher une information pour les utilisateurs non-professionnels
              if (!AuthService().canCreateProfessionalContent)
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade600),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Devenir professionnel',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Contactez un administrateur pour obtenir le statut professionnel et pouvoir créer du contenu.\nRôle actuel: ${AuthService().userRole}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              
              _buildSettingsItem(
                icon: LucideIcons.bell,
                title: 'Notifications',
                subtitle: 'Gérer les notifications',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const NotificationsScreen(),
                    ),
                  );
                },
              ),
              _buildSettingsItem(
                icon: LucideIcons.logOut,
                title: 'Se déconnecter',
                subtitle: 'Déconnecter votre compte',
                onTap: _logout,
                isDestructive: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? const Color(0xFFE53E3E) : const Color(0xFF4A5568),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'OpenSans',
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isDestructive ? const Color(0xFFE53E3E) : const Color(0xFF2D3748),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 14,
          color: Color(0xFF4A5568),
        ),
      ),
      trailing: trailing ?? const Icon(
        LucideIcons.chevronRight,
        size: 20,
        color: Color(0xFFCBD5E0),
      ),
      onTap: onTap,
    );
  }

  // Helper methods
  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String _getShortDescription(String? description) {
    if (description == null || description.isEmpty) return 'Aucune description';
    return description.length > 100 
        ? '${description.substring(0, 100)}...'
        : description;
  }

  String _getDefaultImage(String type) {
    switch (type) {
      case 'recipe':
        return 'https://new.dinorapp.com/images/default-recipe.jpg';
      case 'tip':
        return 'https://new.dinorapp.com/images/default-tip.jpg';
      case 'event':
        return 'https://new.dinorapp.com/images/default-event.jpg';
      case 'dinor_tv':
        return 'https://new.dinorapp.com/images/default-video.jpg';
      default:
        return 'https://new.dinorapp.com/images/default-content.jpg';
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'recipe':
        return LucideIcons.utensils;
      case 'tip':
        return LucideIcons.lightbulb;
      case 'event':
        return LucideIcons.calendar;
      case 'dinor_tv':
        return LucideIcons.play;
      default:
        return LucideIcons.file;
    }
  }

  String _getEmptyMessage() {
    switch (_selectedFilter) {
      case 'recipes':
        return 'Aucune recette favorite';
      case 'tips':
        return 'Aucune astuce favorite';
      case 'events':
        return 'Aucun événement favori';
      case 'videos':
        return 'Aucune vidéo favorite';
      default:
        return 'Aucun favori';
    }
  }

  String _getEmptyDescription() {
    switch (_selectedFilter) {
      case 'recipes':
        return 'Ajoutez des recettes à vos favoris pour les retrouver facilement';
      case 'tips':
        return 'Ajoutez des astuces à vos favoris pour les retrouver facilement';
      case 'events':
        return 'Ajoutez des événements à vos favoris pour les retrouver facilement';
      case 'videos':
        return 'Ajoutez des vidéos à vos favoris pour les retrouver facilement';
      default:
        return 'Ajoutez du contenu à vos favoris pour le retrouver facilement';
    }
  }

  Future<void> _removeFavorite(Map<String, dynamic> favorite) async {
    try {
      final favoritesService = ref.read(favoritesServiceProvider.notifier);
      final success = await favoritesService.removeFavorite(favorite['id']?.toString() ?? '');
      
      if (success) {
        setState(() {
          _userFavorites?.removeWhere((f) => f['id'] == favorite['id']);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Favori supprimé'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la suppression'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ [ProfileScreen] Erreur suppression favori: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString().contains('401') ? 'Authentification requise' : 'Erreur lors de la suppression'}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _logout() async {
    try {
      await ref.read(useAuthHandlerProvider.notifier).logout();
      setState(() {
        _userProfile = null;
        _userFavorites = [];
        _predictionsStats = null;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Déconnexion réussie'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('❌ [ProfileScreen] Erreur déconnexion: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de la déconnexion'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateToFavorites() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const FavoritesScreen(),
      ),
    );
  }

  void _navigateToContent(String type, String contentId) {
    switch (type) {
      case 'recipe':
        NavigationService.pushNamed('/recipe-detail-unified/$contentId');
        break;
      case 'tip':
        NavigationService.pushNamed('/tip-detail-unified/$contentId');
        break;
      case 'event':
        NavigationService.pushNamed('/event-detail-unified/$contentId');
        break;
      default:
        print('Navigation non supportée pour le type: $type');
    }
  }

  Widget _buildAccountSection() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mon Compte',
            style: TextStyle(
              fontFamily: 'OpenSans',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 16),
          
          // Informations utilisateur
          _buildInfoRow('Nom', _userProfile?['name'] ?? ref.watch(useAuthHandlerProvider).userName ?? 'Non défini'),
          _buildInfoRow('Email', _userProfile?['email'] ?? ref.watch(useAuthHandlerProvider).userEmail ?? 'Non défini'),
          if (_userProfile?['created_at'] != null)
            _buildInfoRow('Membre depuis', _formatDate(_userProfile!['created_at'])),
        ],
      ),
    );
  }

  Widget _buildSecuritySection() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sécurité',
            style: TextStyle(
              fontFamily: 'OpenSans',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 16),
          
          // Bouton changer mot de passe
          ElevatedButton.icon(
            onPressed: _showChangePasswordDialog,
            icon: const Icon(LucideIcons.lock),
            label: const Text('Changer le mot de passe'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53E3E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Bouton déconnexion
          OutlinedButton.icon(
            onPressed: _handleLogout,
            icon: const Icon(LucideIcons.logOut),
            label: const Text('Se déconnecter'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFE53E3E),
              side: const BorderSide(color: Color(0xFFE53E3E)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalSection() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Légal & Confidentialité',
            style: TextStyle(
              fontFamily: 'OpenSans',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 16),
          
          // Legal links
          _buildLegalLink(
            icon: LucideIcons.fileText,
            title: 'Conditions générales d\'utilisation',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const TermsOfServiceScreen()),
            ),
          ),
          _buildLegalLink(
            icon: LucideIcons.shield,
            title: 'Politique de confidentialité',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
            ),
          ),
          _buildLegalLink(
            icon: LucideIcons.cookie,
            title: 'Politique des cookies',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const CookiePolicyScreen()),
            ),
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildLegalLink({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            icon,
            color: const Color(0xFFE53E3E),
            size: 20,
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2D3748),
            ),
          ),
          trailing: const Icon(
            LucideIcons.chevronRight,
            size: 16,
            color: Color(0xFFCBD5E0),
          ),
          onTap: onTap,
        ),
        if (!isLast)
          const Divider(
            height: 1,
            color: Color(0xFFE2E8F0),
          ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 14,
              color: Color(0xFF4A5568),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2D3748),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTournamentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Tournois Disponibles',
              style: TextStyle(
                fontFamily: 'OpenSans',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3748),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/predictions');
              },
              child: const Text('Voir tous'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        if (_tournamentsLoading)
          const Center(child: CircularProgressIndicator())
        else if (_tournaments.isEmpty)
          _buildEmptyTournaments()
        else
          _buildTournamentsList(),
      ],
    );
  }

  Widget _buildTournamentsList() {
    // Prendre les 3 derniers tournois
    final recentTournaments = _tournaments.take(3).toList();
    
    return Column(
      children: recentTournaments.map((tournament) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFE53E3E),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                LucideIcons.trophy,
                color: Color(0xFFE53E3E),
                size: 20,
              ),
            ),
            title: Text(
              tournament['name'] ?? 'Tournoi',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tournament['status_label'] ?? ''),
                Text('${tournament['participants_count'] ?? 0} participants'),
              ],
            ),
            trailing: ElevatedButton(
              onPressed: () {
                _showTournamentMatches(tournament);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53E3E),
                foregroundColor: Colors.white,
                minimumSize: const Size(80, 32),
              ),
              child: const Text('Jouer', style: TextStyle(fontSize: 12)),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyTournaments() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            LucideIcons.trophy,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucun tournoi disponible',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Les tournois apparaîtront ici une fois disponibles',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF718096),
            ),
          ),
        ],
      ),
    );
  }

  void _showTournamentMatches(Map<String, dynamic> tournament) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TournamentMatchesModal(
        tournament: tournament,
        onPredictionSubmitted: () {
          // Recharger les stats après avoir fait un pronostic
          _loadProfileData();
        },
      ),
    );
  }

  void _showLeaderboardModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LeaderboardModal(tournaments: _tournaments),
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => _ChangePasswordDialog(
        onPasswordChanged: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mot de passe mis à jour avec succès'),
              backgroundColor: Color(0xFF38A169),
            ),
          );
        },
      ),
    );
  }

  void _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _logout();
    }
  }
}

// Dialog pour changer le mot de passe
class _ChangePasswordDialog extends ConsumerStatefulWidget {
  final VoidCallback onPasswordChanged;

  const _ChangePasswordDialog({required this.onPasswordChanged});

  @override
  ConsumerState<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends ConsumerState<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
        newPasswordConfirmation: _confirmPasswordController.text,
      );

      if (response['success']) {
        Navigator.of(context).pop();
        widget.onPasswordChanged();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Erreur lors du changement de mot de passe'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Changer le mot de passe'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _currentPasswordController,
              decoration: const InputDecoration(
                labelText: 'Mot de passe actuel',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez saisir votre mot de passe actuel';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _newPasswordController,
              decoration: const InputDecoration(
                labelText: 'Nouveau mot de passe',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez saisir un nouveau mot de passe';
                }
                if (value.length < 8) {
                  return 'Le mot de passe doit contenir au moins 8 caractères';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPasswordController,
              decoration: const InputDecoration(
                labelText: 'Confirmer le nouveau mot de passe',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez confirmer le nouveau mot de passe';
                }
                if (value != _newPasswordController.text) {
                  return 'Les mots de passe ne correspondent pas';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _changePassword,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE53E3E),
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Changer'),
        ),
      ],
    );
  }
}