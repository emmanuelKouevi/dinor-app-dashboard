/**
 * UNIFIED_LIKE_BUTTON.DART - BOUTON DE LIKE UNIFIÉ AVEC SYNCHRONISATION
 * 
 * FONCTIONNALITÉS :
 * - Gestion unifiée pour tous types de contenu (recipe, tip, event, video)
 * - Mise à jour automatique des compteurs après like/unlike
 * - Synchronisation en temps réel avec le serveur
 * - Animation fluide et feedback visuel
 * - Gestion d'authentification intégrée
 * - Retry automatique en cas d'erreur
 */

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../services/local_database_service.dart';
import '../../composables/use_auth_handler.dart';
import 'auth_modal.dart';

// Modèle pour les données de like
class LikeData {
  final String type;
  final String itemId;
  final bool isLiked;
  final int count;
  final DateTime lastUpdated;

  LikeData({
    required this.type,
    required this.itemId,
    required this.isLiked,
    required this.count,
    required this.lastUpdated,
  });

  String get key => '${type}_$itemId';

  LikeData copyWith({
    String? type,
    String? itemId,
    bool? isLiked,
    int? count,
    DateTime? lastUpdated,
  }) {
    return LikeData(
      type: type ?? this.type,
      itemId: itemId ?? this.itemId,
      isLiked: isLiked ?? this.isLiked,
      count: count ?? this.count,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'itemId': itemId,
      'isLiked': isLiked,
      'count': count,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory LikeData.fromJson(Map<String, dynamic> json) {
    return LikeData(
      type: json['type'] ?? '',
      itemId: json['itemId'] ?? '',
      isLiked: json['isLiked'] ?? false,
      count: json['count'] ?? 0,
      lastUpdated: DateTime.tryParse(json['lastUpdated'] ?? '') ?? DateTime.now(),
    );
  }
}

// État global des likes
class UnifiedLikesState {
  final Map<String, LikeData> likes;
  final bool isLoading;
  final String? error;

  const UnifiedLikesState({
    this.likes = const {},
    this.isLoading = false,
    this.error,
  });

  UnifiedLikesState copyWith({
    Map<String, LikeData>? likes,
    bool? isLoading,
    String? error,
  }) {
    return UnifiedLikesState(
      likes: likes ?? this.likes,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  bool isLiked(String type, String itemId) {
    final key = '${type}_$itemId';
    return likes[key]?.isLiked ?? false;
  }

  int getLikeCount(String type, String itemId) {
    final key = '${type}_$itemId';
    return likes[key]?.count ?? 0;
  }
}

// Service de likes unifié
class UnifiedLikesService extends StateNotifier<UnifiedLikesState> {
  static const String baseUrl = 'https://new.dinorapp.com/api/v1';
  final LocalDatabaseService _localDB;

  UnifiedLikesService(this._localDB) : super(const UnifiedLikesState()) {
    _loadFromCache();
  }

  // Charger depuis le cache local
  Future<void> _loadFromCache() async {
    try {
      final likes = await _localDB.getUserLikes();
      final counts = await _localDB.getLikeCounts();
      
      final Map<String, LikeData> likeData = {};
      
      // Combiner les données de likes et de compteurs
      for (final entry in likes.entries) {
        final parts = entry.key.split('_');
        if (parts.length >= 2) {
          final type = parts[0];
          final itemId = parts.sublist(1).join('_');
          
          likeData[entry.key] = LikeData(
            type: type,
            itemId: itemId,
            isLiked: entry.value,
            count: counts[entry.key] ?? 0,
            lastUpdated: DateTime.now(),
          );
        }
      }
      
      state = state.copyWith(likes: likeData);
      print('📱 [UnifiedLikes] Données chargées depuis le cache: ${likeData.length} éléments');
    } catch (e) {
      print('❌ [UnifiedLikes] Erreur chargement cache: $e');
    }
  }

  // Sauvegarder en cache
  Future<void> _saveToCache() async {
    try {
      final likes = <String, bool>{};
      final counts = <String, int>{};
      
      for (final entry in state.likes.entries) {
        likes[entry.key] = entry.value.isLiked;
        counts[entry.key] = entry.value.count;
      }
      
      await _localDB.saveUserLikes(likes);
      await _localDB.saveLikeCounts(counts);
      
      print('💾 [UnifiedLikes] Données sauvegardées en cache');
    } catch (e) {
      print('❌ [UnifiedLikes] Erreur sauvegarde cache: $e');
    }
  }

  // Obtenir les headers d'authentification
  Future<Map<String, String>> _getHeaders() async {
    final authState = await _localDB.getAuthState();
    
    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    
    if (authState != null && authState['token'] != null) {
      headers['Authorization'] = 'Bearer ${authState['token']}';
    }
    
    return headers;
  }

  // Initialiser les données d'un contenu
  void setInitialData(String type, String itemId, bool isLiked, int count) {
    final key = '${type}_$itemId';
    final currentLikes = Map<String, LikeData>.from(state.likes);
    
    currentLikes[key] = LikeData(
      type: type,
      itemId: itemId,
      isLiked: isLiked,
      count: count,
      lastUpdated: DateTime.now(),
    );
    
    state = state.copyWith(likes: currentLikes);
    _saveToCache();
  }

  // Récupérer les données exactes depuis l'API
  Future<void> fetchExactData(String type, String itemId) async {
    try {
      print('🔍 [UnifiedLikes] Récupération données exactes $type:$itemId');
      
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/likes/check?likeable_type=$type&likeable_id=$itemId'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          final responseData = data['data'];
          final key = '${type}_$itemId';
          final currentLikes = Map<String, LikeData>.from(state.likes);
          
          currentLikes[key] = LikeData(
            type: type,
            itemId: itemId,
            isLiked: responseData['is_liked'] ?? false,
            count: responseData['total_likes'] ?? 0,
            lastUpdated: DateTime.now(),
          );
          
          state = state.copyWith(likes: currentLikes);
          _saveToCache();
          
          print('✅ [UnifiedLikes] Données exactes récupérées: ${responseData['is_liked']} / ${responseData['total_likes']}');
        }
      }
    } catch (e) {
      print('❌ [UnifiedLikes] Erreur récupération données exactes: $e');
    }
  }

  // Toggle un like
  Future<bool> toggleLike(String type, String itemId) async {
    final key = '${type}_$itemId';
    final currentData = state.likes[key];
    
    // Mise à jour optimiste immédiate
    final currentLikes = Map<String, LikeData>.from(state.likes);
    final wasLiked = currentData?.isLiked ?? false;
    final currentCount = currentData?.count ?? 0;
    
    currentLikes[key] = LikeData(
      type: type,
      itemId: itemId,
      isLiked: !wasLiked,
      count: wasLiked ? currentCount - 1 : currentCount + 1,
      lastUpdated: DateTime.now(),
    );
    
    state = state.copyWith(likes: currentLikes, isLoading: true);
    
    try {
      print('❤️ [UnifiedLikes] Toggle like $type:$itemId (était: $wasLiked)');
      
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/likes/toggle'),
        headers: headers,
        body: json.encode({
          'likeable_type': type,
          'likeable_id': itemId,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          final responseData = data['data'];
          
          // Mise à jour avec les données exactes du serveur
          currentLikes[key] = LikeData(
            type: type,
            itemId: itemId,
            isLiked: responseData['is_liked'] ?? !wasLiked,
            count: responseData['total_likes'] ?? (wasLiked ? currentCount - 1 : currentCount + 1),
            lastUpdated: DateTime.now(),
          );
          
          state = state.copyWith(
            likes: currentLikes,
            isLoading: false,
            error: null,
          );
          
          await _saveToCache();
          
          print('✅ [UnifiedLikes] Like toggled: ${responseData['is_liked']} / ${responseData['total_likes']}');
          return true;
        }
      } else if (response.statusCode == 401) {
        throw Exception('Authentification requise');
      } else {
        throw Exception('Erreur serveur ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [UnifiedLikes] Erreur toggle like: $e');
      
      // Rollback optimiste en cas d'erreur
      if (currentData != null) {
        currentLikes[key] = currentData;
      } else {
        currentLikes.remove(key);
      }
      
      state = state.copyWith(
        likes: currentLikes,
        isLoading: false,
        error: e.toString(),
      );
      
      rethrow;
    }
    
    return false;
  }

  // Rafraîchir toutes les données
  Future<void> refreshAll() async {
    try {
      print('🔄 [UnifiedLikes] Rafraîchissement de toutes les données');
      state = state.copyWith(isLoading: true);
      
      // Récupérer les données fraîches pour tous les éléments
      final futures = state.likes.values.map((like) => 
        fetchExactData(like.type, like.itemId)
      ).toList();
      
      await Future.wait(futures);
      
      state = state.copyWith(isLoading: false);
      print('✅ [UnifiedLikes] Rafraîchissement terminé');
    } catch (e) {
      print('❌ [UnifiedLikes] Erreur rafraîchissement: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

// Provider pour le service unifié
final unifiedLikesProvider = StateNotifierProvider<UnifiedLikesService, UnifiedLikesState>((ref) {
  final localDB = ref.read(localDatabaseServiceProvider);
  return UnifiedLikesService(localDB);
});

// Composant bouton de like unifié
class UnifiedLikeButton extends ConsumerStatefulWidget {
  final String type;
  final String itemId;
  final bool initialLiked;
  final int initialCount;
  final bool showCount;
  final String size;
  final String variant;
  final VoidCallback? onAuthRequired;
  final bool autoFetch;

  const UnifiedLikeButton({
    Key? key,
    required this.type,
    required this.itemId,
    this.initialLiked = false,
    this.initialCount = 0,
    this.showCount = true,
    this.size = 'medium',
    this.variant = 'standard',
    this.onAuthRequired,
    this.autoFetch = false,
  }) : super(key: key);

  @override
  ConsumerState<UnifiedLikeButton> createState() => _UnifiedLikeButtonState();
}

class _UnifiedLikeButtonState extends ConsumerState<UnifiedLikeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    // Initialiser les données
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(unifiedLikesProvider.notifier).setInitialData(
        widget.type,
        widget.itemId,
        widget.initialLiked,
        widget.initialCount,
      );
      
      // Récupérer les données exactes si demandé
      if (widget.autoFetch) {
        ref.read(unifiedLikesProvider.notifier).fetchExactData(
          widget.type,
          widget.itemId,
        );
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showAuthModal() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AuthModal(
        isOpen: true,
        onClose: () => Navigator.of(context).pop(),
        onAuthenticated: () {
          Navigator.of(context).pop();
          // Réessayer l'action après authentification
          Future.delayed(const Duration(milliseconds: 500), () {
            _toggleLike();
          });
        },
      ),
    );
  }

  Future<void> _toggleLike() async {
    if (_isProcessing) return;
    
    final authState = ref.read(useAuthHandlerProvider);
    if (!authState.isAuthenticated) {
      print('🔐 [UnifiedLikeButton] Authentification requise');
      _showAuthModal();
      return;
    }

    setState(() => _isProcessing = true);
    
    // Animation immédiate pour la responsivité
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
    
    try {
      final success = await ref.read(unifiedLikesProvider.notifier).toggleLike(
        widget.type,
        widget.itemId,
      );
      
      if (success && mounted) {
        final likesState = ref.read(unifiedLikesProvider);
        final isNowLiked = likesState.isLiked(widget.type, widget.itemId);
        final count = likesState.getLikeCount(widget.type, widget.itemId);
        
        // Feedback visuel avec SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  isNowLiked ? LucideIcons.heart : LucideIcons.heartOff,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isNowLiked 
                      ? '❤️ Ajouté aux favoris ($count likes)'
                      : '💔 Retiré des favoris ($count likes)',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: isNowLiked 
              ? const Color(0xFFE53E3E)
              : Colors.grey[600],
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      print('❌ [UnifiedLikeButton] Erreur toggle: $e');
      
      if (e.toString().contains('Authentification requise')) {
        _showAuthModal();
      } else {
        // Afficher erreur avec bouton retry
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('❌ Erreur lors de la mise à jour du like'),
              duration: const Duration(seconds: 4),
              backgroundColor: Colors.red[600],
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              action: SnackBarAction(
                label: 'Réessayer',
                textColor: Colors.white,
                onPressed: _toggleLike,
              ),
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final likesState = ref.watch(unifiedLikesProvider);
    final isLiked = likesState.isLiked(widget.type, widget.itemId);
    final count = likesState.getLikeCount(widget.type, widget.itemId);
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTap: _isProcessing ? null : _toggleLike,
            child: Container(
              padding: _getPadding(),
              decoration: _getDecoration(isLiked),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Icône principale avec animation de remplissage
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          key: ValueKey(isLiked),
                          size: _getIconSize(),
                          color: _getIconColor(isLiked),
                        ),
                      ),
                      
                      // Indicateur de chargement
                      if (_isProcessing)
                        SizedBox(
                          width: _getIconSize() * 1.4,
                          height: _getIconSize() * 1.4,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getIconColor(isLiked).withOpacity(0.5),
                            ),
                          ),
                        ),
                    ],
                  ),
                  
                  if (widget.showCount) ...[
                    const SizedBox(width: 6),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        '$count',
                        key: ValueKey(count),
                        style: TextStyle(
                          fontSize: _getFontSize(),
                          fontWeight: FontWeight.w600,
                          color: _getTextColor(isLiked),
                          fontFamily: 'Roboto',
                        ),
                      ),
                    ),
                  ],
                  
                  // Indicateur de synchronisation globale
                  if (likesState.isLoading)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.grey[400]!,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  EdgeInsets _getPadding() {
    switch (widget.size) {
      case 'small':
        return const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
      case 'large':
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 10);
      default: // medium
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
    }
  }

  double _getIconSize() {
    switch (widget.size) {
      case 'small':
        return 16;
      case 'large':
        return 26;
      default: // medium
        return 20;
    }
  }

  double _getFontSize() {
    switch (widget.size) {
      case 'small':
        return 12;
      case 'large':
        return 16;
      default: // medium
        return 14;
    }
  }

  BoxDecoration? _getDecoration(bool isLiked) {
    switch (widget.variant) {
      case 'minimal':
        return null;
      case 'filled':
        return BoxDecoration(
          color: isLiked ? const Color(0xFFE53E3E) : Colors.grey[200],
          borderRadius: BorderRadius.circular(_getBorderRadius()),
          boxShadow: isLiked ? [
            BoxShadow(
              color: const Color(0xFFE53E3E).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        );
      default: // standard
        return BoxDecoration(
          color: isLiked ? const Color(0xFFE53E3E).withOpacity(0.1) : Colors.transparent,
          border: Border.all(
            color: isLiked ? const Color(0xFFE53E3E) : Colors.grey[300]!,
            width: isLiked ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(_getBorderRadius()),
        );
    }
  }

  double _getBorderRadius() {
    switch (widget.size) {
      case 'small':
        return 12;
      case 'large':
        return 20;
      default: // medium
        return 16;
    }
  }

  Color _getIconColor(bool isLiked) {
    if (isLiked) {
      return widget.variant == 'filled' ? Colors.white : const Color(0xFFE53E3E);
    }

    switch (widget.variant) {
      case 'filled':
        return Colors.grey[600]!;
      case 'minimal':
        return const Color(0xFF4A5568).withOpacity(0.35);
      default:
        return const Color(0xFF4A5568).withOpacity(0.55);
    }
  }

  Color _getTextColor(bool isLiked) {
    if (isLiked) {
      return widget.variant == 'filled' ? Colors.white : const Color(0xFFE53E3E);
    }

    switch (widget.variant) {
      case 'filled':
        return Colors.grey[600]!;
      case 'minimal':
        return const Color(0xFF4A5568).withOpacity(0.55);
      default:
        return const Color(0xFF4A5568).withOpacity(0.7);
    }
  }
} 