/**
 * TEST_SWIPEABLE_NAVIGATION.DART - TEST DE LA NAVIGATION SWIPEABLE
 * 
 * Ce script permet de tester la navigation swipeable
 * et de vérifier que toutes les fonctionnalités fonctionnent correctement.
 */

import 'package:dinor_app/screens/swipeable_detail_screen.dart';
import 'package:dinor_app/services/analytics_service.dart';
import 'package:dinor_app/services/analytics_tracker.dart';
import 'package:dinor_app/services/swipeable_navigation_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

// Écrans et services


class TestSwipeableNavigationApp extends StatelessWidget {
  const TestSwipeableNavigationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test Navigation Swipeable',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const TestSwipeableNavigationScreen(),
    );
  }
}

class TestSwipeableNavigationScreen extends ConsumerStatefulWidget {
  const TestSwipeableNavigationScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<TestSwipeableNavigationScreen> createState() => _TestSwipeableNavigationScreenState();
}

class _TestSwipeableNavigationScreenState extends ConsumerState<TestSwipeableNavigationScreen> with AnalyticsScreenMixin {
  @override
  String get screenName => 'test_swipeable_navigation';

  // Données de test
  final List<Map<String, dynamic>> _testRecipes = [
    {
      'id': '1',
      'title': 'Poulet rôti aux herbes',
      'description': 'Un poulet rôti savoureux avec des herbes fraîches',
      'ingredients': ['Poulet', 'Herbes', 'Beurre'],
      'instructions': ['Préchauffer le four', 'Assaisonner le poulet'],
    },
    {
      'id': '2',
      'title': 'Salade César',
      'description': 'Une salade César classique et délicieuse',
      'ingredients': ['Laitue', 'Parmesan', 'Croûtons'],
      'instructions': ['Laver la laitue', 'Préparer la vinaigrette'],
    },
    {
      'id': '3',
      'title': 'Tiramisu',
      'description': 'Un tiramisu authentique italien',
      'ingredients': ['Mascarpone', 'Café', 'Biscuits'],
      'instructions': ['Préparer le café', 'Monter la crème'],
    },
  ];

  final List<Map<String, dynamic>> _testTips = [
    {
      'id': '1',
      'title': 'Comment couper un oignon sans pleurer',
      'description': 'Technique pour éviter les larmes',
      'difficulty_level': 'facile',
    },
    {
      'id': '2',
      'title': 'Conserver les herbes fraîches',
      'description': 'Méthodes de conservation',
      'difficulty_level': 'moyen',
    },
    {
      'id': '3',
      'title': 'Cuire le riz parfaitement',
      'description': 'Technique du riz parfait',
      'difficulty_level': 'facile',
    },
  ];

  final List<Map<String, dynamic>> _testEvents = [
    {
      'id': '1',
      'title': 'Atelier cuisine française',
      'description': 'Apprenez les bases de la cuisine française',
      'event_date': '2024-02-15',
    },
    {
      'id': '2',
      'title': 'Masterclass pâtisserie',
      'description': 'Perfectionnez vos techniques de pâtisserie',
      'event_date': '2024-02-20',
    },
    {
      'id': '3',
      'title': 'Dégustation de vins',
      'description': 'Découvrez les accords mets-vins',
      'event_date': '2024-02-25',
    },
  ];

  final List<Map<String, dynamic>> _testVideos = [
    {
      'id': '1',
      'title': 'Technique de découpe',
      'description': 'Maîtrisez les techniques de découpe',
      'video_url': 'https://www.youtube.com/watch?v=example1',
    },
    {
      'id': '2',
      'title': 'Préparation de la pâte',
      'description': 'Apprenez à faire une pâte parfaite',
      'video_url': 'https://www.youtube.com/watch?v=example2',
    },
    {
      'id': '3',
      'title': 'Platage artistique',
      'description': 'Créez des assiettes magnifiques',
      'video_url': 'https://www.youtube.com/watch?v=example3',
    },
  ];

  @override
  void initState() {
    super.initState();
    print('🧪 [TestSwipeable] Écran de test initialisé');
  }

  @override
  Widget build(BuildContext context) {
    //super.build(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Navigation Swipeable'),
        backgroundColor: Colors.orange,
        toolbarHeight: 56,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSection(
              title: '🍳 Test Recettes',
              children: [
                _buildTestButton(
                  'Test Navigation Recettes',
                  () => _testRecipeNavigation(),
                ),
                _buildTestButton(
                  'Test Swipeable Recettes',
                  () => _testSwipeableRecipes(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSection(
              title: '💡 Test Astuces',
              children: [
                _buildTestButton(
                  'Test Navigation Astuces',
                  () => _testTipNavigation(),
                ),
                _buildTestButton(
                  'Test Swipeable Astuces',
                  () => _testSwipeableTips(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSection(
              title: '📅 Test Événements',
              children: [
                _buildTestButton(
                  'Test Navigation Événements',
                  () => _testEventNavigation(),
                ),
                _buildTestButton(
                  'Test Swipeable Événements',
                  () => _testSwipeableEvents(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSection(
              title: '🎬 Test Vidéos',
              children: [
                _buildTestButton(
                  'Test Navigation Vidéos',
                  () => _testVideoNavigation(),
                ),
                _buildTestButton(
                  'Test Swipeable Vidéos',
                  () => _testSwipeableVideos(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSection(
              title: '🔧 Test Services',
              children: [
                _buildTestButton(
                  'Test Service Navigation',
                  () => _testNavigationService(),
                ),
                _buildTestButton(
                  'Test Types de Contenu',
                  () => _testContentTypes(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSection(
              title: '📊 Test Analytics',
              children: [
                _buildTestButton(
                  'Test Tracking Navigation',
                  () => _testAnalyticsTracking(),
                ),
                _buildTestButton(
                  'Test Événements Swipe',
                  () => _testSwipeEvents(),
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
          _showSuccessMessage('Test "$label" exécuté avec succès !');
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

  // === TESTS DE NAVIGATION ===

  void _testRecipeNavigation() {
    print('🧪 [Test] Test navigation recettes');
    
    SwipeableNavigationService.navigateFromCarousel(
      context: context,
      initialId: '1',
      contentType: 'recipe',
      carouselItems: _testRecipes,
      carouselIndex: 0,
    );
  }

  void _testTipNavigation() {
    print('🧪 [Test] Test navigation astuces');
    
    SwipeableNavigationService.navigateFromCarousel(
      context: context,
      initialId: '1',
      contentType: 'tip',
      carouselItems: _testTips,
      carouselIndex: 0,
    );
  }

  void _testEventNavigation() {
    print('🧪 [Test] Test navigation événements');
    
    SwipeableNavigationService.navigateFromCarousel(
      context: context,
      initialId: '1',
      contentType: 'event',
      carouselItems: _testEvents,
      carouselIndex: 0,
    );
  }

  void _testVideoNavigation() {
    print('🧪 [Test] Test navigation vidéos');
    
    SwipeableNavigationService.navigateFromCarousel(
      context: context,
      initialId: '1',
      contentType: 'video',
      carouselItems: _testVideos,
      carouselIndex: 0,
    );
  }

  // === TESTS SWIPEABLE ===

  void _testSwipeableRecipes() {
    print('🧪 [Test] Test swipeable recettes');
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SwipeableDetailScreen(
          initialId: '1',
          initialType: ContentType.recipe,
          items: _testRecipes,
        ),
      ),
    );
  }

  void _testSwipeableTips() {
    print('🧪 [Test] Test swipeable astuces');
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SwipeableDetailScreen(
          initialId: '1',
          initialType: ContentType.tip,
          items: _testTips,
        ),
      ),
    );
  }

  void _testSwipeableEvents() {
    print('🧪 [Test] Test swipeable événements');
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SwipeableDetailScreen(
          initialId: '1',
          initialType: ContentType.event,
          items: _testEvents,
        ),
      ),
    );
  }

  void _testSwipeableVideos() {
    print('🧪 [Test] Test swipeable vidéos');
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SwipeableDetailScreen(
          initialId: '1',
          initialType: ContentType.video,
          items: _testVideos,
        ),
      ),
    );
  }

  // === TESTS SERVICES ===

  void _testNavigationService() {
    print('🧪 [Test] Test service de navigation');
    
    // Test des types de contenu supportés
    final supportedTypes = SwipeableNavigationService.getSupportedContentTypes();
    print('✅ Types supportés: $supportedTypes');
    
    // Test de vérification de type
    final isRecipeSupported = SwipeableNavigationService.isContentTypeSupported('recipe');
    final isInvalidSupported = SwipeableNavigationService.isContentTypeSupported('invalid');
    print('✅ Recipe supporté: $isRecipeSupported');
    print('✅ Invalid supporté: $isInvalidSupported');
    
    // Test de conversion de type
    final recipeType = SwipeableNavigationService.getContentType('recipe');
    final recipeName = SwipeableNavigationService.getContentTypeName(recipeType);
    print('✅ Type recette: $recipeType');
    print('✅ Nom recette: $recipeName');
  }

  void _testContentTypes() {
    print('🧪 [Test] Test types de contenu');
    
    // Test de tous les types
    final types = [
      ContentType.recipe,
      ContentType.tip,
      ContentType.event,
      ContentType.video,
    ];
    
    for (final type in types) {
      final name = SwipeableNavigationService.getContentTypeName(type);
      print('✅ Type: $type -> Nom: $name');
    }
  }

  // === TESTS ANALYTICS ===

  void _testAnalyticsTracking() {
    print('🧪 [Test] Test tracking analytics');
    
    // Test de navigation
    AnalyticsTracker.trackNavigation(
      fromScreen: 'test_screen',
      toScreen: 'swipeable_detail_recipe',
      method: 'test',
    );
    
    // Test de consultation de contenu
    AnalyticsService.logViewContent(
      contentType: 'recipe',
      contentId: 'test_123',
      contentName: 'Test Recette',
      additionalParams: {
        'test_param': 'test_value',
      },
    );
    
    // Test d'utilisation de fonctionnalité
    AnalyticsService.logFeatureUsage(
      featureName: 'swipeable_navigation',
      category: 'test',
      additionalData: {
        'test_data': 'test_value',
      },
    );
    
    print('✅ Analytics tracking testé');
  }

  void _testSwipeEvents() {
    print('🧪 [Test] Test événements swipe');
    
    // Simuler des événements de swipe
    AnalyticsService.logCustomEvent(
      eventName: 'swipe_navigation',
      parameters: {
        'direction': 'left',
        'content_type': 'recipe',
        'from_index': 0,
        'to_index': 1,
      },
    );
    
    AnalyticsService.logCustomEvent(
      eventName: 'swipe_navigation',
      parameters: {
        'direction': 'right',
        'content_type': 'tip',
        'from_index': 2,
        'to_index': 1,
      },
    );
    
    print('✅ Événements swipe testés');
  }
}

// Fonction principale pour tester la navigation swipeable
Future<void> testSwipeableNavigation() async {
  try {
    print('🧪 [TestSwipeable] Démarrage des tests de navigation swipeable');
    
    // Test des types de contenu
    print('✅ Types de contenu supportés:');
    final supportedTypes = SwipeableNavigationService.getSupportedContentTypes();
    for (final type in supportedTypes) {
      print('  - $type');
    }
    
    // Test de conversion de types
    print('✅ Test de conversion de types:');
    final recipeType = SwipeableNavigationService.getContentType('recipe');
    final tipType = SwipeableNavigationService.getContentType('tip');
    print('  - recipe -> $recipeType');
    print('  - tip -> $tipType');
    
    // Test de noms de types
    print('✅ Test de noms de types:');
    final recipeName = SwipeableNavigationService.getContentTypeName(ContentType.recipe);
    final tipName = SwipeableNavigationService.getContentTypeName(ContentType.tip);
    print('  - recipe -> $recipeName');
    print('  - tip -> $tipName');
    
    print('✅ [TestSwipeable] Tests de navigation swipeable terminés');
    
  } catch (e) {
    print('❌ [TestSwipeable] Erreur lors des tests: $e');
  }
} 