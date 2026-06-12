/**
 * NAVIGATION_SERVICE.DART - SERVICE DE NAVIGATION AVEC GLOBALKEY
 * 
 * Remplacement de GoRouter par Navigator classique pour éviter les erreurs
 * de contexte modal avec des GlobalKey pour un accès sûr.
 */

import 'package:flutter/material.dart';
import '../screens/working_home_screen.dart';
import '../screens/simple_recipes_screen.dart';
import '../screens/simple_tips_screen.dart';
import '../screens/simple_events_screen.dart';
import '../screens/enhanced_dinor_tv_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/pages_list_screen.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../screens/terms_of_service_screen.dart';
import '../screens/privacy_policy_screen.dart';
import '../screens/cookie_policy_screen.dart';
import '../screens/predictions_screen_simple.dart';
import '../screens/leaderboard_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/recipe_detail_screen_unified.dart';
import '../screens/tip_detail_screen_unified.dart';
import '../screens/event_detail_screen_unified.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static final RouteObserver<ModalRoute> routeObserver = RouteObserver<ModalRoute>();
  
  // Getter pour le contexte sûr
  static BuildContext? get context => navigatorKey.currentContext;
  
  // Routes définies
  static const String home = '/';
  static const String recipes = '/recipes';
  static const String recipeDetail = '/recipe-detail';
  static const String recipeDetailUnified = '/recipe-detail-unified';
  static const String tips = '/tips';
  static const String tipDetail = '/tip-detail';
  static const String tipDetailUnified = '/tip-detail-unified';
  static const String events = '/events';
  static const String eventDetail = '/event-detail';
  static const String eventDetailUnified = '/event-detail-unified';
  static const String dinorTv = '/dinor-tv';
  static const String profile = '/profile';
  static const String pages = '/pages';
  static const String terms = '/terms';
  static const String privacy = '/privacy';
  static const String cookies = '/cookies';
  static const String predictions = '/predictions';
  static const String leaderboard = '/leaderboard';
  static const String notifications = '/notifications';
  static const String webEmbed = '/web-embed';
  
  // Route actuelle
  static String _currentRoute = home;
  static String get currentRoute => _currentRoute;
  
  // Callbacks pour les changements de route
  static final List<Function(String)> _routeChangeListeners = [];
  
  static void addRouteChangeListener(Function(String) listener) {
    _routeChangeListeners.add(listener);
  }
  
  static void removeRouteChangeListener(Function(String) listener) {
    _routeChangeListeners.remove(listener);
  }
  
  static void _notifyRouteChange(String route) {
    print('🧭 [NavigationService] Route change: $_currentRoute -> $route');
    _currentRoute = route;
    for (var listener in _routeChangeListeners) {
      listener(route);
    }
  }
  
  // Méthodes de navigation
  static Future<T?> pushNamed<T extends Object?>(String routeName, {Object? arguments}) {
    print('🧭 [NavigationService] pushNamed appelé:');
    print('   - Route: $routeName');
    print('   - Arguments: $arguments');
    
    if (navigatorKey.currentState == null) {
      print('❌ [NavigationService] navigatorKey.currentState est null!');
      print('💡 [NavigationService] Vérifiez que MaterialApp utilise bien navigatorKey');
      throw Exception('NavigatorState non disponible. App non initialisée?');
    }
    
    try {
      _notifyRouteChange(routeName);
      final result = navigatorKey.currentState!.pushNamed<T>(routeName, arguments: arguments);
      print('✅ [NavigationService] Navigation lancée vers: $routeName');
      return result;
    } catch (e) {
      print('❌ [NavigationService] Erreur lors de pushNamed: $e');
      rethrow;
    }
  }
  
  static Future<T?> pushReplacementNamed<T extends Object?, TO extends Object?>(
    String routeName, {
    Object? arguments,
    TO? result,
  }) {
    _notifyRouteChange(routeName);
    return navigatorKey.currentState!.pushReplacementNamed<T, TO>(
      routeName,
      arguments: arguments,
      result: result,
    );
  }
  
  static void pop<T extends Object?>([T? result]) {
    navigatorKey.currentState!.pop<T>(result);
    // Note: Nous ne pouvons pas facilement déterminer la route précédente ici
  }
  
  static Future<T?> pushNamedAndClearStack<T extends Object?>(String routeName, {Object? arguments}) {
    _notifyRouteChange(routeName);
    return navigatorKey.currentState!.pushNamedAndRemoveUntil<T>(
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }
  
  static bool canPop() {
    return navigatorKey.currentState?.canPop() ?? false;
  }
  
  // Méthodes de navigation spécifiques
  static void goHome() {
    pushNamedAndClearStack(home);
  }
  
  static void goToRecipes() {
    pushNamed(recipes);
  }
  
  static void goToRecipeDetail(String id) {
    print('🧭 [NavigationService] goToRecipeDetail appelé avec ID: $id');
    if (id.isEmpty) {
      print('❌ [NavigationService] ID vide fourni pour la recette');
      return;
    }
    
    try {
      pushNamed(recipeDetail, arguments: {'id': id});
      print('✅ [NavigationService] Navigation vers recette initiée');
    } catch (e) {
      print('❌ [NavigationService] Erreur navigation recette: $e');
    }
  }
  
  static void goToTips() {
    pushNamed(tips);
  }
  
  static void goToTipDetail(String id) {
    print('🧭 [NavigationService] goToTipDetail appelé avec ID: $id');
    if (id.isEmpty) {
      print('❌ [NavigationService] ID vide fourni pour l\'astuce');
      return;
    }
    
    try {
      pushNamed(tipDetail, arguments: {'id': id});
      print('✅ [NavigationService] Navigation vers astuce initiée');
    } catch (e) {
      print('❌ [NavigationService] Erreur navigation astuce: $e');
    }
  }
  
  static void goToEvents() {
    pushNamed(events);
  }
  
  static void goToEventDetail(String id) {
    print('🧭 [NavigationService] goToEventDetail appelé avec ID: $id');
    if (id.isEmpty) {
      print('❌ [NavigationService] ID vide fourni pour l\'événement');
      return;
    }
    
    try {
      pushNamed(eventDetail, arguments: {'id': id});
      print('✅ [NavigationService] Navigation vers événement initiée');
    } catch (e) {
      print('❌ [NavigationService] Erreur navigation événement: $e');
    }
  }
  
  static void goToDinorTv() {
    print('🧭 [NavigationService] goToDinorTv appelé');
    try {
      pushNamed(dinorTv);
      print('✅ [NavigationService] Navigation vers Dinor TV initiée');
    } catch (e) {
      print('❌ [NavigationService] Erreur navigation Dinor TV: $e');
    }
  }
  
  static void goToProfile() {
    pushNamed(profile);
  }
  
  static void goToPages() {
    pushNamed(pages);
  }
  
  static void goToTerms() {
    pushNamed(terms);
  }
  
  static void goToPrivacy() {
    pushNamed(privacy);
  }
  
  static void goToCookies() {
    pushNamed(cookies);
  }
  
  static void goToPredictions() {
    pushNamed(predictions);
  }
  
  // Méthode générique navigateTo pour compatibilité
  static Future<T?> navigateTo<T extends Object?>(String routeName, {Object? arguments}) {
    return pushNamed<T>(routeName, arguments: arguments);
  }
  
  // Générateur de routes
  static Route<dynamic>? generateRoute(RouteSettings settings) {
    print('🧭 [NavigationService] Navigation vers: ${settings.name}');
    
    final path = settings.name;
    if (path == null) {
      return _errorRoute();
    }

    // Gestion des routes dynamiques avec ID
    if (path.startsWith('$recipeDetailUnified/')) {
      final id = _extractIdFromPath(path);
      if (id != null) {
        return MaterialPageRoute(
          builder: (_) => RecipeDetailScreenUnified(id: id),
          settings: settings,
        );
      }
    }

    if (path.startsWith('$tipDetailUnified/')) {
      final id = _extractIdFromPath(path);
      if (id != null) {
        return MaterialPageRoute(
          builder: (_) => TipDetailScreenUnified(id: id),
          settings: settings,
        );
      }
    }

    if (path.startsWith('$eventDetailUnified/')) {
      final id = _extractIdFromPath(path);
      if (id != null) {
        return MaterialPageRoute(
          builder: (_) => EventDetailScreenUnified(id: id),
          settings: settings,
        );
      }
    }

    // Gestion des routes statiques
    switch (settings.name) {
      case home:
        return MaterialPageRoute(
          builder: (_) => const WorkingHomeScreen(),
          settings: settings,
        );
        
      case recipes:
        return MaterialPageRoute(
          builder: (_) => const SimpleRecipesScreen(),
          settings: settings,
        );
        
      case recipeDetail:
        final arguments = settings.arguments as Map<String, dynamic>?;
        if (arguments == null || arguments['id'] == null) return _errorRoute();
        return MaterialPageRoute(
          builder: (_) => RecipeDetailScreenUnified(id: arguments['id']),
          settings: settings,
        );
        
      case tips:
        return MaterialPageRoute(
          builder: (_) => const SimpleTipsScreen(),
          settings: settings,
        );
        
      case tipDetail:
        final arguments = settings.arguments as Map<String, dynamic>?;
        if (arguments == null || arguments['id'] == null) return _errorRoute();
        return MaterialPageRoute(
          builder: (_) => TipDetailScreenUnified(id: arguments['id']),
          settings: settings,
        );
        
      case events:
        return MaterialPageRoute(
          builder: (_) => const SimpleEventsScreen(),
          settings: settings,
        );
        
      case eventDetail:
        final arguments = settings.arguments as Map<String, dynamic>?;
        if (arguments == null || arguments['id'] == null) return _errorRoute();
        return MaterialPageRoute(
          builder: (_) => EventDetailScreenUnified(id: arguments['id']),
          settings: settings,
        );
        
      case dinorTv:
        return MaterialPageRoute(
          builder: (_) => const EnhancedDinorTVScreen(),
          settings: settings,
        );
        
      case profile:
        return MaterialPageRoute(
          builder: (_) => const ProfileScreen(),
          settings: settings,
        );
        
      case notifications:
        return MaterialPageRoute(
          builder: (_) => const NotificationsScreen(),
          settings: settings,
        );
        
      case pages:
        return MaterialPageRoute(
          builder: (_) => const PagesListScreen(),
          settings: settings,
        );
        
      case webEmbed:
        final arguments = settings.arguments as Map<String, dynamic>?;
        final url = arguments != null ? arguments['url'] as String? : null;
        final title = arguments != null ? arguments['title'] as String? : null;
        if (url == null) return _errorRoute();
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(
              title: Text(title ?? 'Page'),
              backgroundColor: const Color(0xFFF4D03F),
              foregroundColor: Colors.black,
            ),
            body: InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(url)),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                useHybridComposition: true,
                allowFileAccess: true,
                allowContentAccess: true,
              ),
              onPermissionRequest: (controller, request) async {
                return PermissionResponse(
                  resources: request.resources,
                  action: PermissionResponseAction.GRANT,
                );
              },
            ),
          ),
          settings: settings,
        );
        
      case terms:
        return MaterialPageRoute(
          builder: (_) => const TermsOfServiceScreen(),
          settings: settings,
        );
        
      case privacy:
        return MaterialPageRoute(
          builder: (_) => const PrivacyPolicyScreen(),
          settings: settings,
        );
        
      case cookies:
        return MaterialPageRoute(
          builder: (_) => const CookiePolicyScreen(),
          settings: settings,
        );
        
      case predictions:
        return MaterialPageRoute(
          builder: (_) => const PredictionsScreen(),
          settings: settings,
        );
        
      case leaderboard:
        return MaterialPageRoute(
          builder: (_) => const LeaderboardScreen(),
          settings: settings,
        );
        
      default:
        return _errorRoute();
    }
  }
  
  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        backgroundColor: const Color(0xFFFFFFFF),
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
                '404 - Page non trouvée',
                style: TextStyle(
                  fontFamily: 'OpenSans',
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'La page que vous recherchez n\'existe pas.',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 16,
                  color: Color(0xFF4A5568),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => goHome(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53E3E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text(
                  'Retour à l\'accueil',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Fonction helper pour extraire l'ID d'un chemin de route
  static String? _extractIdFromPath(String path) {
    final segments = path.split('/');
    if (segments.length >= 3 && segments.last.isNotEmpty) {
      return segments.last;
    }
    return null;
  }
}