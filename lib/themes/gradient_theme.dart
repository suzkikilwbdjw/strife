import 'package:flutter/material.dart';

class GradientTheme extends ThemeExtension<GradientTheme> {
  final Gradient mainGradient;

  const GradientTheme({required this.mainGradient});

  @override
  GradientTheme copyWith({Gradient? mainGradient}) {
    return GradientTheme(mainGradient: mainGradient ?? this.mainGradient);
  }

  @override
  GradientTheme lerp(ThemeExtension<GradientTheme>? other, double t) {
    if (other is! GradientTheme) return this;
    return this;
  }
}
