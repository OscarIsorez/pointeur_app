import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:pointeur_app/theme/app_colors.dart';

class AnimatedSaveButton extends StatefulWidget {
  final VoidCallback onPressed;
  final bool isLoading;

  const AnimatedSaveButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  State<AnimatedSaveButton> createState() => _AnimatedSaveButtonState();
}

class _AnimatedSaveButtonState extends State<AnimatedSaveButton>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _iconOpacityAnimation;
  late Animation<double> _textOpacityAnimation;
  late Animation<double> _borderRadiusAnimation;
  late Animation<double> _widthAnimation;
  late Animation<double> _rotationAnimation;

  bool _showSuccess = false;

  @override
  void initState() {
    super.initState();

    // Animation principale pour le changement texte -> icône
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Animation pour l'effet de pression
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    // Animation d'échelle pour l'effet de validation
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 0.7, curve: Curves.elasticOut),
      ),
    );

    // Animation de transformation rectangle -> cercle
    _borderRadiusAnimation = Tween<double>(begin: 16.0, end: 30.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
      ),
    );

    // Animation de la largeur pour former un cercle
    _widthAnimation = Tween<double>(begin: 1.0, end: 60.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
      ),
    );

    // Animation de rotation de l'icône
    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
      ),
    );

    // Opacité de l'icône (apparition)
    _iconOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 0.8, curve: Curves.easeIn),
      ),
    );

    // Opacité du texte (disparition)
    _textOpacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pressController.dispose();
    super.dispose();
  }

  void _handlePress() async {
    if (widget.isLoading || _showSuccess) return;

    // Animation de pression
    await _pressController.forward();
    await _pressController.reverse();

    // Démarrer l'animation de transformation
    _animationController.forward();

    // Attendre un peu avant d'appeler onPressed
    await Future.delayed(const Duration(milliseconds: 200));
    widget.onPressed();

    // Marquer comme succès et reset après un délai
    setState(() {
      _showSuccess = true;
    });

    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted) {
      _animationController.reverse();
      setState(() {
        _showSuccess = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _animationController,
                _pressController,
              ]),
              builder: (context, child) {
                return Transform.scale(
                  scale:
                      _showSuccess
                          ? 1.0 + (_scaleAnimation.value * 0.1)
                          : 1.0 - (_pressController.value * 0.05),
                  child: AnimatedBuilder(
                    animation: _borderRadiusAnimation,
                    builder: (context, child) {
                      return Center(
                        child: AnimatedBuilder(
                          animation: _widthAnimation,
                          builder: (context, child) {
                            return Container(
                              width:
                                  _widthAnimation.value == 1.0
                                      ? double.infinity
                                      : _widthAnimation.value,
                              height: 60,
                              decoration: BoxDecoration(
                                color:
                                    _showSuccess
                                        ? Colors.green.withValues(alpha: 0.4)
                                        : Colors.white.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(
                                  _borderRadiusAnimation.value,
                                ),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _handlePress,
                                  borderRadius: BorderRadius.circular(
                                    _borderRadiusAnimation.value,
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(
                                        _borderRadiusAnimation.value,
                                      ),
                                    ),
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        // Texte "Sauvegarder"
                                        AnimatedBuilder(
                                          animation: _textOpacityAnimation,
                                          builder: (context, child) {
                                            return Opacity(
                                              opacity:
                                                  _textOpacityAnimation.value,
                                              child: Text(
                                                'Sauvegarder',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color:
                                                      _showSuccess
                                                          ? Colors.white
                                                          : AppColors.textLight,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                        // Icône de validation avec rotation
                                        AnimatedBuilder(
                                          animation: _iconOpacityAnimation,
                                          builder: (context, child) {
                                            return Opacity(
                                              opacity:
                                                  _iconOpacityAnimation.value,
                                              child: AnimatedBuilder(
                                                animation: _rotationAnimation,
                                                builder: (context, child) {
                                                  return Transform.rotate(
                                                    angle:
                                                        _rotationAnimation
                                                            .value *
                                                        2 *
                                                        3.14159, // 360 degrés
                                                    child: Transform.scale(
                                                      scale:
                                                          _scaleAnimation.value,
                                                      child: Icon(
                                                        Icons.check,
                                                        size: 28,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            );
                                          },
                                        ),
                                        // Indicateur de chargement
                                        if (widget.isLoading)
                                          SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    AppColors.primaryTeal,
                                                  ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
