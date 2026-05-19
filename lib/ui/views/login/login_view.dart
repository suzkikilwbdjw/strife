import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:strife/ui/view_models/auth_view_model.dart';
import 'package:strife/ui/views/register/registration_view.dart';
import 'package:strife/themes/gradient_theme.dart';
import 'package:provider/provider.dart';
import 'package:strife/ui/widgets/error_label_widget.dart';

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
        resizeToAvoidBottomInset: true,
        body: Form(
          key: _formKey,
          child: SafeArea(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const SizedBox(height: 40),

                    const Text(
                      'Добро пожаловать!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 32,
                        letterSpacing: 0.5,
                      ),
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      'Войдите в свой аккаунт',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),

                    const SizedBox(height: 60),

                    EmailTextForm(controller: _emailController),

                    const SizedBox(height: 16),

                    PasswordTextForm(controller: _passwordController),

                    const SizedBox(height: 40),

                    LoginButton(
                      formKey: _formKey,
                      emailController: _emailController,
                      passwordController: _passwordController,
                    ),

                    const SizedBox(height: 20),

                    const RegisterNavigationText(),

                    const SizedBox(height: 60),

                    const SocialDivider(),

                    const SizedBox(height: 24),

                    const SocialLogosRow(),

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

class RegisterNavigationText extends StatelessWidget {
  const RegisterNavigationText({super.key});

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: const TextStyle(
          fontSize: 16,
          color: Colors.white70,
          letterSpacing: 0.3,
        ),
        children: [
          const TextSpan(text: 'Нет аккаунта? '),

          TextSpan(
            text: 'Зарегистрироваться',
            style: const TextStyle(
              color: Color.fromARGB(255, 100, 200, 255),
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.none,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                Navigator.of(context).push(_createRoute());
              },
          ),
        ],
      ),
    );
  }
}

class SocialDivider extends StatelessWidget {
  const SocialDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Divider(thickness: 1, color: Colors.white24, endIndent: 12),
        ),
        Text(
          'или войти с помощью',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 13,
            letterSpacing: 0.3,
          ),
        ),
        const Expanded(
          child: Divider(thickness: 1, color: Colors.white24, indent: 12),
        ),
      ],
    );
  }
}

class SocialLogosRow extends StatelessWidget {
  const SocialLogosRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 20,
      children: <Widget>[
        SocialIconButton(
          icon: 'assets/images/yandex_logo.png',
          onPressed: () async {
            await context.read<AuthViewModel>().signInYandex();
          },
        ),
      ],
    );
  }
}

class SocialIconButton extends StatelessWidget {
  final String icon;
  final VoidCallback onPressed;

  const SocialIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.white.withValues(alpha: 0.15),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Image.asset(icon, scale: 1.3),
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
                    hintText: 'Почта',
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
                  style: const TextStyle(color: Colors.black87, fontSize: 16),
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
  const PasswordTextForm({super.key, required this.controller});

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
        validator: (value) =>
            (value == null || value.length < 6) ? 'Минимум 6 символов' : null,
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
                    hintText: 'Пароль',
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
                  style: const TextStyle(color: Colors.black87, fontSize: 16),
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
            isLoading
                ? Colors.blue.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.95),
          ),
          foregroundColor: WidgetStatePropertyAll(
            isLoading ? Colors.white : Colors.black87,
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          elevation: WidgetStatePropertyAll(isLoading ? 0 : 2),
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
                      SnackBar(
                        content: Text('${authVM.error}'),
                        backgroundColor: Colors.red.withValues(alpha: 0.8),
                        behavior: SnackBarBehavior.floating,
                        margin: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  }
                }
              },
        child: isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Войти',
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

Route<void> _createRoute() {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) =>
        const RegistrationView(),
    transitionDuration: const Duration(milliseconds: 400),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return ScaleTransition(
        scale: Tween<double>(begin: 0.85, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic),
        ),
        child: FadeTransition(opacity: animation, child: child),
      );
    },
  );
}
