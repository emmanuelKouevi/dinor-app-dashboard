/**
 * SWIPEABLE_NAVIGATION_SERVICE.DART - SERVICE DE NAVIGATION SWIPEABLE
 * 
 * FONCTIONNALITÉS :
 * - Navigation vers les écrans swipeable
 * - Gestion des types de contenu
 * - Préchargement des données
 * - Analytics tracking
 */

import 'package:flutter/material.dart';
import '../screens/swipeable_detail_screen.dart';
import 'analytics_service.dart';
import 'analytics_tracker.dart';

class SwipeableNavigationService {
  // Types de contenu supportés
  static const Map<String, ContentType> _contentTypeMap = {
    'recipe': ContentType.recipe,
    'tip': ContentType.tip,
    'event': ContentType.event,
    'video': ContentType.video,
  };

  // Naviguer vers un écran swipeable avec un seul item
  static Future<void> navigateToDetail({
    required BuildContext context,
    required String id,
    required String contentType,
    Map<String, dynamic>? item,
  }) async {
    final type = _contentTypeMap[contentType] ?? ContentType.recipe;
    
    // Analytics: navigation vers détail
    AnalyticsTracker.trackNavigation(
      fromScreen: 'current_screen',
      toScreen: 'swipeable_detail_$contentType',
      method: 'button',
    );
    
    AnalyticsService.logViewContent(
      contentType: contentType,
      contentId: id,
      contentName: item?['title'] ?? 'Contenu',
    );
    
    // Navigation
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SwipeableDetailScreen(
          initialId: id,
          initialType: type,
          items: item != null ? [item] : null,
        ),
      ),
    );
  }

  // Naviguer vers un écran swipeable avec une liste d'items
  static Future<void> navigateToSwipeableList({
    required BuildContext context,
    required String initialId,
    required String contentType,
    required List<Map<String, dynamic>> items,
  }) async {
    final type = _contentTypeMap[contentType] ?? ContentType.recipe;
    
    // Analytics: navigation vers liste swipeable
    AnalyticsTracker.trackNavigation(
      fromScreen: 'current_screen',
      toScreen: 'swipeable_detail_$contentType',
      method: 'swipe_list',
    );
    
    AnalyticsService.logFeatureUsage(
      featureName: 'swipeable_navigation',
      category: 'navigation',
      additionalData: {
        'content_type': contentType,
        'total_items': items.length,
        'initial_id': initialId,
      },
    );
    
    // Navigation
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SwipeableDetailScreen(
          initialId: initialId,
          initialType: type,
          items: items,
        ),
      ),
    );
  }

  // Naviguer vers un écran swipeable avec chargement automatique
  static Future<void> navigateToSwipeableAuto({
    required BuildContext context,
    required String initialId,
    required String contentType,
  }) async {
    final type = _contentTypeMap[contentType] ?? ContentType.recipe;
    
    // Analytics: navigation vers swipeable auto
    AnalyticsTracker.trackNavigation(
      fromScreen: 'current_screen',
      toScreen: 'swipeable_detail_$contentType',
      method: 'auto_load',
    );
    
    // Navigation
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SwipeableDetailScreen(
          initialId: initialId,
          initialType: type,
        ),
      ),
    );
  }

  // Naviguer depuis un écran de liste vers le swipeable
  static Future<void> navigateFromList({
    required BuildContext context,
    required String initialId,
    required String contentType,
    required List<Map<String, dynamic>> items,
    int? initialIndex,
  }) async {
    final type = _contentTypeMap[contentType] ?? ContentType.recipe;
    
    // Trouver l'index initial si fourni
    int index = 0;
    if (initialIndex != null && initialIndex < items.length) {
      index = initialIndex;
    } else {
      // Trouver l'index de l'item initial
      for (int i = 0; i < items.length; i++) {
        if (items[i]['id'].toString() == initialId) {
          index = i;
          break;
        }
      }
    }
    
    // Analytics: navigation depuis liste
    AnalyticsTracker.trackNavigation(
      fromScreen: 'list_screen',
      toScreen: 'swipeable_detail_$contentType',
      method: 'list_item',
    );
    
    AnalyticsService.logViewContent(
      contentType: contentType,
      contentId: initialId,
      contentName: items[index]['title'] ?? 'Contenu',
      additionalParams: {
        'list_index': index,
        'total_items': items.length,
      },
    );
    
    // Navigation
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SwipeableDetailScreen(
          initialId: initialId,
          initialType: type,
          items: items,
        ),
      ),
    );
  }

  // Naviguer depuis un carousel vers le swipeable
  static Future<void> navigateFromCarousel({
    required BuildContext context,
    required String initialId,
    required String contentType,
    required List<Map<String, dynamic>> carouselItems,
    required int carouselIndex,
  }) async {
    final type = _contentTypeMap[contentType] ?? ContentType.recipe;
    
    // Analytics: navigation depuis carousel
    AnalyticsTracker.trackNavigation(
      fromScreen: 'carousel_screen',
      toScreen: 'swipeable_detail_$contentType',
      method: 'carousel_item',
    );
    
    AnalyticsService.logViewContent(
      contentType: contentType,
      contentId: initialId,
      contentName: carouselItems[carouselIndex]['title'] ?? 'Contenu',
      additionalParams: {
        'carousel_index': carouselIndex,
        'carousel_total': carouselItems.length,
      },
    );
    
    // Navigation
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SwipeableDetailScreen(
          initialId: initialId,
          initialType: type,
          items: carouselItems,
        ),
      ),
    );
  }

  // Naviguer depuis un écran de recherche
  static Future<void> navigateFromSearch({
    required BuildContext context,
    required String initialId,
    required String contentType,
    required List<Map<String, dynamic>> searchResults,
    required String searchTerm,
  }) async {
    final type = _contentTypeMap[contentType] ?? ContentType.recipe;
    
    // Analytics: navigation depuis recherche
    AnalyticsTracker.trackNavigation(
      fromScreen: 'search_screen',
      toScreen: 'swipeable_detail_$contentType',
      method: 'search_result',
    );
    
    AnalyticsService.logViewContent(
      contentType: contentType,
      contentId: initialId,
      contentName: searchResults.firstWhere(
        (item) => item['id'].toString() == initialId,
        orElse: () => {'title': 'Contenu'},
      )['title'] ?? 'Contenu',
      additionalParams: {
        'search_term': searchTerm,
        'search_results_count': searchResults.length,
      },
    );
    
    // Navigation
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SwipeableDetailScreen(
          initialId: initialId,
          initialType: type,
          items: searchResults,
        ),
      ),
    );
  }

  // Naviguer depuis les favoris
  static Future<void> navigateFromFavorites({
    required BuildContext context,
    required String initialId,
    required String contentType,
    required List<Map<String, dynamic>> favoriteItems,
  }) async {
    final type = _contentTypeMap[contentType] ?? ContentType.recipe;
    
    // Analytics: navigation depuis favoris
    AnalyticsTracker.trackNavigation(
      fromScreen: 'favorites_screen',
      toScreen: 'swipeable_detail_$contentType',
      method: 'favorite_item',
    );
    
    AnalyticsService.logViewContent(
      contentType: contentType,
      contentId: initialId,
      contentName: favoriteItems.firstWhere(
        (item) => item['id'].toString() == initialId,
        orElse: () => {'title': 'Contenu'},
      )['title'] ?? 'Contenu',
      additionalParams: {
        'favorites_count': favoriteItems.length,
      },
    );
    
    // Navigation
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SwipeableDetailScreen(
          initialId: initialId,
          initialType: type,
          items: favoriteItems,
        ),
      ),
    );
  }

  // Obtenir le type de contenu depuis une chaîne
  static ContentType getContentType(String contentType) {
    return _contentTypeMap[contentType] ?? ContentType.recipe;
  }

  // Obtenir le nom du type de contenu
  static String getContentTypeName(ContentType type) {
    switch (type) {
      case ContentType.recipe:
        return 'recette';
      case ContentType.tip:
        return 'astuce';
      case ContentType.event:
        return 'événement';
      case ContentType.video:
        return 'vidéo';
    }
  }

  // Vérifier si un type de contenu est supporté
  static bool isContentTypeSupported(String contentType) {
    return _contentTypeMap.containsKey(contentType);
  }

  // Obtenir tous les types de contenu supportés
  static List<String> getSupportedContentTypes() {
    return _contentTypeMap.keys.toList();
  }
} 