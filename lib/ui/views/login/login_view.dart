import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:strife/ui/view_models/auth_view_model.dart';
import 'package:strife/ui/views/register/registration_view.dart';
import 'package:strife/themes/gradient_theme.dart';
import 'package:provider/provider.dart';

class LoginView extends StatelessWidget {
  LoginView({super.key});

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final gradient = Theme.of(context).extension<GradientTheme>()!.mainGradient;

    return Container(
      decoration: BoxDecoration(gradient: gradient),
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
              ),
              Text(
                'Видеоконференции',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
          backgroundColor: Colors.transparent,
        ),
        resizeToAvoidBottomInset: true,
        body: Form(
          key: _formKey,
          child: SafeArea(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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

                  EmailTextForm(controller: _emailController),

                  const SizedBox(height: 8),

                  PasswordTextForm(controller: _passwordController),

                  const SizedBox(height: 12),

                  LoginButton(
                    formKey: _formKey,
                    emailController: _emailController,
                    passwordController: _passwordController,
                  ),

                  const SizedBox(height: 12),

                  const RegisterNavigationText(),

                  const SizedBox(height: 120),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Divider(
                            thickness: 2,
                            color: Color(0xFF999393),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Text(
                            'или войти с помощью',
                            style: TextStyle(
                              color: Color(0xFF999393),
                              fontSize: 24,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(thickness: 1, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),

                  const SocialLogosRow(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RegisterNavigationText extends StatelessWidget {
  const RegisterNavigationText({super.key});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 20, color: Color(0xFF999393)),
        children: [
          const TextSpan(text: 'Нет аккаунта?'),

          TextSpan(
            text: ' Зарегестрироваться',
            style: TextStyle(color: Color.fromARGB(255, 28, 91, 239)),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => RegistrationView()),
                );
              },
          ),
        ],
      ),
    );
  }
}

class SocialLogosRow extends StatelessWidget {
  const SocialLogosRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 32,
      children: <Widget>[
        //Image.asset('assets/images/mail_logo.png', scale: 1.3),
        IconButton(
          icon: Image.asset('assets/images/yandex_logo.png', scale: 1.3),
          onPressed: () async {
            await context.read<AuthViewModel>().signInYandex();
          },
        ),

        //Image.asset('assets/images/vk_logo.png', scale: 1.3),
      ],
    );
  }
}

class EmailTextForm extends StatelessWidget {
  final TextEditingController controller;
  const EmailTextForm({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.sizeOf(context).width * 0.9,
      child: FormField<String>(
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: (value) {
          if (value == null || value.isEmpty) return 'Пожалуйста введите почту';
          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
            return 'Некорректная почта';
          }
          return null;
        },
        builder: (field) {
          final hasError = field.errorText != null;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                textInputAction: TextInputAction.next,
                controller: controller,
                keyboardType: TextInputType.emailAddress,
                onChanged: field.didChange,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFD9D9D9).withValues(alpha: 0.4),
                  border: const OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.all(Radius.circular(25)),
                  ),
                  hintText: 'Почта...',
                ),
              ),
              SizedBox(
                height: 36,
                child: hasError
                    ? Align(
                        alignment: Alignment.center,
                        child: Container(
                          margin: const EdgeInsets.only(left: 10, top: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFA60A0A),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  field.errorText!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class PasswordTextForm extends StatelessWidget {
  final TextEditingController controller;
  const PasswordTextForm({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.sizeOf(context).width * 0.9,
      child: FormField<String>(
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: (value) => (value == null || value.length < 6)
            ? 'Пароль должен содержать минимум 6 символов'
            : null,
        builder: (field) {
          final hasError = field.errorText != null;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: controller,
                obscureText: true,
                onChanged: field.didChange,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFD9D9D9).withValues(alpha: 0.4),
                  border: const OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.all(Radius.circular(25)),
                  ),
                  hintText: 'Пароль...',
                ),
              ),
              SizedBox(
                height: 36,
                child: hasError
                    ? Align(
                        alignment: Alignment.center,
                        child: Container(
                          margin: const EdgeInsets.only(left: 10, top: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFA60A0A),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  field.errorText!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class LoginButton extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;

  const LoginButton({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
  });

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select<AuthViewModel, bool>((vm) => vm.isLoading);

    return FilledButton(
      style: ButtonStyle(
        backgroundColor: WidgetStatePropertyAll(
          const Color(0xFFFEFEFE).withValues(alpha: 0.7),
        ),
        fixedSize: WidgetStatePropertyAll(
          Size(MediaQuery.sizeOf(context).width * 0.7, 60),
        ),
      ),
      onPressed: isLoading
          ? null
          : () async {
              if (formKey.currentState!.validate()) {
                final authVM = context.read<AuthViewModel>();

                final success = await authVM.signIn(
                  emailController.text.trim(),
                  passwordController.text.trim(),
                );

                if (!context.mounted) return;

                if (!success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ошибка: ${authVM.error}')),
                  );
                }
              }
            },
      child: isLoading
          ? const CircularProgressIndicator(color: Colors.black)
          : const Text(
              'Войти в аккаунт',
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
    );
  }
}
