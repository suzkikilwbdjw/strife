import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:strife/themes/gradient_theme.dart';

class AppNotifications {
  static void showError(BuildContext context, String message) {
    HapticFeedback.vibrate();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent, // Фон прозрачный
        content: Container(
          padding: const EdgeInsets.all(16),
          height: 80,
          decoration: BoxDecoration(
            gradient: Theme.of(
              context,
            ).extension<GradientTheme>()!.mainGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 30),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Ой, ошибка!",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
