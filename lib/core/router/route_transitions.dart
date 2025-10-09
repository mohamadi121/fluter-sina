import 'package:flutter/material.dart';

/// Advanced Route Transitions for Smart Home App
class AppRouteTransitions {
  AppRouteTransitions._();

  /// Slide transition from bottom
  static Widget slideFromBottom(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    const begin = Offset(0.0, 1.0);
    const end = Offset.zero;
    const curve = Curves.easeInOutCubic;

    final tween = Tween(begin: begin, end: end).chain(
      CurveTween(curve: curve),
    );

    return SlideTransition(
      position: animation.drive(tween),
      child: child,
    );
  }

  /// Slide transition from right
  static Widget slideFromRight(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    const begin = Offset(1.0, 0.0);
    const end = Offset.zero;
    const curve = Curves.easeInOutCubic;

    final tween = Tween(begin: begin, end: end).chain(
      CurveTween(curve: curve),
    );

    return SlideTransition(
      position: animation.drive(tween),
      child: child,
    );
  }

  /// Slide transition from left
  static Widget slideFromLeft(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    const begin = Offset(-1.0, 0.0);
    const end = Offset.zero;
    const curve = Curves.easeInOutCubic;

    final tween = Tween(begin: begin, end: end).chain(
      CurveTween(curve: curve),
    );

    return SlideTransition(
      position: animation.drive(tween),
      child: child,
    );
  }

  /// Fade in transition
  static Widget fadeIn(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }

  /// Scale transition
  static Widget scaleTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    const curve = Curves.easeInOutBack;
    final tween = Tween(begin: 0.0, end: 1.0).chain(
      CurveTween(curve: curve),
    );

    return ScaleTransition(
      scale: animation.drive(tween),
      child: child,
    );
  }

  /// Rotation transition
  static Widget rotationTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return RotationTransition(
      turns: animation,
      child: child,
    );
  }

  /// Size transition
  static Widget sizeTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SizeTransition(
      sizeFactor: animation,
      child: child,
    );
  }

  /// Custom bounce transition
  static Widget bounceTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    const curve = Curves.elasticOut;
    final tween = Tween(begin: 0.0, end: 1.0).chain(
      CurveTween(curve: curve),
    );

    return ScaleTransition(
      scale: animation.drive(tween),
      child: child,
    );
  }

  /// Flip transition
  static Widget flipTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        if (animation.value < 0.5) {
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(animation.value * 3.14159),
            child: child,
          );
        } else {
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY((1 - animation.value) * 3.14159),
            child: child,
          );
        }
      },
      child: child,
    );
  }

  /// Slide and fade transition
  static Widget slideAndFade(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    const begin = Offset(0.0, 0.3);
    const end = Offset.zero;
    const curve = Curves.easeOut;

    final slideTween = Tween(begin: begin, end: end).chain(
      CurveTween(curve: curve),
    );

    return SlideTransition(
      position: animation.drive(slideTween),
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }

  /// Morph transition for dashboard
  static Widget morphTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return ScaleTransition(
      scale: Tween<double>(
        begin: 0.8,
        end: 1.0,
      ).animate(
        CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOutQuart,
        ),
      ),
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }
}