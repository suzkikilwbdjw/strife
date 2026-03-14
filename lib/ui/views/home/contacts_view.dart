import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:strife/themes/gradient_theme.dart';

class ContactsView extends StatelessWidget {
  const ContactsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 130,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Контакты',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 24,
              ),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFD9D9D9).withValues(alpha: 0.4),
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.all(Radius.circular(25)),
                ),
                hintText: 'Поиск контактов...',
                hintStyle: TextStyle(color: Color(0xFFD3C9C9)),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: Theme.of(
              context,
            ).extension<GradientTheme>()!.mainGradient,
          ),
        ),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .collection('contacts')
            .snapshots(),
        builder: (context, snapshot) {
          // Если произошла ошибка
          if (snapshot.hasError) {
            return const Center(child: Text('Произошла ошибка'));
          }

          // Если данные грузятся
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          // Если список контактов пуст
          if (docs.isEmpty) {
            return const Center(child: Text('Список контактов пуст'));
          }

          // Отрисовка списка
          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (context, index) => const Divider(
              height: 1,
              thickness: 0.5,
              indent: 75,
              endIndent: 16,
              color: Colors.white24,
            ),
            itemBuilder: (context, index) {
              return ContactWidget(contactId: docs[index].id);
            },
          );
        },
      ),
    );
  }
}

class ContactWidget extends StatelessWidget {
  const ContactWidget({super.key, required this.contactId});
  final String contactId;
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      // Идем в главную коллекцию пользователей за деталями
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(contactId)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const ListTile(title: Text("Загрузка..."));
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;

        return ListTile(
          leading: CircleAvatar(
            backgroundImage: NetworkImage(data['photoUrl'] ?? ''),
            radius: 30,
          ),
          title: Text(data['displayName'] ?? 'Без имени'),
          subtitle: Text(data['email'] ?? ''),
        );
      },
    );
  }
}
