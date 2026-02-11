import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:strife/models/authentication_model.dart';

class AuthenticationPage extends StatelessWidget {
  AuthenticationPage({super.key});

  final _formKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthenticationModel(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Войти',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
        body: Center(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  child: Column(
                    children: <Widget>[
                      const SizedBox(height: 8),
                      EmailTextForm(),
                      const SizedBox(height: 16),
                      PasswordTextForm(),
                      const SizedBox(height: 16),
                      LoginButton(formKey: _formKey),
                      const Divider(
                        height: 80,
                        indent: 20,
                        endIndent: 20,
                        thickness: 5,
                        radius: BorderRadius.horizontal(
                          left: Radius.circular(10),
                          right: Radius.circular(10),
                        ),
                      ),
                      LoginButtonWithGoogle(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class EmailTextForm extends StatelessWidget {
  const EmailTextForm({super.key});

  String? validatorEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'Пожалуйства введите почту';
    } else if (!RegExp(
      r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
    ).hasMatch(email)) {
      return 'Пожалуйства введите корректную почту';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.sizeOf(context).width * 0.9,
      child: TextFormField(
        keyboardType: TextInputType.emailAddress,
        validator: (value) => validatorEmail(value),
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Email',
        ),
        onChanged: (value) {
          context.read<AuthenticationModel>().setEmail(value);
        },
        autovalidateMode: AutovalidateMode.onUserInteraction,
        textInputAction: TextInputAction.next,
      ),
    );
  }
}

class LoginButton extends StatelessWidget {
  const LoginButton({super.key, required this.formKey});
  final GlobalKey<FormState> formKey;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: ButtonStyle(
        fixedSize: WidgetStatePropertyAll(
          Size(MediaQuery.sizeOf(context).width * 0.9, 50),
        ),
      ),
      onPressed: () async {
        if (formKey.currentState!.validate()) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const Center(child: CircularProgressIndicator()),
          );

          await context
              .read<AuthenticationModel>()
              .signInWithEmailAndPassword();

          if (!context.mounted) return;

          Navigator.of(context).pop();
          if (!context.read<AuthenticationModel>().isAuth) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Ошибка регестрации: ${context.read<AuthenticationModel>().error}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                width: MediaQuery.sizeOf(context).width * 0.9,
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                backgroundColor: Theme.of(context).colorScheme.onSecondaryFixed,
              ),
            );
          } else {
            Navigator.of(context).pop();
          }
        }
      },

      child: const Text('Войти', style: TextStyle(fontSize: 20)),
    );
  }
}

class PasswordTextForm extends StatelessWidget {
  const PasswordTextForm({super.key});

  String? validatorPassword(String? password) {
    if (password == null || password.length < 6) {
      return 'Пароль должен быть не менее 6 символов';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.sizeOf(context).width * 0.9,
      child: TextFormField(
        obscureText: true,
        onChanged: (value) {
          context.read<AuthenticationModel>().setPassword(value);
        },
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Password',
        ),
        validator: (value) => validatorPassword(value),
        autovalidateMode: AutovalidateMode.onUserInteraction,
      ),
    );
  }
}

class LoginButtonWithGoogle extends StatelessWidget {
  const LoginButtonWithGoogle({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ButtonStyle(
        fixedSize: WidgetStatePropertyAll(
          Size(MediaQuery.sizeOf(context).width * 0.9, 50),
        ),
      ),
      onPressed: () async {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );
        await context.read<AuthenticationModel>().signWithGoole();

        if (!context.mounted) return;

        Navigator.of(context).pop();

        if (context.read<AuthenticationModel>().isAuth) {
          Navigator.of(context).pop();
        } else if (context.read<AuthenticationModel>().error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Ошибка регестрации: ${context.read<AuthenticationModel>().error}',
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
              width: MediaQuery.sizeOf(context).width * 0.9,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              backgroundColor: Theme.of(context).colorScheme.onSecondaryFixed,
            ),
          );
        }
      },
      child: Row(
        children: [
          Image.asset('assets/images/google_logo.png', width: 24, height: 24),
          SizedBox(width: 16),
          Text('Войти с помощью Google', style: TextStyle(fontSize: 20)),
        ],
      ),
    );
  }
}
