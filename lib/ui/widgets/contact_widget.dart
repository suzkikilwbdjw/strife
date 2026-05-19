import 'package:firebase_database/firebase_database.dart';
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
      contentPadding: EdgeInsets.zero,
      tileColor: Colors.transparent,
      // Аватарка
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                ? NetworkImage(photoUrl)
                : null,
            child: photoUrl == null || photoUrl.isEmpty
                ? const Icon(Icons.person, color: Colors.grey, size: 30)
                : null,
          ),
          Positioned(
            right: 1.0,
            bottom: 1.0,
            child:
                // Статус - онлайн/офлайн
                StreamBuilder<DatabaseEvent>(
                  stream: FirebaseDatabase.instance
                      .ref('status/${userData['id']}')
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
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: isOnline ? Colors.green : Colors.grey,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                    );
                  },
                ),
          ),
        ],
      ),

      title: Row(
        children: [
          // Отображаемое имя
          Expanded(
            child: Text(
              displayName!,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),

          const SizedBox(width: 4),
          // Звезда
          if (isFavorite)
            const Icon(Icons.star, color: Colors.amberAccent, size: 15.0),
        ],
      ),

      trailing: trailing,

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
                      fontSize: 11.0,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            )
          : null,
    );
  }
}
