import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:strife/themes/gradient_theme.dart';
import 'package:strife/ui/view_models/auth_view_model.dart';
import 'package:intl/intl.dart';

class RegistrationView extends StatefulWidget {
  const RegistrationView({super.key});

  @override
  State<RegistrationView> createState() => _RegistrationViewState();
}

class _RegistrationViewState extends State<RegistrationView> {
  final _formKey = GlobalKey<FormState>();

  // Контроллеры для всех полей
  final _nameController = TextEditingController();
  final _secondNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordAgainController = TextEditingController();

  DateTime? _selectedDate;

  @override
  void dispose() {
    _nameController.dispose();
    _secondNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordAgainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gradient = Theme.of(context).extension<GradientTheme>()!.mainGradient;

    return Scaffold(
      appBar: AppBar(
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
        flexibleSpace: Container(decoration: BoxDecoration(gradient: gradient)),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: gradient),
        child: SafeArea(
          child: Center(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    const Text(
                      'Регистрация',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 36,
                      ),
                    ),
                    const SizedBox(height: 30),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: NameTextForm(
                              controller: _nameController,
                              label: 'Имя',
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: NameTextForm(
                              controller: _secondNameController,
                              label: 'Фамилия',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    EmailTextForm(controller: _emailController),
                    const SizedBox(height: 20),
                    DateOfBirthField(
                      selectedDate: _selectedDate,
                      onTap: (date) => setState(() => _selectedDate = date),
                    ),
                    const SizedBox(height: 20),
                    PasswordTextForm(
                      controller: _passwordController,
                      label: 'Пароль',
                    ),
                    const SizedBox(height: 20),
                    PasswordTextForm(
                      controller: _passwordAgainController,
                      label: 'Подтвердите пароль',
                      originalPasswordController: _passwordController,
                    ),
                    const SizedBox(height: 30),
                    RegisterButton(
                      formKey: _formKey,
                      name: _nameController,
                      secondName: _secondNameController,
                      email: _emailController,
                      password: _passwordController,
                      dob: _selectedDate,
                    ),
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

class NameTextForm extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  const NameTextForm({
    super.key,
    required this.controller,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.white70),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: (v) => (v == null || v.isEmpty) ? 'Заполните поле' : null,
          decoration: _inputDecoration(),
          textInputAction: TextInputAction.next,
        ),
      ],
    );
  }
}

class DateOfBirthField extends StatelessWidget {
  final DateTime? selectedDate;
  final Function(DateTime) onTap;

  const DateOfBirthField({super.key, this.selectedDate, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Дата рождения',
          style: TextStyle(fontSize: 14, color: Colors.white70),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: MediaQuery.sizeOf(context).width * 0.9,
          child: TextFormField(
            readOnly: true,
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime(2000),
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
              );
              if (date != null) onTap(date);
            },
            decoration: _inputDecoration().copyWith(
              hintText: selectedDate == null
                  ? 'Выберите дату'
                  : DateFormat('dd.MM.yyyy').format(selectedDate!),
              suffixIcon: const Icon(Icons.calendar_today),
            ),
            validator: (_) =>
                selectedDate == null ? 'Укажите дату рождения' : null,
          ),
        ),
      ],
    );
  }
}

class RegisterButton extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController name, secondName, email, password;
  final DateTime? dob;

  const RegisterButton({
    super.key,
    required this.formKey,
    required this.name,
    required this.secondName,
    required this.email,
    required this.password,
    this.dob,
  });

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();

    return FilledButton(
      style: FilledButton.styleFrom(
        fixedSize: Size(MediaQuery.sizeOf(context).width * 0.7, 60),
        backgroundColor: Colors.white.withValues(alpha: 0.9),
      ),
      onPressed: authVM.isLoading
          ? null
          : () async {
              if (formKey.currentState!.validate() && dob != null) {
                final success = await authVM.signUp(
                  email: email.text.trim(),
                  password: password.text.trim(),
                  name: name.text.trim(),
                  secondName: secondName.text.trim(),
                  dob: dob!,
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
          ? const CircularProgressIndicator(color: Colors.deepPurple)
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Email',
          style: TextStyle(fontSize: 14, color: Colors.white70),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: MediaQuery.sizeOf(context).width * 0.9,
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Пожалуйста введите почту';
              }
              if (!RegExp(
                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
              ).hasMatch(value)) {
                return 'Некорректная почта';
              }
              return null;
            },
            decoration: _inputDecoration(),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            textInputAction: TextInputAction.next,
          ),
        ),
      ],
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
          child: TextFormField(
            controller: controller,
            obscureText: true,
            textInputAction: originalPasswordController != null
                ? TextInputAction.done
                : TextInputAction.next,
            decoration: _inputDecoration(),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Заполните пароль';
              if (value.length < 6) return 'Минимум 6 символов';

              if (originalPasswordController != null &&
                  value != originalPasswordController!.text) {
                return 'Пароли не совпадают';
              }
              return null;
            },
            autovalidateMode: AutovalidateMode.onUserInteraction,
          ),
        ),
      ],
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
