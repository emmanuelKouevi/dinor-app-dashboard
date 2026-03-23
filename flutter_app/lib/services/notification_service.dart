import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'navigation_service.dart';
import 'analytics_service.dart';

class NotificationService {
  static const String _appId = "d98be3fd-e812-47ea-a075-bca9a16b4f6b";
  
  static Map<String, String>? _pendingContentNavigation;

  static Future<void> initialize() async {
    debugPrint('🔔 [NotificationService] Initialisation OneSignal...');
    
    // Vérifier si la plateforme supporte OneSignal
    if (!Platform.isAndroid && !Platform.isIOS) {
      debugPrint('⚠️ [NotificationService] OneSignal non supporté sur cette plateforme: ${Platform.operatingSystem}');
      return;
    }
    
    try {
      // Configuration OneSignal
      OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
      OneSignal.initialize(_appId);
      
      // Demande de permission
      await requestPermission();
      
      // Configuration des événements
      _setupEventListeners();
      
      // Attendre un peu pour que l'inscription se fasse
      await Future.delayed(Duration(seconds: 2));
      
      // Récupérer et afficher l'ID utilisateur
      final userId = OneSignal.User.getOnesignalId();
      debugPrint('🆔 [NotificationService] OneSignal User ID: $userId');
      
      // Vérifier l'état de la subscription
      final subscriptionId = OneSignal.User.pushSubscription.id;
      debugPrint('📱 [NotificationService] Subscription ID: $subscriptionId');
      final subscriptionOptedIn = OneSignal.User.pushSubscription.optedIn;
      debugPrint('📱 [NotificationService] Subscription OptedIn: $subscriptionOptedIn');
      
      if (userId == null || subscriptionId == null) {
        debugPrint('⚠️ [NotificationService] PROBLÈME: User ID ou Subscription ID manquant');
        debugPrint('⚠️ [NotificationService] Tentative de forcer l\'inscription...');
        
        // Forcer l'opt-in
        await OneSignal.User.pushSubscription.optIn();
        debugPrint('🔄 [NotificationService] Opt-in forcé, attente 2 secondes...');
        
        await Future.delayed(Duration(seconds: 2));
        final newUserId = OneSignal.User.getOnesignalId();
        final newSubscriptionId = OneSignal.User.pushSubscription.id;
        debugPrint('🆔 [NotificationService] Nouveau User ID: $newUserId');
        debugPrint('📱 [NotificationService] Nouveau Subscription ID: $newSubscriptionId');
      }
      
      // Vérifier s'il y a eu une notification qui a ouvert l'app
      await _checkLaunchNotification();
      
      debugPrint('✅ [NotificationService] OneSignal initialisé avec succès');
    } catch (e) {
      debugPrint('❌ [NotificationService] Erreur d\'initialisation: $e');
    }
  }
  
  /// Vérifie si l'app a été ouverte par une notification
  static Future<void> _checkLaunchNotification() async {
    try {
      debugPrint('🚀 [NotificationService] Vérification notification de lancement...');
      
      // Note: OneSignal SDK 5.x gère automatiquement les notifications de lancement
      // via le click listener, pas besoin de vérification manuelle
      debugPrint('✅ [NotificationService] Vérification terminée');
    } catch (e) {
      debugPrint('❌ [NotificationService] Erreur vérification lancement: $e');
    }
  }
  
  static Future<void> requestPermission() async {
    try {
      debugPrint('📱 [NotificationService] Demande de permission...');
      
      final permission = await OneSignal.Notifications.requestPermission(true);
      debugPrint('📱 [NotificationService] Permission accordée: $permission');
    } catch (e) {
      debugPrint('❌ [NotificationService] Erreur permission: $e');
    }
  }
  
  static void _setupEventListeners() {
    try {
      // Notification reçue en foreground
      OneSignal.Notifications.addForegroundWillDisplayListener((event) {
        debugPrint('🔔 [NotificationService] ========== NOTIFICATION FOREGROUND ==========');
        debugPrint('🔔 [NotificationService] Titre: ${event.notification.title}');
        debugPrint('🔔 [NotificationService] Message: ${event.notification.body}');
        debugPrint('🔔 [NotificationService] Données: ${event.notification.additionalData}');
        
        // TOUJOURS afficher la notification en bannière, même en foreground
        // Ne pas appeler event.preventDefault() pour permettre l'affichage système
        debugPrint('📱 [NotificationService] Affichage de la notification en bannière système');
        debugPrint('🔔 [NotificationService] ===============================================');
        
        // La notification sera automatiquement affichée en bannière
        // car on ne prévient pas son affichage par défaut
      });
      
      // Notification cliquée (app ouverte ou en foreground)
      OneSignal.Notifications.addClickListener((event) {
        debugPrint('👆 [NotificationService] ========== NOTIFICATION CLIQUÉE ==========');
        debugPrint('👆 [NotificationService] Titre: ${event.notification.title}');
        debugPrint('👆 [NotificationService] Message: ${event.notification.body}');
        debugPrint('👆 [NotificationService] =======================================');
        
        // Attendre un petit délai pour s'assurer que l'app est prête
        Future.delayed(Duration(milliseconds: 500), () {
          _handleNotificationClick(event);
        });
      });
      
      // Changement de l'ID utilisateur
      OneSignal.User.pushSubscription.addObserver((state) {
        debugPrint('👤 [NotificationService] Subscription changée');
        if (state.current.id != null) {
          debugPrint('👤 [NotificationService] Subscription ID: ${state.current.id}');
        }
      });
      
      debugPrint('✅ [NotificationService] Event listeners configurés');
    } catch (e) {
      debugPrint('❌ [NotificationService] Erreur configuration listeners: $e');
    }
  }
  
  /// Gère le clic sur une notification
  static void _handleNotificationClick(OSNotificationClickEvent event) {
    debugPrint('🎯 [NotificationService] ========== TRAITEMENT CLIC ==========');
    
    // Gérer les données de navigation
    final data = event.notification.additionalData;
    debugPrint('📱 [NotificationService] Données notification: $data');
    debugPrint('📱 [NotificationService] Launch URL: ${event.notification.launchUrl}');
    
    // Variable pour tracker si on a navigué
    bool hasNavigated = false;

    _trackNotificationOpen(event);
    
    if (data != null) {
      debugPrint('🔍 [NotificationService] Données détaillées:');
      data.forEach((key, value) {
        debugPrint('🔍 [NotificationService]   $key: $value (${value.runtimeType})');
      });
      
      // Priorité aux données personnalisées (deep link)
      if (data.containsKey('deep_link')) {
        debugPrint('🚀 [NotificationService] Navigation via deep_link: ${data['deep_link']}');
        _handleNotificationUrl(data['deep_link']);
        hasNavigated = true;
      } else if (data.containsKey('content_type') && data.containsKey('content_id')) {
        debugPrint('🚀 [NotificationService] Navigation via content_type/content_id: ${data['content_type']}/${data['content_id']}');
        // Navigation directe via les données
        _handleContentNavigation(data['content_type'], data['content_id'].toString());
        hasNavigated = true;
      } else if (data.containsKey('url')) {
        debugPrint('🚀 [NotificationService] Navigation via URL: ${data['url']}');
        // URL classique en fallback
        _handleNotificationUrl(data['url']);
        hasNavigated = true;
      }
    } else {
      debugPrint('⚠️ [NotificationService] Aucune donnée dans la notification');
    }
    
    // Fallback : URL de la notification elle-même
    if (!hasNavigated && event.notification.launchUrl != null && event.notification.launchUrl!.isNotEmpty) {
      debugPrint('🚀 [NotificationService] Navigation fallback via launchUrl: ${event.notification.launchUrl}');
      _handleNotificationUrl(event.notification.launchUrl!);
      hasNavigated = true;
    }
    
    if (!hasNavigated) {
      debugPrint('❌ [NotificationService] AUCUNE NAVIGATION EFFECTUÉE - Pas de données de navigation trouvées');
      debugPrint('❌ [NotificationService] Données reçues: $data');
      debugPrint('❌ [NotificationService] Launch URL: ${event.notification.launchUrl}');
    } else {
      debugPrint('✅ [NotificationService] Navigation effectuée avec succès');
    }
    
    debugPrint('🎯 [NotificationService] ======================================');
  }
  
  static void _handleNotificationUrl(String url) {
    debugPrint('🔗 [NotificationService] Redirection vers: $url');
    
    try {
      // Vérifier si c'est un deep link de l'app
      if (url.startsWith('dinor://')) {
        _handleDeepLink(url);
      } else {
        // URL web classique - ouvrir dans le navigateur
        debugPrint('🌐 [NotificationService] Ouverture URL web: $url');
        _launchWebUrl(url);
      }
    } catch (e) {
      debugPrint('❌ [NotificationService] Erreur navigation: $e');
    }
  }
  
  static void _handleDeepLink(String deepLink) {
    debugPrint('🔗 [NotificationService] Traitement deep link: $deepLink');
    
    // Parser le deep link : dinor://recipe/123
    final uri = Uri.parse(deepLink);
    final pathSegments = uri.pathSegments;
    
    if (pathSegments.isEmpty) {
      debugPrint('❌ [NotificationService] Deep link invalide: $deepLink');
      return;
    }
    
    String? contentType;
    String? contentId;

    if (uri.host.isNotEmpty) {
      contentType = uri.host;
      contentId = pathSegments.isNotEmpty ? pathSegments[0] : null;
    } else {
      contentType = pathSegments[0];
      contentId = pathSegments.length > 1 ? pathSegments[1] : null;
    }
    
    if (contentId == null) {
      debugPrint('❌ [NotificationService] ID manquant dans deep link: $deepLink');
      return;
    }
    
    _handleContentNavigation(contentType ?? '', contentId);
  }
  
  static void _handleContentNavigation(String contentType, String contentId) {
    debugPrint('📱 [NotificationService] ========== NAVIGATION CONTENT ==========');
    debugPrint('📱 [NotificationService] Type: $contentType');
    debugPrint('📱 [NotificationService] ID: $contentId');
    
    // Vérifier si NavigationService est disponible
    if (NavigationService.navigatorKey.currentState == null) {
      debugPrint('❌ [NotificationService] NavigatorKey.currentState est null !');
      _pendingContentNavigation = {
        'contentType': contentType,
        'contentId': contentId,
      };
      debugPrint('🕒 [NotificationService] Navigation mise en attente (app pas prête)');
      return;
    }
    
    _performNavigation(contentType, contentId);
    debugPrint('📱 [NotificationService] ====================================');
  }

  static void processPendingNavigation() {
    try {
      final pending = _pendingContentNavigation;
      if (pending == null) return;
      if (NavigationService.navigatorKey.currentState == null) return;

      final contentType = pending['contentType'];
      final contentId = pending['contentId'];
      if (contentType == null || contentId == null) return;

      _pendingContentNavigation = null;
      debugPrint('✅ [NotificationService] Traitement navigation en attente: $contentType/$contentId');
      _performNavigation(contentType, contentId);
    } catch (e) {
      debugPrint('❌ [NotificationService] Erreur processPendingNavigation: $e');
    }
  }

  static void _trackNotificationOpen(OSNotificationClickEvent event) {
    try {
      final data = event.notification.additionalData;
      final contentType = data?['content_type']?.toString();
      final contentId = data?['content_id']?.toString();
      final deepLink = data?['deep_link']?.toString();
      final notificationId = event.notification.notificationId;

      AnalyticsService.logCustomEvent(
        eventName: 'notification_open',
        parameters: {
          'notification_id': notificationId ?? '',
          'content_type': contentType ?? '',
          'content_id': contentId ?? '',
          'deep_link': deepLink ?? '',
          'source': 'onesignal',
        },
      );
    } catch (e) {
      debugPrint('❌ [NotificationService] Erreur tracking notification_open: $e');
    }
  }

  /// Effectue la navigation vers le contenu spécifié
  static void _performNavigation(String contentType, String contentId) {
    try {
      // Naviguer selon le type de contenu
      switch (contentType.toLowerCase()) {
        case 'recipe':
          debugPrint('🍽️ [NotificationService] Navigation vers recette ID: $contentId');
          NavigationService.goToRecipeDetail(contentId);
          debugPrint('✅ [NotificationService] Navigation recette lancée');
          break;
        case 'tip':
          debugPrint('💡 [NotificationService] Navigation vers astuce ID: $contentId');
          NavigationService.goToTipDetail(contentId);
          debugPrint('✅ [NotificationService] Navigation astuce lancée');
          break;
        case 'event':
          debugPrint('📅 [NotificationService] Navigation vers événement ID: $contentId');
          NavigationService.goToEventDetail(contentId);
          debugPrint('✅ [NotificationService] Navigation événement lancée');
          break;
        case 'dinor-tv':
        case 'dinor_tv':
          debugPrint('📺 [NotificationService] Navigation vers Dinor TV');
          NavigationService.goToDinorTv();
          debugPrint('✅ [NotificationService] Navigation Dinor TV lancée');
          break;
        case 'page':
          debugPrint('📄 [NotificationService] Navigation vers page: $contentId');
          debugPrint('⚠️ [NotificationService] Navigation page non implémentée');
          break;
        default:
          debugPrint('⚠️ [NotificationService] Type de contenu non géré: $contentType');
          debugPrint('🔍 [NotificationService] Types supportés: recipe, tip, event, dinor-tv, page');
      }
    } catch (e) {
      debugPrint('❌ [NotificationService] Erreur lors de la navigation: $e');
      debugPrint('🔧 [NotificationService] Type: $contentType, ID: $contentId');
    }
  }

  static Future<void> _launchWebUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        debugPrint('✅ [NotificationService] URL ouverte avec succès: $url');
      } else {
        debugPrint('❌ [NotificationService] Impossible d\'ouvrir l\'URL: $url');
      }
    } catch (e) {
      debugPrint('❌ [NotificationService] Erreur lors de l\'ouverture de l\'URL: $e');
    }
  }
  
  static Future<String?> getUserId() async {
    try {
      final userId = OneSignal.User.getOnesignalId();
      debugPrint('👤 [NotificationService] User ID: $userId');
      return userId;
    } catch (e) {
      debugPrint('❌ [NotificationService] Erreur getUserId: $e');
      return null;
    }
  }
  
  static void setExternalUserId(String userId) {
    try {
      OneSignal.login(userId);
      debugPrint('👤 [NotificationService] External User ID défini: $userId');
    } catch (e) {
      debugPrint('❌ [NotificationService] Erreur setExternalUserId: $e');
    }
  }
  
  static void addTag(String key, String value) {
    try {
      OneSignal.User.addTags({key: value});
      debugPrint('🏷️ [NotificationService] Tag ajouté: $key = $value');
    } catch (e) {
      debugPrint('❌ [NotificationService] Erreur addTag: $e');
    }
  }
  
  static void removeTag(String key) {
    try {
      OneSignal.User.removeTags([key]);
      debugPrint('🏷️ [NotificationService] Tag supprimé: $key');
    } catch (e) {
      debugPrint('❌ [NotificationService] Erreur removeTag: $e');
    }
  }
} 