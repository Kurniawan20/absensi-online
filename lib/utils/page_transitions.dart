import 'package:flutter/material.dart';

/// Custom page transitions for smooth navigation
class AppPageTransitions {
  /// Fade transition
  static PageRouteBuilder<T> fade<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  /// Slide from right transition
  static PageRouteBuilder<T> slideRight<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;

        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);

        return SlideTransition(position: offsetAnimation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  /// Slide from bottom transition
  static PageRouteBuilder<T> slideUp<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;

        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);

        return SlideTransition(position: offsetAnimation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 350),
    );
  }

  /// Scale transition (zoom in)
  static PageRouteBuilder<T> scale<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const curve = Curves.easeOutBack;
        var curvedAnimation = CurvedAnimation(parent: animation, curve: curve);

        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(curvedAnimation),
          child: FadeTransition(opacity: curvedAnimation, child: child),
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }

  /// Combined slide and fade transition
  static PageRouteBuilder<T> slideAndFade<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const curve = Curves.easeInOutCubic;
        var curvedAnimation = CurvedAnimation(parent: animation, curve: curve);

        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.1, 0.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: FadeTransition(opacity: curvedAnimation, child: child),
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}

/// Extension to easily navigate with transitions
extension NavigatorTransitions on NavigatorState {
  Future<T?> pushWithTransition<T>(Widget page,
      {TransitionType type = TransitionType.slideRight}) {
    switch (type) {
      case TransitionType.fade:
        return push(AppPageTransitions.fade(page));
      case TransitionType.slideRight:
        return push(AppPageTransitions.slideRight(page));
      case TransitionType.slideUp:
        return push(AppPageTransitions.slideUp(page));
      case TransitionType.scale:
        return push(AppPageTransitions.scale(page));
      case TransitionType.slideAndFade:
        return push(AppPageTransitions.slideAndFade(page));
    }
  }

  Future<T?> pushReplacementWithTransition<T>(Widget page,
      {TransitionType type = TransitionType.slideRight}) {
    switch (type) {
      case TransitionType.fade:
        return pushReplacement(AppPageTransitions.fade(page));
      case TransitionType.slideRight:
        return pushReplacement(AppPageTransitions.slideRight(page));
      case TransitionType.slideUp:
        return pushReplacement(AppPageTransitions.slideUp(page));
      case TransitionType.scale:
        return pushReplacement(AppPageTransitions.scale(page));
      case TransitionType.slideAndFade:
        return pushReplacement(AppPageTransitions.slideAndFade(page));
    }
  }
}

enum TransitionType {
  fade,
  slideRight,
  slideUp,
  scale,
  slideAndFade,
}
