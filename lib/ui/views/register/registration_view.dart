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
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                'Видеоконференции',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Form(
          key: _formKey,
          child: SafeArea(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: <Widget>[
                    const SizedBox(height: 40),

                    const Text(
                      'Регистрация',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 32,
                        letterSpacing: 0.5,
                      ),
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      'Создайте свой аккаунт',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(height: 40),

                    NameTextForm(
                      controller: _displayNameController,
                      label: 'Имя профиля',
                      maxLength: 30,
                    ),

                    const SizedBox(height: 16),

                    EmailTextForm(controller: _emailController),

                    const SizedBox(height: 16),

                    PasswordTextForm(
                      controller: _passwordController,
                      label: 'Пароль',
                    ),

                    const SizedBox(height: 16),

                    PasswordTextForm(
                      controller: _passwordAgainController,
                      label: 'Подтвердите пароль',
                      originalPasswordController: _passwordController,
                    ),

                    const SizedBox(height: 40),

                    RegisterButton(
                      formKey: _formKey,
                      displayNameController: _displayNameController,
                      emailController: _emailController,
                      passwordController: _passwordController,
                    ),

                    const SizedBox(height: 40),
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

class NameTextForm extends StatefulWidget {
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
  State<NameTextForm> createState() => _NameTextFormState();
}

class _NameTextFormState extends State<NameTextForm> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() => _isFocused = _focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FormField<String>(
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: (v) => (v == null || v.isEmpty) ? 'Введите имя' : null,
        builder: (field) {
          final hasError = field.errorText != null;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: _isFocused ? 0.15 : 0.08,
                      ),
                      blurRadius: _isFocused ? 12 : 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  focusNode: _focusNode,
                  controller: widget.controller,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(widget.maxLength),
                  ],
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.95),
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: hasError
                            ? Colors.red.withValues(alpha: 0.3)
                            : Colors.transparent,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: hasError
                            ? Colors.red.withValues(alpha: 0.5)
                            : Colors.blue.withValues(alpha: 0.5),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    hintText: widget.label,
                    hintStyle: TextStyle(
                      color: Colors.grey.withValues(alpha: 0.5),
                      fontSize: 16,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(left: 16, right: 12),
                      child: Icon(
                        Icons.person_outline,
                        color: Colors.grey,
                        size: 20,
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                  ),
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                  ),
                  onChanged: (value) => field.didChange(value),
                ),
              ),
              if (hasError)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 4),
                  child: ErrorLabel(errorText: field.errorText),
                ),
            ],
          );
        },
      ),
    );
  }
}

class RegisterButton extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController displayNameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;

  const RegisterButton({
    super.key,
    required this.formKey,
    required this.displayNameController,
    required this.emailController,
    required this.passwordController,
  });

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FilledButton(
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(
            authVM.isLoading
                ? Colors.blue.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.95),
          ),
          foregroundColor: WidgetStatePropertyAll(
            authVM.isLoading ? Colors.white : Colors.black87,
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          elevation: WidgetStatePropertyAll(authVM.isLoading ? 0 : 2),
        ),
        onPressed: authVM.isLoading
            ? null
            : () async {
                if (formKey.currentState!.validate()) {
                  final success = await authVM.signUp(
                    email: emailController.text.trim(),
                    password: passwordController.text.trim(),
                    displayName: displayNameController.text.trim(),
                  );

                  if (!context.mounted) return;

                  if (!success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(authVM.error ?? 'Ошибка регистрации'),
                        backgroundColor: Colors.red.withValues(alpha: 0.8),
                        behavior: SnackBarBehavior.floating,
                        margin: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  } else {
                    Navigator.of(context).pop();
                  }
                }
              },
        child: authVM.isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Создать аккаунт',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }
}

class EmailTextForm extends StatefulWidget {
  final TextEditingController controller;

  const EmailTextForm({super.key, required this.controller});

  @override
  State<EmailTextForm> createState() => _EmailTextFormState();
}

class _EmailTextFormState extends State<EmailTextForm> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() => _isFocused = _focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FormField<String>(
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: (value) {
          if (value == null || value.isEmpty) return 'Введите почту';
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
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: _isFocused ? 0.15 : 0.08,
                      ),
                      blurRadius: _isFocused ? 12 : 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  focusNode: _focusNode,
                  textInputAction: TextInputAction.next,
                  controller: widget.controller,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: field.didChange,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.95),
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: hasError
                            ? Colors.red.withValues(alpha: 0.3)
                            : Colors.transparent,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: hasError
                            ? Colors.red.withValues(alpha: 0.5)
                            : Colors.blue.withValues(alpha: 0.5),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    hintText: 'Email',
                    hintStyle: TextStyle(
                      color: Colors.grey.withValues(alpha: 0.5),
                      fontSize: 16,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(left: 16, right: 12),
                      child: Icon(
                        Icons.email_outlined,
                        color: Colors.grey,
                        size: 20,
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                  ),
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                  ),
                ),
              ),
              if (hasError)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 4),
                  child: ErrorLabel(errorText: field.errorText),
                ),
            ],
          );
        },
      ),
    );
  }
}

class PasswordTextForm extends StatefulWidget {
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
  State<PasswordTextForm> createState() => _PasswordTextFormState();
}

class _PasswordTextFormState extends State<PasswordTextForm> {
  late FocusNode _focusNode;
  bool _obscureText = true;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() => _isFocused = _focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FormField<String>(
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: (value) {
          final currentText = widget.controller.text;
          if (currentText.isEmpty) return 'Введите пароль';
          if (currentText.length < 6) return 'Минимум 6 символов';

          if (widget.originalPasswordController != null &&
              currentText != widget.originalPasswordController!.text) {
            return 'Пароли не совпадают';
          }
          return null;
        },
        builder: (field) {
          final hasError = field.errorText != null;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: _isFocused ? 0.15 : 0.08,
                      ),
                      blurRadius: _isFocused ? 12 : 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  focusNode: _focusNode,
                  controller: widget.controller,
                  obscureText: _obscureText,
                  textInputAction: widget.originalPasswordController != null
                      ? TextInputAction.done
                      : TextInputAction.next,
                  onChanged: (value) => field.didChange(value),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.95),
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: hasError
                            ? Colors.red.withValues(alpha: 0.3)
                            : Colors.transparent,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: hasError
                            ? Colors.red.withValues(alpha: 0.5)
                            : Colors.blue.withValues(alpha: 0.5),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    hintText: widget.label,
                    hintStyle: TextStyle(
                      color: Colors.grey.withValues(alpha: 0.5),
                      fontSize: 16,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(left: 16, right: 12),
                      child: Icon(
                        Icons.lock_outline,
                        color: Colors.grey,
                        size: 20,
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    suffixIcon: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: IconButton(
                        icon: Icon(
                          _obscureText
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: Colors.grey,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() => _obscureText = !_obscureText);
                        },
                      ),
                    ),
                    suffixIconConstraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                  ),
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                  ),
                ),
              ),
              if (hasError)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 4),
                  child: ErrorLabel(errorText: field.errorText),
                ),
            ],
          );
        },
      ),
    );
  }
}
