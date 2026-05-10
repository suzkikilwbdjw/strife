import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:strife/data/repositories/user_repository.dart';
import 'package:strife/themes/gradient_theme.dart';
import 'package:strife/ui/view_models/auth_view_model.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: context.read<UserRepository>().userStream,
        builder: (context, snapshot) {
          // Пока данные загружаются
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Если есть ошибка или нет пользователя
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Ошибка загрузки профиля'));
          }

          final user = snapshot.data!;
          return Column(
            children: [
              // Верхняя часть с градиентом и аватаром
              Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // Заливка сверху
                  Container(
                    height: 170,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: Theme.of(
                        context,
                      ).extension<GradientTheme>()!.mainGradient,
                    ),
                    padding: const EdgeInsets.only(left: 20, top: 60),
                    child: const Text(
                      'Профиль',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -50,
                    child: Stack(
                      children: [
                        // Аватарка
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 56,
                            backgroundImage:
                                user.photoURL != null &&
                                    user.photoURL!.isNotEmpty
                                ? NetworkImage(user.photoURL!)
                                : NetworkImage('f'),
                            child:
                                user.photoURL == null || user.photoURL!.isEmpty
                                ? Text(
                                    user.displayName?.isNotEmpty == true
                                        ? user.displayName![0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        // Индикатор статуса
                        Positioned(
                          bottom: 5,
                          right: 5,
                          child: StreamBuilder<DatabaseEvent>(
                            stream: FirebaseDatabase.instance
                                .ref('status/${user.uid}')
                                .onValue,
                            builder: (context, snapshot) {
                              bool isOnline = false;
                              if (snapshot.hasData &&
                                  snapshot.data!.snapshot.value != null) {
                                final data = Map<String, dynamic>.from(
                                  snapshot.data!.snapshot.value as Map,
                                );
                                isOnline = data['state'] == 'online';
                              }

                              return Container(
                                width: 25,
                                height: 25,
                                decoration: BoxDecoration(
                                  color: isOnline ? Colors.green : Colors.grey,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 60),

              // Имя пользователя
              Text(
                user.displayName ?? 'Anonymous',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              // Статус пользователя
              StreamBuilder(
                stream: FirebaseDatabase.instance
                    .ref('status/${user.uid}')
                    .onValue,
                builder: (context, snapshot) {
                  final data = snapshot.data?.snapshot.value as Map?;
                  final status = data?['state'] ?? 'offline';
                  return Text(
                    status == 'online' ? 'Online' : 'Offline',
                    style: TextStyle(
                      color: status == 'online' ? Colors.green : Colors.grey,
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // Список настроек
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildSectionTitle('Security & Settings'),
                    _buildMenuItem('Изменить имя пользователя'),
                    _buildMenuItem('Сменить пароль', icon: Icons.lock_outline),
                    _buildMenuItem(
                      'Уведомления',
                      icon: Icons.notifications_none,
                      trailing: Switch(
                        value: false,
                        onChanged: (_) {},
                        activeThumbColor: Colors.purple,
                      ),
                    ),
                    _buildMenuItem(
                      'Выйти из аккаунта...',
                      isLast: true,
                      onTap: () async {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) =>
                              const Center(child: CircularProgressIndicator()),
                        );

                        await context.read<AuthViewModel>().signOut();

                        if (!context.mounted) return;
                        Navigator.of(context).pop();
                      },
                    ),

                    _buildSectionTitle('App Details'),
                    _buildMenuItem(
                      'Версия приложения',
                      trailing: const Text('1.0'),
                    ),
                    _buildMenuItem(
                      'Поддержка',
                      trailing: const Text(
                        'ggbb1234554321@gmail.com',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Вспомогательный виджет для заголовков секций
  Widget _buildSectionTitle(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.grey.shade50,
      child: Text(
        title,
        style: TextStyle(
          color: Colors.grey.shade700,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
      ),
    );
  }

  // Вспомогательный виджет для пунктов меню
  Widget _buildMenuItem(
    String title, {
    IconData? icon,
    Widget? trailing,
    bool isLast = false,
    VoidCallback? onTap,
  }) {
    return Column(
      children: [
        ListTile(
          leading: icon != null ? Icon(icon, color: Colors.black) : null,
          title: Text(title, style: const TextStyle(fontSize: 16)),
          trailing: trailing,
          onTap: onTap,
        ),
        if (!isLast) const Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }
}
