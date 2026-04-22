import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:strife/themes/gradient_theme.dart';
import 'package:strife/ui/view_models/auth_view_model.dart';
import 'package:intl/intl.dart';
import 'package:strife/ui/widgets/error_label_widget.dart';

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

    return Container(
      decoration: BoxDecoration(gradient: gradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
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
        ),
        body: Form(
          key: _formKey,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
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

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
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

                  EmailTextForm(controller: _emailController),

                  DateOfBirthField(
                    selectedDate: _selectedDate,
                    onTap: (date) => setState(() => _selectedDate = date),
                  ),

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

class DateOfBirthField extends StatelessWidget {
  final DateTime? selectedDate;
  final Function(DateTime) onTap;

  const DateOfBirthField({super.key, this.selectedDate, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.sizeOf(context).width * 0.9,
      child: FormField<DateTime>(
        initialValue: selectedDate,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: (value) {
          if (selectedDate == null) return 'Укажите дату рождения';
          return null;
        },
        builder: (field) {
          final hasError = field.errorText != null;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Дата рождения',
                style: TextStyle(fontSize: 14, color: Colors.white70),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: MediaQuery.sizeOf(context).width * 0.9,
                child: TextField(
                  readOnly: true,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate ?? DateTime(2000),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      onTap(date);
                      field.didChange(date);
                    }
                  },
                  decoration: _inputDecoration().copyWith(
                    hintText: selectedDate == null
                        ? 'Выберите дату'
                        : DateFormat('dd.MM.yyyy').format(selectedDate!),
                    suffixIcon: const Icon(Icons.calendar_today),
                  ),
                ),
              ),
              if (hasError) ErrorLabel(errorText: field.errorText),
            ],
          );
        },
      ),
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
              if (formKey.currentState!.validate() && dob != null) {
                final success = await authVM.signUp(
                  email: email.text.trim(),
                  password: password.text.trim(),
                  firtstName: name.text.trim(),
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
