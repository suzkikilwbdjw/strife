import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:strife/models/registration_model.dart';

class RegistrationPage extends StatelessWidget {
  RegistrationPage({super.key});

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => RegistrationModel(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Зарегистрироваться',
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
                      const EmailTextForm(),
                      const SizedBox(height: 16),
                      const PasswordTextForm(),
                      const SizedBox(height: 16),
                      PasswordAgainTextForm(),
                      const SizedBox(height: 16),
                      RegisterButtonWithEmailAndPassowrd(formKey: _formKey),
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
                      RegisterButtonWithGoogle(),
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

class RegisterButtonWithGoogle extends StatelessWidget {
  const RegisterButtonWithGoogle({super.key});

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
        await context.read<RegistrationModel>().signWithGoole();

        if (!context.mounted) return;

        Navigator.of(context).pop();

        if (context.read<RegistrationModel>().isRegister) {
          Navigator.of(context).pop();
        } else if (context.read<RegistrationModel>().error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Ошибка регестрации: ${context.read<RegistrationModel>().error}',
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

class RegisterButtonWithEmailAndPassowrd extends StatelessWidget {
  const RegisterButtonWithEmailAndPassowrd({super.key, required this.formKey});
  final GlobalKey<FormState> formKey;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: () async {
        if (formKey.currentState!.validate()) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) =>
                const Center(child: CircularProgressIndicator()),
          );

          await context
              .read<RegistrationModel>()
              .registerWithEmailAndPassword();

          if (!context.mounted) return;

          Navigator.of(context).pop();

          if (!context.read<RegistrationModel>().isRegister) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Ошибка регестрации: ${context.read<RegistrationModel>().error}',
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
      style: ButtonStyle(
        fixedSize: WidgetStatePropertyAll(
          Size(MediaQuery.sizeOf(context).width * 0.9, 50),
        ),
      ),
      child: const Text('Зарегистрироваться', style: TextStyle(fontSize: 20)),
    );
  }
}

class PasswordAgainTextForm extends StatelessWidget {
  const PasswordAgainTextForm({super.key});

  String? validatePasswordAgain(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Пожалуйста подтвердите пароль';
    }
    if (value != password) {
      return 'Пароли не совпaдают';
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
          context.read<RegistrationModel>().setPasswordAgain(value);
        },
        validator: (value) => validatePasswordAgain(
          value,
          context.read<RegistrationModel>().password,
        ),
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Confirm Password',
        ),
        autovalidateMode: AutovalidateMode.onUserInteraction,
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
        textInputAction: TextInputAction.next,
        obscureText: true,
        onChanged: (value) {
          context.read<RegistrationModel>().setPassword(value);
        },
        validator: (value) => validatorPassword(value),
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Password',
        ),
        autovalidateMode: AutovalidateMode.onUserInteraction,
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
      return 'Пожалуйства введите коректную почту';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.sizeOf(context).width * 0.9,
      child: TextFormField(
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        validator: (value) => validatorEmail(value),
        onChanged: (value) {
          context.read<RegistrationModel>().setEmail(value);
        },
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Email',
        ),
        autovalidateMode: AutovalidateMode.onUserInteraction,
      ),
    );
  }
}
