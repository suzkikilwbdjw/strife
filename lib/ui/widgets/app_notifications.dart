import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:strife/themes/gradient_theme.dart';

class AppNotifications {
  // Общий метод для построения уведомления
  static void _show(
    BuildContext context, {
    required String title,
    required String message,
    required IconData icon,
    required Gradient gradient,
  }) {
    HapticFeedback.lightImpact();

    final messenger = ScaffoldMessenger.of(context);

    messenger.showSnackBar(
      SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          height: 80,
          decoration: BoxDecoration(
            gradient: gradient,
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
              Icon(icon, color: Colors.white, size: 30),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
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
                onPressed: () => messenger.hideCurrentSnackBar(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Метод для ошибки
  static void showError(BuildContext context, String message) {
    _show(
      context,
      title: 'Ой, ошибка!',
      message: message,
      icon: Icons.error_outline,
      gradient: Theme.of(context).extension<GradientTheme>()!.mainGradient,
    );
  }

  // Метод для успеха
  static void showSuccess(BuildContext context, String message) {
    _show(
      context,
      title: 'Успешно!',
      message: message,
      icon: Icons.check_circle_outline,
      gradient: const LinearGradient(
        colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
      ),
    );
  }

  // Метод для нейтрального вывода
  static void showInfo(BuildContext context, String message) {
    _show(
      context,
      title: 'Четко',
      message: message,
      icon: Icons.info_outline,
      gradient: const LinearGradient(
        colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
      ),
    );
  }
}
