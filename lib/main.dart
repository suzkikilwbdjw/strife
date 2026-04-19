import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:strife/data/repositories/chat_repository.dart';
import 'package:strife/data/repositories/user_repository.dart';
import 'package:strife/data/repositories/vcs_repository.dart';

// Импорты слоев
import 'package:strife/firebase/firebase_options.dart';
import 'package:strife/presentation/blocs/chats/chat_bloc.dart';
import 'package:strife/presentation/blocs/vcs/vcs_bloc.dart';
import 'package:strife/presentation/blocs/contacts/contacts_bloc.dart';
import 'package:strife/themes/gradient_theme.dart';
import 'package:strife/data/repositories/auth_repository.dart';
import 'package:strife/ui/view_models/auth_view_model.dart';

// Импорты экранов
import 'package:strife/ui/views/login/login_view.dart';
import 'package:strife/ui/views/home/home_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        Provider(create: (_) => AuthRepository()),
        Provider(create: (_) => ChatRepository()),
        Provider(create: (_) => UserRepository()),
        Provider(create: (_) => VCSRepository()),

        // ViewModels
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => VCSBloc(context.read<VCSRepository>()),
          ),
          BlocProvider(
            create: (context) => ContactsBloc(context.read<UserRepository>()),
          ),
          BlocProvider(
            create: (context) => ChatBloc(
              chatRepository: context.read<ChatRepository>(),
              userRepository: context.read<UserRepository>(),
            ),
          ),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        extensions: const [
          GradientTheme(
            mainGradient: LinearGradient(
              colors: [Color(0xFFB91ED0), Color(0xFF5E0F6A)],
            ),
          ),
        ],
        brightness: Brightness.light,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData) {
            return const HomeView(); // Пользователь залогинен
          }

          return LoginView(); // Пользователь не залогинен
        },
      ),
    );
  }
}
