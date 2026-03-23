import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/notifications_service.dart';
import '../services/navigation_service.dart';
import '../services/permissions_service.dart';
import '../composables/use_auth_handler.dart';
import '../components/common/auth_modal.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  List<NotificationModel> notifications = [];
  NotificationsPagination? pagination;
  bool isLoading = true;
  bool isLoadingMore = false;
  String? errorMessage;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthAndLoadNotifications();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _checkAuthAndLoadNotifications() async {
    final authState = ref.read(useAuthHandlerProvider);
    
    if (!authState.isAuthenticated) {
      _showAuthModal();
      return;
    }

    await _loadNotifications();
  }

  void _showAuthModal() {
    showDialog(
      context: context,
      barrierDismissible: true,
      useRootNavigator: true,
      builder: (BuildContext context) {
        return AuthModal(
          isOpen: true,
          onClose: () {
            Navigator.of(context, rootNavigator: true).pop();
          },
          onAuthenticated: () {
            Navigator.of(context, rootNavigator: true).pop();
            _loadNotifications();
          },
        );
      },
    );
  }

  Future<void> _loadNotifications({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        notifications.clear();
        pagination = null;
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      final notificationsService = ref.read(notificationsServiceProvider);
      final result = await notificationsService.getNotifications(page: 1);

      if (result['success']) {
        setState(() {
          notifications = result['notifications'];
          pagination = result['pagination'];
          isLoading = false;
          errorMessage = null;
        });
      } else {
        setState(() {
          errorMessage = result['error'];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Erreur de chargement: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (isLoadingMore || 
        pagination == null || 
        !pagination!.hasMorePages) {
      return;
    }

    setState(() {
      isLoadingMore = true;
    });

    try {
      final notificationsService = ref.read(notificationsServiceProvider);
      final result = await notificationsService.getNotifications(
        page: pagination!.currentPage + 1
      );

      if (result['success']) {
        setState(() {
          notifications.addAll(result['notifications']);
          pagination = result['pagination'];
          isLoadingMore = false;
        });
      } else {
        setState(() {
          isLoadingMore = false;
        });
        _showErrorSnackBar(result['error']);
      }
    } catch (e) {
      setState(() {
        isLoadingMore = false;
      });
      _showErrorSnackBar('Erreur de chargement: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _onNotificationTap(NotificationModel notification) {
    print('🔔 [NotificationsScreen] Notification cliquée:');
    print('   - ID: ${notification.id}');
    print('   - Titre: ${notification.title}');
    print('   - Deep Link: ${notification.deepLink}');
    print('   - Content Type: ${notification.contentType}');
    print('   - Content ID: ${notification.contentId}');
    print('   - URL: ${notification.url}');
    
    // Marquer comme lue localement pour une UX immédiate
    if (!notification.isRead) {
      setState(() {
        final index = notifications.indexWhere((n) => n.id == notification.id);
        if (index != -1) {
          notifications[index] = notification.copyWith(
            isRead: true,
            readAt: DateTime.now(),
          );
        }
      });

      // Marquer comme lue sur le serveur (en arrière-plan)
      ref.read(notificationsServiceProvider).markAsRead(notification.id);
    }

    // Navigation vers le contenu
    try {
      if (notification.deepLink != null && notification.deepLink!.isNotEmpty) {
        print('🔗 [NotificationsScreen] Utilisation du deep link...');
        _handleDeepLink(notification.deepLink!);
      } else if (notification.contentType != null && 
                 notification.contentId != null &&
                 notification.contentType!.isNotEmpty &&
                 notification.contentId!.isNotEmpty) {
        print('📱 [NotificationsScreen] Utilisation du type/ID de contenu...');
        _handleContentNavigation(notification.contentType!, notification.contentId!);
      } else if (notification.url != null && notification.url!.isNotEmpty) {
        print('🌐 [NotificationsScreen] Utilisation de l\'URL...');
        _launchUrl(notification.url!);
      } else {
        print('⚠️ [NotificationsScreen] Aucune information de navigation disponible');
        _showErrorSnackBar('Cette notification ne contient pas de lien de navigation');
      }
    } catch (e) {
      print('❌ [NotificationsScreen] Erreur lors du traitement de la notification: $e');
      _showErrorSnackBar('Erreur lors de l\'ouverture de la notification');
    }
  }

  void _handleDeepLink(String deepLink) {
    print('🔗 [NotificationsScreen] === DEBUT DEEP LINK ===');
    print('🔗 [NotificationsScreen] Deep link reçu: $deepLink');
    
    try {
      final uri = Uri.parse(deepLink);
      print('🔗 [NotificationsScreen] URI parsé: $uri');
      print('🔗 [NotificationsScreen] Scheme: ${uri.scheme}');
      print('🔗 [NotificationsScreen] Host: ${uri.host}');
      print('🔗 [NotificationsScreen] Path: ${uri.path}');
      
      final pathSegments = uri.pathSegments;
      print('🔗 [NotificationsScreen] Path segments: $pathSegments');
      print('🔗 [NotificationsScreen] Nombre de segments: ${pathSegments.length}');
      
      // Pour les deep links de format: dinor://event/2
      // uri.host = "event" (contentType)
      // pathSegments[0] = "2" (contentId)
      
      String? contentType;
      String? contentId;
      
      if (uri.host.isNotEmpty) {
        contentType = uri.host;
        print('🔗 [NotificationsScreen] Content Type depuis host: $contentType');
        
        if (pathSegments.isNotEmpty) {
          contentId = pathSegments[0];
          print('🔗 [NotificationsScreen] Content ID depuis path[0]: $contentId');
        }
      } else if (pathSegments.length >= 2) {
        // Fallback pour format: dinor:///event/2
        contentType = pathSegments[0];
        contentId = pathSegments[1];
        print('🔗 [NotificationsScreen] Fallback - Type: $contentType, ID: $contentId');
      }
      
      print('🔗 [NotificationsScreen] === PARSING FINAL ===');
      print('🔗 [NotificationsScreen] Content Type final: $contentType');
      print('🔗 [NotificationsScreen] Content ID final: $contentId');
      
      if (contentType != null && contentId != null && 
          contentType.isNotEmpty && contentId.isNotEmpty) {
        print('🔗 [NotificationsScreen] Appel de _handleContentNavigation...');
        _handleContentNavigation(contentType, contentId);
      } else {
        print('❌ [NotificationsScreen] Content Type ou ID manquant');
        print('❌ [NotificationsScreen] Type: "$contentType", ID: "$contentId"');
        _showErrorSnackBar('Lien de navigation invalide - données manquantes');
      }
    } catch (e) {
      print('❌ [NotificationsScreen] Erreur parsing deep link: $e');
      _showErrorSnackBar('Erreur lors de l\'analyse du lien: $e');
    }
    
    print('🔗 [NotificationsScreen] === FIN DEEP LINK ===');
  }

  void _handleContentNavigation(String contentType, String contentId) {
    print('🔍 [NotificationsScreen] Navigation demandée:');
    print('   - Type: $contentType');
    print('   - ID: $contentId');
    
    try {
      switch (contentType.toLowerCase()) {
        case 'recipe':
          print('🍽️ [NotificationsScreen] Navigation vers recette...');
          NavigationService.goToRecipeDetail(contentId);
          print('✅ [NotificationsScreen] Navigation recette initiée');
          break;
        case 'tip':
          print('💡 [NotificationsScreen] Navigation vers astuce...');
          NavigationService.goToTipDetail(contentId);
          print('✅ [NotificationsScreen] Navigation astuce initiée');
          break;
        case 'event':
          print('📅 [NotificationsScreen] Navigation vers événement...');
          NavigationService.goToEventDetail(contentId);
          print('✅ [NotificationsScreen] Navigation événement initiée');
          break;
        case 'dinor-tv':
        case 'dinor_tv':
          print('📺 [NotificationsScreen] Navigation vers Dinor TV...');
          NavigationService.goToDinorTv();
          print('✅ [NotificationsScreen] Navigation Dinor TV initiée');
          break;
        default:
          print('⚠️ [NotificationsScreen] Type de contenu non géré: $contentType');
          _showErrorSnackBar('Type de contenu non supporté: $contentType');
      }
    } catch (e) {
      print('❌ [NotificationsScreen] Erreur lors de la navigation: $e');
      _showErrorSnackBar('Erreur lors de la navigation: $e');
    }
  }

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        print('🌐 URL ouverte avec succès: $url');
      } else {
        print('❌ Impossible d\'ouvrir l\'URL: $url');
        _showErrorSnackBar('Impossible d\'ouvrir le lien');
      }
    } catch (e) {
      print('❌ Erreur lors de l\'ouverture de l\'URL: $e');
      _showErrorSnackBar('Erreur lors de l\'ouverture du lien');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadNotifications(refresh: true),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadNotifications(refresh: true),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune notification',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vous recevrez ici toutes vos notifications.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: notifications.length + (isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == notifications.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final notification = notifications[index];
        return _buildNotificationCard(notification);
      },
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    final isUnread = !notification.isRead;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isUnread ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isUnread 
          ? BorderSide(color: Colors.blue.shade300, width: 1.5)
          : BorderSide.none,
      ),
      color: isUnread ? const Color.fromRGBO(227, 242, 253, 1) : Colors.white,
      child: InkWell(
        onTap: () => _onNotificationTap(notification),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Indicateur de notification non lue
                  if (isUnread) 
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(top: 4, right: 8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade600,
                        shape: BoxShape.circle,
                      ),
                    ),
                  // Emoji/Icône du type
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isUnread ? Colors.blue.shade100 : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      notification.typeEmoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Contenu de la notification
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                            color: isUnread ? Colors.black87 : Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification.message,
                          style: TextStyle(
                            fontSize: 14,
                            color: isUnread ? Colors.grey[700] : Colors.grey[600],
                            height: 1.3,
                            fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
                          ),
                        ),
                        if (notification.contentName != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isUnread ? Colors.green.shade100 : Colors.green.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isUnread ? Colors.green.shade300 : Colors.green.shade200,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              notification.contentName!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Date et statut
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        notification.displayDate,
                        style: TextStyle(
                          fontSize: 12,
                          color: isUnread ? Colors.grey[600] : Colors.grey[500],
                          fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
                        ),
                      ),
                      if (isUnread) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade600,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'NOUVEAU',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 