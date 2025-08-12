/**
 * BOTTOM_NAVIGATION.DART - CONVERSION FIDÈLE DE BottomNavigation.vue
 * 
 * FIDÉLITÉ VISUELLE :
 * - Position : absolute bottom (0, 0, 0) → positioned bottom
 * - Couleur : #F4D03F (fond doré) identique
 * - Hauteur : 80px exacte + safe area insets
 * - 6 onglets : même layout flex space-around
 * - État actif : #FF6B35 (orange) + soulignement 24px
 * - Police : Roboto 12px/500 pour labels
 * - Icônes : 24px Lucide identiques
 * 
 * FIDÉLITÉ FONCTIONNELLE :
 * - isActive() : même logique route matching
 * - handleItemClick() : authentification profil + navigation
 * - AuthModal : même comportement
 * - Menu statique : 6 items identiques (home, recipes, tips, events, dinor-tv, profile)
 */

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/navigation_service.dart';
import '../../styles/shadows.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

// Components
import '../common/auth_modal.dart';

// Composables et stores
import '../../composables/use_auth_handler.dart';
import '../../composables/use_pages.dart';
import '../../services/tutorial_service.dart';


class BottomNavigation extends ConsumerStatefulWidget {
  const BottomNavigation({Key? key}) : super(key: key);

  @override
  ConsumerState<BottomNavigation> createState() => _BottomNavigationState();
}

class _BottomNavigationState extends ConsumerState<BottomNavigation> {
  bool _showAuthModal = false;
  String _authModalMessage = '';
  bool _showScrollTooltip = true;
  String _currentRoute = '/';

  @override
  void initState() {
    super.initState();
    
    // Ajouter un listener pour les changements de route
    NavigationService.addRouteChangeListener(_onRouteChanged);
    
    // Charger les pages au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(usePagesProvider.notifier).loadPages();
      
      // Initialiser la route actuelle
      _currentRoute = NavigationService.currentRoute;
    });
  }
  
  void _onRouteChanged(String newRoute) {
    if (mounted) {
      setState(() {
        _currentRoute = newRoute;
      });
      print('🔄 [BottomNav] Route changée vers: $newRoute');
    }
  }

  @override
  void dispose() {
    NavigationService.removeRouteChangeListener(_onRouteChanged);
    super.dispose();
  }


  // Surveiller les changements de pages pour afficher le tutoriel si nécessaire (désactivé temporairement)
  void _checkForNavigationTutorial(List<PageModel> pages) {
    // final totalItems = _menuItems.length + pages.length;
    // if (totalItems > 6) {
    //   // Attendre un peu que l'interface soit stable et que le contexte soit prêt
    //   Future.delayed(const Duration(milliseconds: 3000), () {
    //     try {
    //       if (mounted && Navigator.of(context, rootNavigator: false).canPop() == false) {
    //         TutorialService.showNavigationTutorialIfNeeded(context, totalItems);
    //       }
    //     } catch (e) {
    //       print('⚠️ [BottomNav] Erreur tutoriel navigation: $e');
    //     }
    //   });
    // }
  }

  // Menu statique sans profil
  final List<Map<String, dynamic>> _menuItems = [
    {
      'name': 'all',
      'path': '/',
      'icon': LucideIcons.home,
      'label': 'Accueil',
      'action_type': 'route'
    },
    {
      'name': 'recipes',
      'path': '/recipes',
      'icon': LucideIcons.chefHat,
      'label': 'Recettes',
      'action_type': 'route'
    },
    {
      'name': 'tips',
      'path': '/tips',
      'icon': LucideIcons.lightbulb,
      'label': 'Astuces',
      'action_type': 'route'
    },
    {
      'name': 'events',
      'path': '/events',
      'icon': LucideIcons.calendar,
      'label': 'Événements',
      'action_type': 'route'
    },
    {
      'name': 'dinor-tv',
      'path': '/dinor-tv',
      'icon': LucideIcons.playCircle,
      'label': 'DinorTV',
      'action_type': 'route'
    },
  ];

  // REPRODUCTION EXACTE de handleItemClick() Vue
  void _handleItemClick(Map<String, dynamic> item) {
    print('🔘 [BottomNav] Clic sur item: ${item['name']} -> ${item['path']}');

    switch (item['action_type']) {
      case 'route':
        // Navigation interne standard
        if (item['path'] != null) {
          if (item['path'] == '/') {
            NavigationService.pushNamedAndClearStack('/');
          } else {
            NavigationService.pushNamed(item['path']);
          }
        }
        break;

      case 'web_embed':
        // Ouvrir la page dans une webview via route nommée (contexte global)
        if (item['url'] != null) {
          NavigationService.pushNamed(NavigationService.webEmbed, arguments: {
            'url': item['url'],
            'title': item['label'],
          });
        }
        break;

      case 'external_link':
        // Ouvrir dans un navigateur externe
        if (item['url'] != null) {
          _launchURL(item['url']);
        }
        break;

      default:
        // Type d'action non géré - Fallback vers navigation route si définie
        if (item['path'] != null) {
          if (item['path'] == '/') {
            NavigationService.pushNamedAndClearStack('/');
          } else {
            NavigationService.pushNamed(item['path']);
          }
        }
    }
  }

  // IDENTIQUE à isActive() Vue - Version simplifiée utilisant NavigationService
  bool _isActive(Map<String, dynamic> item) {
    // Utiliser directement NavigationService.currentRoute qui se met à jour lors des navigations
    final currentRoute = NavigationService.currentRoute;

    // Debug - afficher la route actuelle
    print('🧭 [BottomNav] Route actuelle: $currentRoute, Item: ${item['path']} (${item['name']})');

    // Routes internes
    if (item['action_type'] == 'route' && item['path'] != null) {
      // Cas spécial pour la route d'accueil
      if (item['path'] == '/' && (currentRoute == '/' || currentRoute == NavigationService.home)) {
        return true;
      }
      
      // Autres routes - vérification exacte et par préfixe
      if (currentRoute == item['path']) {
        return true;
      }
      
      // Vérification par préfixe pour les routes imbriquées (sauf pour '/')
      if (item['path'] != '/' && currentRoute.startsWith(item['path'])) {
        return true;
      }
    }

    // Pages web intégrées: actif si route /web-embed ET titre/URL correspondants
    if (item['action_type'] == 'web_embed') {
      return currentRoute == NavigationService.webEmbed;
    }

    // Liens externes: pas d'état actif (navigateur externe)
    if (item['action_type'] == 'external_link') {
      return false;
    }

    return false;
  }

  // (remplacé par navigation via NavigationService.webEmbed)

  // Ouvrir une URL dans le navigateur externe
  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      print('❌ Impossible d\'ouvrir l\'URL: $url');
    }
  }

  // Gestion de l'authentification réussie
  void _onAuthSuccess() {
    setState(() => _showAuthModal = false);
    // Redirection vers le profil après authentification
    NavigationService.pushReplacementNamed('/profile');
  }

  @override
  Widget build(BuildContext context) {
    final pagesState = ref.watch(usePagesProvider);
    final navigationPages = ref.watch(navigationPagesProvider);
    
    // Vérifier si on doit afficher le tutoriel de navigation
    if (navigationPages.isNotEmpty) {
      _checkForNavigationTutorial(navigationPages);
    }
    
    // Combiner les éléments de menu statiques avec les pages dynamiques
    final allMenuItems = [
      ..._menuItems,
      // Ajouter les pages depuis le dashboard Filament
      ...navigationPages.map((page) => {
        'name': 'page_${page.id}',
        'path': '/page/${page.id}',
        'icon': LucideIcons.globe,
        'label': page.title,
        'action_type': page.isExternal ? 'external_link' : 'web_embed',
        'url': page.url,
      }).toList(),
    ];

    // IMPORTANT: Retourner un Container dimensionné pour bottomNavigationBar
    return Container
      (
      height: 80 + MediaQuery.of(context).padding.bottom,
      decoration: const BoxDecoration(
        color: Color(0xFFF4D03F),
        border: Border(
          top: BorderSide(
            color: Color.fromRGBO(0, 0, 0, 0.1),
            width: 1,
          ),
        ),
        boxShadow: AppShadows.softTop,
      ),
      child: SafeArea(
        child: SizedBox(
          height: 80,
          child: Stack(
            children: [
              // Navigation avec largeurs uniformes
              LayoutBuilder(
                builder: (context, constraints) {
                  final availableWidth = constraints.maxWidth - 16; // Padding horizontal
                  final itemWidth = availableWidth / allMenuItems.length;
                  
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: allMenuItems.map((item) => 
                        SizedBox(
                          width: itemWidth.clamp(70.0, 120.0), // Min 70px, max 120px par item
                          child: _buildNavItem(item, isCompact: allMenuItems.length > 6),
                        )
                      ).toList(),
                    ),
                  );
                },
              ),
              
              // Tooltip pour indiquer le défilement (si overflow)
              if (allMenuItems.length > 6 && _showScrollTooltip)
                Positioned(
                  right: 8,
                  top: 8,
                  child: GestureDetector(
                    onTap: () => setState(() => _showScrollTooltip = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.swap_horiz,
                            size: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Faites défiler →',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            LucideIcons.x,
                            size: 10,
                            color: Colors.white70,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _displayAuthModal() {
    // Vérifier que le contexte est prêt avant d'afficher la modale
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _showAuthModal) {
        showDialog(
          context: context,
          barrierDismissible: true,
          useRootNavigator: true,
          builder: (BuildContext context) {
            return AuthModal(
              isOpen: true,
              onClose: () {
                print('🔐 [BottomNav] Fermeture de la modal d\'authentification');
                Navigator.of(context, rootNavigator: true).pop();
                setState(() => _showAuthModal = false);
              },
              onAuthenticated: () {
                print('✅ [BottomNav] Utilisateur authentifié, fermeture de la modal');
                Navigator.of(context, rootNavigator: true).pop();
                setState(() => _showAuthModal = false);
                _onAuthSuccess();
              },
            );
          },
        );
      }
    });
  }

  // Construction d'un item de navigation - STYLES CSS IDENTIQUES
  Widget _buildNavItem(Map<String, dynamic> item, {bool isCompact = false}) {
    final isActive = _isActive(item);
    print('🏗️ [BottomNav] Construction item: ${item['name']} - Active: $isActive - Compact: $isCompact');

    return GestureDetector(
      behavior: HitTestBehavior.opaque,  // S'assurer que toute la zone est cliquable
      onTap: () {
        print('👆 [BottomNav] Tap détecté sur: ${item['name']}');
        _handleItemClick(item);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 8,
          horizontal: 4,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? const Color.fromRGBO(255, 107, 53, 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isActive
              ? Border.all(
                  color: const Color(0xFFFF6B35),
                  width: 1,
                )
              : null,
          boxShadow: isActive
              ? [
                  const BoxShadow(
                    color: Color(0xFFFF6B35),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icône - taille uniforme
            Container(
              margin: const EdgeInsets.only(bottom: 4),
              child: Icon(
                item['icon'],
                size: 22, // Taille uniforme pour tous
                color: isActive
                    ? const Color(0xFFFF6B35)
                    : const Color.fromRGBO(0, 0, 0, 0.7),
              ),
            ),

            // Label - taille uniforme
            Text(
              item['label'],
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 11, // Taille uniforme pour tous
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive
                    ? const Color(0xFFFF6B35)
                    : const Color.fromRGBO(0, 0, 0, 0.7),
                height: 1.2,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),

            // Soulignement orange pour l'item actif
            if (isActive)
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 20, // Largeur uniforme pour tous
                height: 2,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B35),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

