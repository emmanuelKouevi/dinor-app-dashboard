/**
 * AUTH_MODAL.DART - CONVERSION FIDÈLE DE AuthModal.vue
 * 
 * FIDÉLITÉ VISUELLE :
 * - Modal bottom sheet identique
 * - Formulaires login/register identiques
 * - Validation et messages d'erreur identiques
 * - Animation et transitions identiques
 * 
 * FIDÉLITÉ FONCTIONNELLE :
 * - Logique d'authentification identique
 * - Gestion d'état identique
 * - API calls identiques via AuthStore
 */

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../composables/use_auth_handler.dart';

class AuthModal extends ConsumerStatefulWidget {
  final bool isOpen;
  final VoidCallback? onClose;
  final VoidCallback? onAuthenticated;

  const AuthModal({
    Key? key,
    required this.isOpen,
    this.onClose,
    this.onAuthenticated,
  }) : super(key: key);

  @override
  ConsumerState<AuthModal> createState() => _AuthModalState();
}

class _AuthModalState extends ConsumerState<AuthModal> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordConfirmationController = TextEditingController();
  
  bool _isLogin = true;
  bool _isLoading = false;
  bool _rememberMe = true;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _passwordConfirmationController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      _error = null;
    });
  }

  Future<void> _submitForm() async {
    print('🔐 [AuthModal] _submitForm appelé - Mode: ${_isLogin ? "Connexion" : "Inscription"}');
    
    if (!_formKey.currentState!.validate()) {
      print('❌ [AuthModal] Validation du formulaire échouée');
      return;
    }

    print('🔐 [AuthModal] Validation réussie, début du processus d\'authentification');
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('🔐 [AuthModal] Récupération du provider d\'authentification');
      final authHandler = ref.read(useAuthHandlerProvider.notifier);
      bool success;

      if (_isLogin) {
        print('🔐 [AuthModal] Tentative de connexion pour: ${_emailController.text.trim()}');
        success = await authHandler.login(
          _emailController.text.trim(),
          _passwordController.text,
          rememberMe: _rememberMe,
        );
        print('🔐 [AuthModal] Résultat connexion: $success');
      } else {
        print('🔐 [AuthModal] Tentative d\'inscription pour: ${_emailController.text.trim()}');
        success = await authHandler.register(
          _nameController.text.trim(),
          _emailController.text.trim(),
          _passwordController.text,
          _passwordConfirmationController.text,
        );
        print('🔐 [AuthModal] Résultat inscription: $success');
      }

      if (success) {
        print('✅ [AuthModal] Authentification réussie, fermeture de la modal');
        
        // Afficher un message de succès
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isLogin ? 'Connexion réussie !' : 'Compte créé avec succès !'),
            duration: const Duration(seconds: 2),
            backgroundColor: const Color(0xFF38A169),
          ),
        );
        
        // Appeler les callbacks dans le bon ordre
        widget.onAuthenticated?.call();
        
        // Fermer la modal avec un délai pour permettre l'animation
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            widget.onClose?.call();
          }
        });
      } else {
        print('❌ [AuthModal] Authentification échouée');
        setState(() {
          _error = _isLogin 
            ? 'Connexion échouée. Vérifiez vos identifiants et votre connexion internet.'
            : 'Inscription échouée. Vérifiez les informations saisies et votre connexion internet.';
        });
      }
    } catch (error) {
      print('❌ [AuthModal] Exception lors de l\'authentification: $error');
      setState(() {
        _error = 'Erreur de connexion au serveur. Vérifiez votre connexion internet et réessayez.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _continueAsGuest() async {
    print('👤 [AuthModal] _continueAsGuest appelé');
    
    try {
      print('👤 [AuthModal] Récupération du provider d\'authentification');
      final authHandler = ref.read(useAuthHandlerProvider.notifier);
      
      print('👤 [AuthModal] Tentative de connexion en tant qu\'invité');
      await authHandler.loginAsGuest();
      
      print('✅ [AuthModal] Connexion invité réussie, fermeture de la modal');
      widget.onAuthenticated?.call();
      
      // Fermer la modal avec un délai pour permettre l'animation
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          widget.onClose?.call();
        }
      });
    } catch (error) {
      print('❌ [AuthModal] Erreur connexion invité: $error');
      setState(() {
        _error = 'Erreur lors de la connexion invité';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🔐 [AuthModal] build appelé - isOpen: ${widget.isOpen}');
    if (!widget.isOpen) {
      print('🔐 [AuthModal] Modal fermée, retour SizedBox.shrink()');
      return const SizedBox.shrink();
    }
    
    print('🔐 [AuthModal] Rendu de la modal d\'authentification');

    final viewInsetsBottom = MediaQuery.of(context).viewInsets.bottom;

    InputDecoration _inputDecoration({required String label, IconData? icon}) {
      return InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, color: const Color(0xFF718096)) : null,
        filled: true,
        fillColor: const Color(0xFFF7FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE53E3E), width: 1.5),
        ),
      );
    }

    return PopScope(
      canPop: false,
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: viewInsetsBottom),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF5F5),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.lock_outline,
                            color: Color(0xFFE53E3E),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isLogin ? 'Connexion' : 'Inscription',
                                style: const TextStyle(
                                  fontFamily: 'OpenSans',
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2D3748),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _isLogin
                                    ? 'Accède à ton compte Dinor'
                                    : 'Crée ton compte en quelques secondes',
                                style: const TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 13,
                                  color: Color(0xFF718096),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: widget.onClose,
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Error Message
                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red[200]!),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _error!,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Form Fields
                    if (!_isLogin) ...[
                      TextFormField(
                        controller: _nameController,
                        decoration: _inputDecoration(label: 'Nom complet', icon: Icons.person_outline),
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Le nom est requis';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    TextFormField(
                      controller: _emailController,
                      decoration: _inputDecoration(label: 'Email', icon: Icons.email_outlined),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'L\'email est requis';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'Email invalide';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _passwordController,
                      decoration: _inputDecoration(label: 'Mot de passe', icon: Icons.lock_outline),
                      obscureText: true,
                      textInputAction: _isLogin ? TextInputAction.done : TextInputAction.next,
                      onFieldSubmitted: (_) {
                        if (_isLogin && !_isLoading) {
                          _submitForm();
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Le mot de passe est requis';
                        }
                        if (!_isLogin && value.length < 8) {
                          return 'Le mot de passe doit contenir au moins 8 caractères';
                        }
                        return null;
                      },
                    ),

                    if (!_isLogin) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordConfirmationController,
                        decoration: _inputDecoration(label: 'Confirmer le mot de passe', icon: Icons.lock_outline),
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) {
                          if (!_isLoading) {
                            _submitForm();
                          }
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'La confirmation est requise';
                          }
                          if (value != _passwordController.text) {
                            return 'Les mots de passe ne correspondent pas';
                          }
                          return null;
                        },
                      ),
                    ],

                    // Remember Me checkbox (only for login)
                    if (_isLogin) ...[
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        title: const Text(
                          'Se souvenir de moi',
                          style: TextStyle(
                            fontFamily: 'OpenSans',
                            fontSize: 14,
                            color: Color(0xFF4A5568),
                          ),
                        ),
                        value: _rememberMe,
                        onChanged: (bool? value) {
                          setState(() {
                            _rememberMe = value ?? true;
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        activeColor: const Color(0xFFE53E3E),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Submit Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE53E3E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _isLogin ? 'Se connecter' : 'S\'inscrire',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),

                    const SizedBox(height: 14),

                    // Toggle Mode
                    TextButton(
                      onPressed: _isLoading ? null : _toggleMode,
                      child: Text(
                        _isLogin
                            ? 'Pas encore de compte ? S\'inscrire'
                            : 'Déjà un compte ? Se connecter',
                        style: const TextStyle(
                          color: Color(0xFFE53E3E),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Guest Login
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isLoading
                            ? null
                            : () {
                                print('👤 [AuthModal] Bouton "Continuer en tant qu\'invité" appuyé');
                                _continueAsGuest();
                              },
                        icon: const Icon(Icons.person_outline),
                        label: const Text('Continuer en tant qu\'invité'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF4A5568),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}