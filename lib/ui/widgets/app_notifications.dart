import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppNotifications {
  static void _show({
    required String title,
    required String message,
    required IconData icon,
    required Color iconColor,
  }) {
    HapticFeedback.lightImpact();

    BotToast.showCustomNotification(
      duration: const Duration(seconds: 4),
      wrapAnimation: (controller, cancel, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
              .animate(
                CurvedAnimation(parent: controller, curve: Curves.easeOutCubic),
              ),
          child: child,
        );
      },
      toastBuilder: (cancelFunc) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.black.withValues(alpha: 0.06),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(icon, color: iconColor, size: 24),
                  const SizedBox(width: 12),

                  // Блок текста
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          message,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Тонкая серая кнопка закрытия
                  IconButton(
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.black26,
                      size: 18,
                    ),
                    onPressed: () => cancelFunc(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Ошибка
  static void showError(BuildContext context, String message) {
    _show(
      title: 'Ошибка',
      message: message,
      icon: Icons.error_outline_rounded,
      iconColor: const Color(0xFFD32F2F),
    );
  }

  // Успех
  static void showSuccess(BuildContext context, String message) {
    _show(
      title: 'Успешно',
      message: message,
      icon: Icons.check_circle_outline_rounded,
      iconColor: const Color(0xFF2E7D32),
    );
  }

  // Инфо / Нейтральное
  static void showInfo(BuildContext context, String message) {
    _show(
      title: 'Уведомление',
      message: message,
      icon: Icons.info_outline_rounded,
      iconColor: const Color(0xFFB91ED0),
    );
  }
}
