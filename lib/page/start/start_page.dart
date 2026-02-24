import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:strife/models/authentication_model.dart';
import 'package:strife/page/register/registration_page.dart';
import 'package:strife/themes/gradient_theme.dart';
import 'package:provider/provider.dart';

class StartPage extends StatelessWidget {
  StartPage({super.key});
  final _formKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AuthenticationModel(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          toolbarHeight: 100,
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Strife',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 36,
                ),
                textAlign: TextAlign.right,
              ),
              Text(
                'Видеоконференции',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
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

        resizeToAvoidBottomInset: true,

        body: Form(
          key: _formKey,
          child: Container(
            decoration: BoxDecoration(
              gradient: Theme.of(
                context,
              ).extension<GradientTheme>()!.mainGradient,
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,

                  children: <Widget>[
                    const Text(
                      'Добро пожаловать!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 36,
                      ),
                    ),

                    const SizedBox(height: 80),
                    EmailTextForm(),
                    const SizedBox(height: 24),
                    PasswordTextForm(),
                    const SizedBox(height: 24),
                    LoginButton(formKey: _formKey),
                    const SizedBox(height: 16),

                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 20,
                          color: Color(0xFF999393),
                        ),
                        children: [
                          const TextSpan(text: 'Нет аккаунта?'),
                          TextSpan(
                            text: ' Зарегестрироваться',
                            style: TextStyle(
                              color: Color.fromARGB(255, 28, 91, 239),
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => RegistrationPage(),
                                  ),
                                );
                              },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 150),

                    const Text(
                      'или войти с помощью',
                      style: TextStyle(
                        fontWeight: FontWeight.normal,
                        color: Color(0xFF999393),
                        fontSize: 24,
                      ),
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset('assets/images/mail_logo.png'),
                        SizedBox(width: 32),
                        Image.asset('assets/images/yandex_logo.png'),
                        SizedBox(width: 32),
                        Image.asset('assets/images/vk_logo.png'),
                      ],
                    ),

                    const SizedBox(height: 50),
                  ],
                ),
              ),
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
      return 'Пожалуйста введите почту';
    } else if (!RegExp(
      r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
    ).hasMatch(email)) {
      return 'Пожалуйста введите корректную почту';
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
          filled: true,
          fillColor: Color(0xFFD9D9D9).withValues(alpha: 0.4),
          border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.all(Radius.circular(25)),
          ),
          hintText: 'Почта...',
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
        backgroundColor: WidgetStatePropertyAll(
          Color(0xFFFEFEFE).withValues(alpha: 0.7),
        ),
        fixedSize: WidgetStatePropertyAll(
          Size(MediaQuery.sizeOf(context).width * 0.7, 60),
        ),
      ),
      onPressed: () async {
        if (formKey.currentState!.validate()) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) =>
                const Center(child: CircularProgressIndicator()),
          );

          await context
              .read<AuthenticationModel>()
              .signInWithEmailAndPassword();

          if (!context.mounted) return;

          Navigator.of(context).pop();

          Navigator.of(context).focusNode.unfocus();

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
          }
        }
      },

      child: const Text(
        'Войти в аккаунт',
        style: TextStyle(fontSize: 16, color: Colors.black),
      ),
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
          filled: true,
          fillColor: Color(0xFFD9D9D9).withValues(alpha: 0.4),
          border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.all(Radius.circular(25)),
          ),
          hintText: 'Пароль...',
        ),
        validator: (value) => validatorPassword(value),
        autovalidateMode: AutovalidateMode.onUserInteraction,
      ),
    );
  }
}
