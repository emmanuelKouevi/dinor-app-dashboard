import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../services/comments_service.dart';
import '../../composables/use_auth_handler.dart';
import 'comment_item.dart';
import 'auth_modal.dart';

class UnifiedCommentsSection extends ConsumerStatefulWidget {
  final String contentType;
  final String contentId;
  final String contentTitle;
  final VoidCallback? onAuthRequired;
  final int initialCommentsToShow;
  final int commentsPerPage;

  const UnifiedCommentsSection({
    super.key,
    required this.contentType,
    required this.contentId,
    required this.contentTitle,
    this.onAuthRequired,
    this.initialCommentsToShow = 5,
    this.commentsPerPage = 5,
  });

  @override
  ConsumerState<UnifiedCommentsSection> createState() =>
      _UnifiedCommentsSectionState();
}

class _UnifiedCommentsSectionState
    extends ConsumerState<UnifiedCommentsSection> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  bool _isSubmitting = false;
  bool _showFullSection = false;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadComments();
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
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
          // Actualiser les commentaires après connexion
          Future.delayed(const Duration(milliseconds: 500), () {
            _loadComments();
          });
        },
      ),
    );
  }

  Future<void> _loadComments() async {
    await ref
        .read(commentsServiceProvider.notifier)
        .loadComments(widget.contentType, widget.contentId);
  }

  @override
  Widget build(BuildContext context) {
    final commentsKey = '${widget.contentType}_${widget.contentId}';
    final commentsState = ref.watch(commentsProvider(commentsKey));
    final authHandler = ref.watch(useAuthHandlerProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(commentsState),
          const SizedBox(height: 16),
          // Formulaire d'ajout de commentaire ou incitation à se connecter
          if (authHandler.isAuthenticated) ...[
            _buildCommentForm(),
            const SizedBox(height: 16),
          ] else ...[
            _buildQuickAuthPrompt(),
            const SizedBox(height: 16),
          ],
          if (_showFullSection) ...[
            // Liste des commentaires avec pagination
            _buildCommentsList(commentsState),
          ] else ...[
            // Aperçu des premiers commentaires
            _buildCommentsPreview(commentsState),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(CommentsState commentsState) {
    final commentsCount = commentsState.comments.length;

    return Row(
      children: [
        const Icon(
          LucideIcons.messageCircle,
          size: 20,
          color: Color(0xFF4A5568),
        ),
        const SizedBox(width: 8),
        const Text(
          'Commentaires',
          style: TextStyle(
            fontFamily: 'OpenSans',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF4D03F),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            commentsCount.toString(),
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2D3748),
            ),
          ),
        ),
        const Spacer(),
        if (commentsCount > 0)
          TextButton(
            onPressed: () {
              setState(() {
                _showFullSection = !_showFullSection;
                if (!_showFullSection) {
                  _currentPage = 1; // Reset pagination when collapsing
                }
              });
            },
            child: Text(
              _showFullSection ? 'Réduire' : 'Voir tout',
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 14,
                color: Color(0xFFE53E3E),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCommentForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _commentFocusNode.hasFocus
                  ? const Color(0xFFE53E3E)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: TextField(
            controller: _commentController,
            focusNode: _commentFocusNode,
            maxLines: 3,
            maxLength: 500,
            decoration: const InputDecoration(
              hintText: 'Partagez votre avis...',
              hintStyle: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 14,
                color: Color(0xFF718096),
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(12),
              counterStyle: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 12,
                color: Color(0xFF718096),
              ),
            ),
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 14,
              color: Color(0xFF2D3748),
            ),
            onChanged: (value) {
              setState(() {});
            },
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
            TextButton(
              onPressed: _commentController.text.trim().isEmpty
                  ? null
                  : () {
                      _commentController.clear();
                      _commentFocusNode.unfocus();
                    },
              child: const Text(
                'Annuler',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 14,
                  color: Color(0xFF718096),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _commentController.text.trim().isEmpty || _isSubmitting
                  ? null
                  : _submitComment,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53E3E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Publier',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAuthPrompt() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const Icon(
            LucideIcons.messageCircle,
            size: 20,
            color: Color(0xFF718096),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Partagez votre avis sur ce contenu',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 14,
                color: Color(0xFF718096),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: widget.onAuthRequired ?? _showAuthModal,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53E3E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: Size.zero,
            ),
            child: const Text(
              'Se connecter',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsList(CommentsState commentsState) {
    if (commentsState.isLoading && commentsState.comments.isEmpty) {
      return _buildLoadingState();
    }

    if (commentsState.error != null && commentsState.comments.isEmpty) {
      return _buildErrorState(commentsState.error!);
    }

    if (commentsState.comments.isEmpty) {
      return _buildEmptyState();
    }

    // Pagination des commentaires
    final totalComments = commentsState.comments.length;
    final commentsToShow = _currentPage * widget.commentsPerPage;
    final visibleComments =
        commentsState.comments.take(commentsToShow).toList();
    final hasMoreComments = totalComments > commentsToShow;

    return Column(
      children: [
        // Liste des commentaires visibles
        ...visibleComments.map((comment) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CommentItem(
                comment: comment,
                onDelete: () => _deleteComment(comment.id),
              ),
            )),

        // Pagination
        if (hasMoreComments) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _currentPage++;
                  });
                },
                icon: const Icon(
                  LucideIcons.chevronDown,
                  size: 16,
                  color: Color(0xFFE53E3E),
                ),
                label: Text(
                  'Afficher ${(totalComments - commentsToShow).clamp(0, widget.commentsPerPage)} commentaires suivants',
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 14,
                    color: Color(0xFFE53E3E),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],

        // Indicateur de pagination
        if (totalComments > widget.commentsPerPage) ...[
          const SizedBox(height: 8),
          Text(
            'Affichage de ${visibleComments.length} sur $totalComments commentaires',
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 12,
              color: Color(0xFF718096),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCommentsPreview(CommentsState commentsState) {
    if (commentsState.isLoading) {
      return _buildLoadingState();
    }

    if (commentsState.comments.isEmpty) {
      return const Text(
        'Aucun commentaire pour le moment',
        style: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 14,
          color: Color(0xFF718096),
        ),
      );
    }

    // Afficher les premiers commentaires en aperçu
    final previewComments =
        commentsState.comments.take(widget.initialCommentsToShow).toList();

    return Column(
      children: [
        ...previewComments.map((comment) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildCommentPreview(comment),
            )),
        if (commentsState.comments.length > widget.initialCommentsToShow) ...[
          const SizedBox(height: 8),
          Text(
            'et ${commentsState.comments.length - widget.initialCommentsToShow} autres commentaires...',
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 12,
              color: Color(0xFF718096),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCommentPreview(Comment comment) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showFullSection = true;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFFF4D03F),
              child: Text(
                (comment.authorName.isNotEmpty)
                    ? comment.authorName[0].toUpperCase()
                    : 'A',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    comment.authorName.isNotEmpty
                        ? comment.authorName
                        : 'Anonyme',
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    comment.content.length > 80
                        ? '${comment.content.substring(0, 80)}...'
                        : comment.content,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 12,
                      color: Color(0xFF4A5568),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              LucideIcons.chevronRight,
              size: 16,
              color: Color(0xFF718096),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF4D03F)),
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Icon(
            LucideIcons.alertCircle,
            size: 48,
            color: Color(0xFFE53E3E),
          ),
          const SizedBox(height: 12),
          Text(
            error,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 14,
              color: Color(0xFF4A5568),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _loadComments,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53E3E),
              foregroundColor: Colors.white,
            ),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            LucideIcons.messageCircle,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 12),
          const Text(
            'Aucun commentaire pour le moment',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 16,
              color: Color(0xFF718096),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Soyez le premier à partager votre avis !',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 14,
              color: Color(0xFF718096),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final success =
          await ref.read(commentsServiceProvider.notifier).addComment(
                widget.contentType,
                widget.contentId,
                _commentController.text.trim(),
              );

      if (success) {
        _commentController.clear();
        _commentFocusNode.unfocus();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Commentaire ajouté avec succès'),
              backgroundColor: Color(0xFF38A169),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors de l\'ajout du commentaire'),
              backgroundColor: Color(0xFFE53E3E),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (e.toString().contains('Authentification requise')) {
        _showAuthModal();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de l\'ajout du commentaire'),
            backgroundColor: Color(0xFFE53E3E),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _deleteComment(String commentId) async {
    try {
      final success = await ref
          .read(commentsServiceProvider.notifier)
          .deleteComment(widget.contentType, widget.contentId, commentId);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Commentaire supprimé'),
            backgroundColor: Color(0xFF38A169),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la suppression'),
            backgroundColor: Color(0xFFE53E3E),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
