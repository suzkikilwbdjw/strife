import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:provider/provider.dart';
import 'package:strife/models/registration_model.dart';
import 'package:strife/themes/gradient_theme.dart';

class RegistrationPage extends StatelessWidget {
  RegistrationPage({super.key});

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => RegistrationModel(),
      child: Scaffold(
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

        body: Container(
          decoration: BoxDecoration(
            gradient: Theme.of(
              context,
            ).extension<GradientTheme>()!.mainGradient,
          ),
          child: SafeArea(
            child: Center(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Expanded(
                      child: Text(
                        'Добро пожаловать!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 36,
                        ),
                      ),
                    ),

                    const Row(
                      children: <Widget>[
                        SizedBox(width: 20),
                        Expanded(child: NameTextForm()),
                        SizedBox(width: 20),
                        Expanded(child: SecondNameTextForm()),
                        SizedBox(width: 20),
                      ],
                    ),

                    const SizedBox(height: 20),

                    const EmailTextForm(),

                    const SizedBox(height: 20),

                    const DateOfBirthTextForm(),

                    const SizedBox(height: 20),

                    const PhoneNumberTextForm(),

                    const PasswordTextForm(),

                    const SizedBox(height: 20),

                    PasswordAgainTextForm(),

                    const SizedBox(height: 20),

                    RegisterButtonWithEmailAndPassowrd(formKey: _formKey),

                    const SizedBox(height: 20),
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

class PhoneNumberTextForm extends StatelessWidget {
  const PhoneNumberTextForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Номер телефона',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),

        const SizedBox(height: 6),

        SizedBox(
          width: MediaQuery.sizeOf(context).width * 0.9,
          child: IntlPhoneField(
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
            initialCountryCode: 'RU',
            onChanged: (phoneNumber) {},
          ),
        ),
      ],
    );
  }
}

class DateOfBirthTextForm extends StatelessWidget {
  const DateOfBirthTextForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Дата рождения',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),

        const SizedBox(height: 6),

        SizedBox(
          width: MediaQuery.sizeOf(context).width * 0.9,
          child: TextFormField(
            readOnly: true,

            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              suffixIcon: Icon(Icons.calendar_today),
            ),

            onTap: () async {
              final dateOfBirth = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(1900),
                lastDate: DateTime(2100),
              );

              if (!context.mounted) return;

              context.read<RegistrationModel>().setDateOfBirth(dateOfBirth!);
            },
          ),
        ),
      ],
    );
  }
}

class NameTextForm extends StatelessWidget {
  const NameTextForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text('Имя', style: TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 6),
        SizedBox(
          width: MediaQuery.sizeOf(context).width * 0.45,
          child: TextFormField(
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class SecondNameTextForm extends StatelessWidget {
  const SecondNameTextForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Фамилия',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),

        const SizedBox(height: 6),

        SizedBox(
          width: MediaQuery.sizeOf(context).width * 0.45,

          child: TextFormField(
            textInputAction: TextInputAction.next,

            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,

              border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
            ),
          ),
        ),
      ],
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
          Size(MediaQuery.sizeOf(context).width * 0.7, 60),
        ),
      ),
      child: const Text('Создать аккаунт', style: TextStyle(fontSize: 16)),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Подтвердите пароль',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),

        const SizedBox(height: 6),

        SizedBox(
          width: MediaQuery.sizeOf(context).width * 0.9,
          child: TextFormField(
            obscureText: true,

            textInputAction: TextInputAction.next,

            validator: (value) => validatePasswordAgain(
              value,
              context.read<RegistrationModel>().password,
            ),

            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,

              border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
            ),

            autovalidateMode: AutovalidateMode.onUserInteraction,
          ),
        ),
      ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Пароль',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),

        const SizedBox(height: 6),

        SizedBox(
          width: MediaQuery.sizeOf(context).width * 0.9,
          child: TextFormField(
            obscureText: true,

            textInputAction: TextInputAction.next,

            validator: (value) => validatorPassword(value),

            onChanged: (value) {
              context.read<RegistrationModel>().setPassword(value);
            },

            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,

              border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
            ),

            autovalidateMode: AutovalidateMode.onUserInteraction,
          ),
        ),
      ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text('Email', style: TextStyle(fontSize: 14, color: Colors.grey)),

        const SizedBox(height: 6),

        SizedBox(
          width: MediaQuery.sizeOf(context).width * 0.9,
          child: TextFormField(
            keyboardType: TextInputType.emailAddress,

            textInputAction: TextInputAction.next,

            validator: (value) => validatorEmail(value),

            onChanged: (value) {
              context.read<RegistrationModel>().setEmail(value);
            },

            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,

              border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
            ),

            autovalidateMode: AutovalidateMode.onUserInteraction,
          ),
        ),
      ],
    );
  }
}
