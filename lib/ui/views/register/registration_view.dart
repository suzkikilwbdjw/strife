import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:strife/themes/gradient_theme.dart';
import 'package:strife/ui/view_models/auth_view_model.dart';
import 'package:strife/ui/widgets/app_notifications.dart';

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
          toolbarHeight: 100,
          leading: BackIconButton(),
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Strife',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 32,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                'Видеоконференции',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
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
                      style: TextStyle(color: Colors.white70, fontSize: 16),
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

class BackIconButton extends StatelessWidget {
  const BackIconButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(
        Icons.arrow_back_ios_new_rounded,
        color: Colors.white,
        size: 32,
      ),
      onPressed: () => Navigator.of(context).pop(),
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
    const brandColor = Color(0xFFB91ED0);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: _isFocused
                ? brandColor.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: _isFocused ? 14 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        focusNode: _focusNode,
        controller: widget.controller,
        textInputAction: TextInputAction.next,
        textCapitalization: TextCapitalization.words,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        style: const TextStyle(color: Colors.black87, fontSize: 16),

        inputFormatters: [LengthLimitingTextInputFormatter(widget.maxLength)],

        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Введите имя';
          }
          return null;
        },

        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          hintText: widget.label,
          hintStyle: TextStyle(
            color: Colors.grey.withValues(alpha: 0.5),
            fontSize: 16,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),

          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 16, right: 12),
            child: Icon(
              Icons.person_outline_rounded,
              color: _isFocused ? brandColor : Colors.grey,
              size: 20,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 48,
            minHeight: 48,
          ),

          border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(14),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(14),
          ),

          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: brandColor.withValues(alpha: 0.4),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(14),
          ),

          errorBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.redAccent, width: 1),
            borderRadius: BorderRadius.circular(14),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            borderRadius: BorderRadius.circular(14),
          ),
          errorStyle: const TextStyle(fontSize: 13, color: Colors.redAccent),
        ),
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
    final isLoading = context.select<AuthViewModel, bool>((vm) => vm.isLoading);
    const brandColor = Color(0xFFB91ED0);

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: isLoading
              ? Colors.white.withValues(alpha: 0.6)
              : Colors.white,
          foregroundColor: Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: isLoading ? 0 : 4,
          shadowColor: brandColor.withValues(alpha: 0.3),
        ),
        onPressed: isLoading
            ? null
            : () async {
                if (formKey.currentState!.validate()) {
                  final authVM = context.read<AuthViewModel>();

                  final success = await authVM.signUp(
                    email: emailController.text.trim(),
                    password: passwordController.text.trim(),
                    displayName: displayNameController.text.trim(),
                  );

                  if (!context.mounted) return;

                  if (!success) {
                    AppNotifications.showError(
                      context,
                      authVM.error ?? 'Ошибка регистрации',
                    );
                  } else {
                    Navigator.of(context).pop();
                  }
                }
              },
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black87),
                ),
              )
            : const Text(
                'Создать аккаунт',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
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
    const brandColor = Color(0xFFB91ED0);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: _isFocused
                ? brandColor.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: _isFocused ? 14 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        focusNode: _focusNode,
        controller: widget.controller,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        style: const TextStyle(color: Colors.black87, fontSize: 16),

        validator: (value) {
          if (value == null || value.trim().isEmpty) return 'Введите почту';
          final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
          if (!emailRegex.hasMatch(value.trim())) {
            return 'Некорректная почта';
          }
          return null;
        },

        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          hintText: 'Почта',
          hintStyle: TextStyle(
            color: Colors.grey.withValues(alpha: 0.5),
            fontSize: 16,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),

          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 16, right: 12),
            child: Icon(
              Icons.email_outlined,
              color: _isFocused ? brandColor : Colors.grey,
              size: 20,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 48,
            minHeight: 48,
          ),

          border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(14),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(14),
          ),

          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: brandColor.withValues(alpha: 0.4),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(14),
          ),

          errorBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.redAccent, width: 1),
            borderRadius: BorderRadius.circular(14),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            borderRadius: BorderRadius.circular(14),
          ),

          errorStyle: const TextStyle(fontSize: 13, color: Colors.redAccent),
        ),
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
    const brandColor = Color(0xFFB91ED0);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: _isFocused ? 0.15 : 0.05),
            blurRadius: _isFocused ? 14 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
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
        focusNode: _focusNode,
        controller: widget.controller,
        obscureText: _obscureText,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        textInputAction: widget.originalPasswordController != null
            ? TextInputAction.done
            : TextInputAction.next,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,

          border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(14),
          ),

          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(14),
          ),

          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: brandColor.withValues(alpha: 0.4),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(14),
          ),

          errorBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.redAccent, width: 1),
            borderRadius: BorderRadius.circular(14),
          ),

          focusedErrorBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            borderRadius: BorderRadius.circular(14),
          ),

          errorStyle: const TextStyle(fontSize: 13, color: Colors.redAccent),

          hintText: widget.label,
          hintStyle: TextStyle(
            color: Colors.grey.withValues(alpha: 0.5),
            fontSize: 16,
          ),

          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),

          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 16, right: 12),
            child: Icon(
              Icons.lock_outline_rounded,
              color: _isFocused ? brandColor : Colors.grey,
              size: 20,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 48,
            minHeight: 48,
          ),
          suffixIcon: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Icon(
                _obscureText
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: _isFocused
                    ? brandColor.withValues(alpha: 0.7)
                    : Colors.grey,
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
        style: const TextStyle(color: Colors.black87, fontSize: 16),
      ),
    );
  }
}
