import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:strife/themes/gradient_theme.dart';
import 'package:strife/ui/view_models/auth_view_model.dart';
import 'package:strife/ui/widgets/error_label_widget.dart';

class RegistrationView extends StatefulWidget {
  const RegistrationView({super.key});

  @override
  State<RegistrationView> createState() => _RegistrationViewState();
}

class _RegistrationViewState extends State<RegistrationView> {
  final _formKey = GlobalKey<FormState>();

  // Контроллеры для всех полей
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordAgainController = TextEditingController();

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordAgainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gradient = Theme.of(context).extension<GradientTheme>()!.mainGradient;

    return Container(
      decoration: BoxDecoration(gradient: gradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.white),
          toolbarHeight: 100,
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
        body: Form(
          key: _formKey,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                vertical: 16.0,
                horizontal: 16.0,
              ),
              child: Column(
                spacing: 4.0,
                children: <Widget>[
                  const Text(
                    'Регистрация',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 36,
                    ),
                  ),

                  const SizedBox(height: 10),

                  NameTextForm(
                    controller: _displayNameController,
                    label: 'Отображаемое имя',
                    maxLength: 30,
                  ),

                  EmailTextForm(controller: _emailController),

                  PasswordTextForm(
                    controller: _passwordController,
                    label: 'Пароль',
                  ),

                  PasswordTextForm(
                    controller: _passwordAgainController,
                    label: 'Подтвердите пароль',
                    originalPasswordController: _passwordController,
                  ),

                  const SizedBox(height: 30),

                  RegisterButton(
                    formKey: _formKey,
                    displayName: _displayNameController.text.trim(),
                    email: _emailController.text.trim(),
                    password: _passwordController.text.trim(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class NameTextForm extends StatelessWidget {
  final TextEditingController controller;
  final String label;

  final int? maxLength;
  const NameTextForm({
    super.key,
    required this.controller,
    required this.label,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: FormField<String>(
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: (v) => (v == null || v.isEmpty) ? 'Заполните поле' : null,
        builder: (field) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 14, color: Colors.white70),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: MediaQuery.sizeOf(context).width * 0.9,
                child: TextField(
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(maxLength),
                  ],
                  controller: controller,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration(),
                  onChanged: (value) => field.didChange(value),
                ),
              ),
              if (field.hasError) ErrorLabel(errorText: field.errorText),
            ],
          );
        },
      ),
    );
  }
}

class RegisterButton extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final String displayName, email, password;

  const RegisterButton({
    super.key,
    required this.formKey,
    required this.displayName,
    required this.email,
    required this.password,
  });

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();

    return FilledButton(
      style: ButtonStyle(
        backgroundColor: WidgetStatePropertyAll(
          const Color.fromARGB(255, 255, 255, 255).withValues(alpha: 0.9),
        ),
        fixedSize: WidgetStatePropertyAll(
          Size(MediaQuery.sizeOf(context).width * 0.7, 60),
        ),
      ),
      onPressed: authVM.isLoading
          ? null
          : () async {
              if (formKey.currentState!.validate()) {
                final success = await authVM.signUp(
                  email: email,
                  password: password,
                  displayName: displayName,
                );

                if (!context.mounted) return;

                if (!success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(authVM.error ?? 'Ошибка регистрации'),
                    ),
                  );
                } else {
                  Navigator.of(context).pop();
                }
              }
            },
      child: authVM.isLoading
          ? const CircularProgressIndicator(color: Colors.black)
          : const Text(
              'Создать аккаунт',
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
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
              const Text(
                'Email',
                style: TextStyle(fontSize: 14, color: Colors.white70),
              ),
              const SizedBox(height: 6),
              TextField(
                textInputAction: TextInputAction.next,
                controller: controller,
                keyboardType: TextInputType.emailAddress,
                onChanged: field.didChange,
                decoration: _inputDecoration(),
              ),
              SizedBox(
                child: hasError
                    ? ErrorLabel(errorText: field.errorText)
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
  final String label;
  final TextEditingController? originalPasswordController;

  const PasswordTextForm({
    super.key,
    required this.controller,
    required this.label,
    this.originalPasswordController,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.sizeOf(context).width * 0.9,
      child: FormField<String>(
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: (value) {
          final currentText = controller.text;
          if (currentText.isEmpty) return 'Заполните пароль';
          if (currentText.length < 6) return 'Минимум 6 символов';

          if (originalPasswordController != null &&
              currentText != originalPasswordController!.text) {
            return 'Пароли не совпадают';
          }
          return null;
        },
        builder: (field) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 14, color: Colors.white70),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: MediaQuery.sizeOf(context).width * 0.9,
                child: TextField(
                  controller: controller,
                  obscureText: true,
                  textInputAction: originalPasswordController != null
                      ? TextInputAction.done
                      : TextInputAction.next,
                  decoration: _inputDecoration(),
                  onChanged: (value) => field.didChange(value),
                ),
              ),
              if (field.hasError) ErrorLabel(errorText: field.errorText),
            ],
          );
        },
      ),
    );
  }
}

InputDecoration _inputDecoration() {
  return const InputDecoration(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderSide: BorderSide.none,
      borderRadius: BorderRadius.all(Radius.circular(10)),
    ),
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  );
}
