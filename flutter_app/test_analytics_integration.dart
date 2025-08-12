/**
 * TEST_ANALYTICS_INTEGRATION.DART - SCRIPT DE TEST FIREBASE ANALYTICS
 * 
 * Ce script permet de tester l'intégration Firebase Analytics
 * et de vérifier que tous les événements sont correctement trackés.
 */

import 'package:dinor_app/services/analytics_service.dart';
import 'package:dinor_app/services/analytics_tracker.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

class TestAnalyticsApp extends StatelessWidget {
  const TestAnalyticsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test Firebase Analytics',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const TestAnalyticsScreen(),
    );
  }
}

class TestAnalyticsScreen extends StatefulWidget {
  const TestAnalyticsScreen({super.key});

  @override
  State<TestAnalyticsScreen> createState() => _TestAnalyticsScreenState();
}

class _TestAnalyticsScreenState extends State<TestAnalyticsScreen> with AnalyticsScreenMixin {
  @override
  String get screenName => 'test_analytics';

  @override
  void initState() {
    super.initState();
    print('🧪 [TestAnalytics] Écran de test initialisé');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Firebase Analytics'),
        backgroundColor: Colors.orange,
        toolbarHeight: 56,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSection(
              title: '📊 Événements d\'Application',
              children: [
                _buildTestButton(
                  'Test Installation',
                  () => _testAppInstall(),
                ),
                _buildTestButton(
                  'Test Première Ouverture',
                  () => _testFirstOpen(),
                ),
                _buildTestButton(
                  'Test Ouverture App',
                  () => _testAppOpen(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSection(
              title: '🧭 Événements de Navigation',
              children: [
                _buildTestButton(
                  'Test Visite Écran',
                  () => _testScreenView(),
                ),
                _buildTestButton(
                  'Test Navigation',
                  () => _testNavigation(),
                ),
                _buildTestButton(
                  'Test Temps Écran',
                  () => _testScreenTime(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSection(
              title: '👀 Événements de Contenu',
              children: [
                _buildTestButton(
                  'Test Consultation Recette',
                  () => _testViewContent('recipe'),
                ),
                _buildTestButton(
                  'Test Consultation Astuce',
                  () => _testViewContent('tip'),
                ),
                _buildTestButton(
                  'Test Recherche',
                  () => _testSearch(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSection(
              title: '🖱️ Événements d\'Interaction',
              children: [
                _buildTestButton(
                  'Test Clic Bouton',
                  () => _testButtonClick(),
                ),
                _buildTestButton(
                  'Test Like',
                  () => _testLikeAction(),
                ),
                _buildTestButton(
                  'Test Favoris',
                  () => _testFavoriteAction(),
                ),
                _buildTestButton(
                  'Test Partage',
                  () => _testShareContent(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSection(
              title: '🔐 Événements d\'Authentification',
              children: [
                _buildTestButton(
                  'Test Connexion',
                  () => _testLogin(),
                ),
                _buildTestButton(
                  'Test Inscription',
                  () => _testSignUp(),
                ),
                _buildTestButton(
                  'Test Déconnexion',
                  () => _testLogout(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSection(
              title: '📈 Métriques d\'Engagement',
              children: [
                _buildTestButton(
                  'Test Engagement Quotidien',
                  () => _testDailyEngagement(),
                ),
                _buildTestButton(
                  'Test Session Longue',
                  () => _testLongSession(),
                ),
                _buildTestButton(
                  'Test Utilisation Fonctionnalité',
                  () => _testFeatureUsage(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSection(
              title: '⚠️ Gestion d\'Erreurs',
              children: [
                _buildTestButton(
                  'Test Erreur Utilisateur',
                  () => _testUserError(),
                ),
                _buildTestButton(
                  'Test Performance',
                  () => _testPerformance(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSection(
              title: '🎯 Événements Personnalisés',
              children: [
                _buildTestButton(
                  'Test Événement Personnalisé',
                  () => _testCustomEvent(),
                ),
                _buildTestButton(
                  'Test Propriétés Utilisateur',
                  () => _testUserProperties(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTestButton(String label, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: ElevatedButton(
        onPressed: () {
          onPressed();
          _showSuccessMessage('Événement "$label" tracké avec succès !');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
        ),
        child: Text(label),
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // === TESTS DES ÉVÉNEMENTS ===

  Future<void> _testAppInstall() async {
    await AnalyticsService.logAppInstall();
    print('✅ [Test] Événement app_install tracké');
  }

  Future<void> _testFirstOpen() async {
    await AnalyticsService.logFirstOpen();
    print('✅ [Test] Événement first_open tracké');
  }

  Future<void> _testAppOpen() async {
    await AnalyticsService.logAppOpen();
    print('✅ [Test] Événement app_open tracké');
  }

  Future<void> _testScreenView() async {
    await AnalyticsService.logScreenView(
      screenName: 'test_screen',
      screenClass: 'TestScreen',
    );
    print('✅ [Test] Événement screen_view tracké');
  }

  Future<void> _testNavigation() async {
    await AnalyticsService.logNavigation(
      from: 'test_screen',
      to: 'home_screen',
      method: 'button',
    );
    print('✅ [Test] Événement navigation tracké');
  }

  Future<void> _testScreenTime() async {
    await AnalyticsService.logScreenTime(
      screenName: 'test_screen',
      durationSeconds: 120,
    );
    print('✅ [Test] Événement screen_time tracké');
  }

  Future<void> _testViewContent(String contentType) async {
    await AnalyticsService.logViewContent(
      contentType: contentType,
      contentId: 'test_123',
      contentName: 'Test $contentType',
    );
    print('✅ [Test] Événement view_content tracké pour $contentType');
  }

  Future<void> _testSearch() async {
    await AnalyticsService.logSearch(
      searchTerm: 'test search',
      category: 'recipes',
      resultsCount: 5,
    );
    print('✅ [Test] Événement search tracké');
  }

  Future<void> _testButtonClick() async {
    AnalyticsTracker.trackButtonClick(
      buttonName: 'test_button',
      screenName: 'test_analytics',
      additionalData: {
        'test_param': 'test_value',
      },
    );
    print('✅ [Test] Événement button_click tracké');
  }

  Future<void> _testLikeAction() async {
    await AnalyticsService.logLikeAction(
      contentType: 'recipe',
      contentId: 'test_recipe_123',
      isLiked: true,
    );
    print('✅ [Test] Événement like_content tracké');
  }

  Future<void> _testFavoriteAction() async {
    await AnalyticsService.logFavoriteAction(
      contentType: 'recipe',
      contentId: 'test_recipe_123',
      isFavorited: true,
    );
    print('✅ [Test] Événement add_to_favorites tracké');
  }

  Future<void> _testShareContent() async {
    await AnalyticsService.logShareContent(
      contentType: 'recipe',
      contentId: 'test_recipe_123',
      method: 'copy_link',
    );
    print('✅ [Test] Événement share tracké');
  }

  Future<void> _testLogin() async {
    await AnalyticsService.logLogin(method: 'email');
    print('✅ [Test] Événement login tracké');
  }

  Future<void> _testSignUp() async {
    await AnalyticsService.logSignUp(method: 'email');
    print('✅ [Test] Événement sign_up tracké');
  }

  Future<void> _testLogout() async {
    await AnalyticsService.logLogout();
    print('✅ [Test] Événement logout tracké');
  }

  Future<void> _testDailyEngagement() async {
    await AnalyticsService.logDailyEngagement();
    print('✅ [Test] Événement daily_engagement tracké');
  }

  Future<void> _testLongSession() async {
    await AnalyticsService.logLongSession(durationMinutes: 10);
    print('✅ [Test] Événement long_session tracké');
  }

  Future<void> _testFeatureUsage() async {
    await AnalyticsService.logFeatureUsage(
      featureName: 'test_feature',
      category: 'test_category',
      additionalData: {
        'test_param': 'test_value',
      },
    );
    print('✅ [Test] Événement feature_usage tracké');
  }

  Future<void> _testUserError() async {
    await AnalyticsService.logUserError(
      errorType: 'test_error',
      errorMessage: 'Test error message',
      screenName: 'test_analytics',
    );
    print('✅ [Test] Événement user_error tracké');
  }

  Future<void> _testPerformance() async {
    await AnalyticsService.logPerformance(
      actionName: 'test_action',
      durationMs: 500,
      category: 'test_category',
    );
    print('✅ [Test] Événement performance_timing tracké');
  }

  Future<void> _testCustomEvent() async {
    await AnalyticsService.logCustomEvent(
      eventName: 'test_custom_event',
      parameters: {
        'test_param': 'test_value',
        'test_number': 42,
      },
    );
    print('✅ [Test] Événement personnalisé tracké');
  }

  Future<void> _testUserProperties() async {
    await AnalyticsService.setUserId('test_user_123');
    await AnalyticsService.setUserProperty(
      name: 'test_property',
      value: 'test_value',
    );
    print('✅ [Test] Propriétés utilisateur définies');
  }
}

// Fonction principale pour tester l'intégration
Future<void> testAnalyticsIntegration() async {
  try {
    // Initialiser Firebase
    await Firebase.initializeApp();
    await AnalyticsService.initialize();
    
    print('✅ [TestAnalytics] Firebase Analytics initialisé avec succès');
    
    // Démarrer le tracking de session
    AnalyticsTracker.startSession();
    
    print('✅ [TestAnalytics] Session de test démarrée');
    print('🧪 [TestAnalytics] Prêt pour les tests d\'événements');
    
  } catch (e) {
    print('❌ [TestAnalytics] Erreur initialisation: $e');
  }
} 