import 'package:flutter/material.dart';

class ContactWidget extends StatelessWidget {
  const ContactWidget({super.key, required this.userData, this.trailing});

  final Map<String, dynamic> userData;

  final Widget? trailing;
  @override
  Widget build(BuildContext context) {
    final photoUrl = userData['photoUrl'] as String?;
    final displayName = userData['displayName'] as String?;
    final email = userData['email'] as String?;
    final isFavorite = userData['isFavorite'] ?? false;

    return ListTile(
      // Аватарка
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: Colors.grey.shade200,
        backgroundImage: photoUrl != null && photoUrl.isNotEmpty
            ? NetworkImage(photoUrl)
            : null,
        child: photoUrl == null || photoUrl.isEmpty
            ? const Icon(Icons.person, color: Colors.grey, size: 30)
            : null,
      ),

      // Отображаемое имя
      title: Row(
        children: [
          Text(
            displayName!,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),

          const SizedBox(width: 4),

          if (isFavorite) const Icon(Icons.star, color: Colors.amberAccent),
        ],
      ),

      trailing: trailing,

      // Адрес почты
      subtitle: email!.isNotEmpty
          ? Row(
              children: [
                // Иконка почты
                const Icon(
                  Icons.mail_outline_rounded,
                  size: 14,
                  color: Colors.black45,
                ),

                const SizedBox(width: 4),

                // Email
                Expanded(
                  child: Text(
                    email,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 12.0,
                    ),
                  ),
                ),
              ],
            )
          : null,
    );
  }
}
