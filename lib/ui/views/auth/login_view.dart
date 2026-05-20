import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:strife/data/repositories/auth_repository.dart';
import 'package:strife/presentation/blocs/auth/auth_bloc.dart';
import 'package:strife/ui/views/auth/reset_password_view.dart';
import 'package:strife/ui/views/auth/registration_view.dart';
import 'package:strife/themes/gradient_theme.dart';
import 'package:strife/ui/widgets/app_notifications.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gradient = Theme.of(context).extension<GradientTheme>()!.mainGradient;

    return BlocProvider(
      create: (context) =>
          AuthBloc(authRepository: context.read<AuthRepository>()),
      child: Container(
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
                    fontSize: 32,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'Видеоконференции',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    fontWeight: FontWeight.normal,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),

          resizeToAvoidBottomInset: false,

          body: BlocListener<AuthBloc, AuthState>(
            listenWhen: (previous, current) =>
                previous.status != current.status,
            listener: (context, state) {
              if (state.status == AuthStatus.failure &&
                  state.errorMessage != null) {
                AppNotifications.showError(context, state.errorMessage!);
              }
              if (state.status == AuthStatus.success &&
                  state.successMessage != null) {
                AppNotifications.showSuccess(context, state.successMessage!);
              }
            },
            child: Form(
              key: _formKey,
              child: SafeArea(
                child: CustomScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          const SizedBox(height: 40),

                          // Заголовок
                          const Center(
                            child: Text(
                              'Добро пожаловать!',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 32,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Подзаголовок
                          const Center(
                            child: Text(
                              'Войдите в свой аккаунт',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(height: 48),

                          // Поля ввода
                          EmailTextForm(controller: _emailController),
                          const SizedBox(height: 16),
                          PasswordTextForm(controller: _passwordController),
                          const SizedBox(height: 12),

                          ResetPasswordNavigationText(),
                          const SizedBox(height: 20),

                          // Главная кнопка входа
                          LoginButton(
                            formKey: _formKey,
                            emailController: _emailController,
                            passwordController: _passwordController,
                          ),
                          const SizedBox(height: 20),

                          // Ссылка на регистрацию
                          const RegisterNavigationText(),
                        ]),
                      ),
                    ),

                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Spacer(),

                            Builder(
                              builder: (context) {
                                final bool isKeyboardOpen =
                                    MediaQuery.of(context).viewInsets.bottom >
                                    0;

                                return AnimatedScale(
                                  scale: isKeyboardOpen ? 0.85 : 1.0,
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeInOutCubic,
                                  child: AnimatedOpacity(
                                    opacity: isKeyboardOpen ? 0.0 : 1.0,
                                    duration: const Duration(milliseconds: 180),
                                    curve: Curves.easeInOutCubic,
                                    child: const Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SocialDivider(),
                                        SizedBox(height: 24),
                                        SocialLogosRow(),
                                        SizedBox(
                                          height: 24,
                                        ), // Отступ от самого низа экрана
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
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

class ResetPasswordNavigationText extends StatelessWidget {
  const ResetPasswordNavigationText({super.key});

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: TextAlign.end,
      text: TextSpan(
        text: 'Забыли пароль?',
        style: const TextStyle(
          color: Color.fromARGB(255, 100, 200, 255),
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.none,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            Navigator.of(context).push(_createRoute(ResetPasswordView()));
          },
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
                Navigator.of(
                  context,
                ).push(_createRoute(const RegistrationView()));
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
        Expanded(
          child: Divider(
            thickness: 1,
            color: Colors.white.withValues(alpha: 0.15),
            endIndent: 16,
          ),
        ),
        Text(
          'или войти с помощью',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 14,
            letterSpacing: 0.3,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Divider(
            thickness: 1,
            color: Colors.white.withValues(alpha: 0.15),
            indent: 16,
          ),
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
      children: <Widget>[
        SocialIconButton(
          icon: 'assets/images/yandex_logo.png',
          onPressed: () async {
            context.read<AuthBloc>().add(const SignInWithYandexRequested());
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
      width: 80,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            splashColor: const Color(0xFFB91ED0).withValues(alpha: 0.2),
            highlightColor: const Color(0xFFB91ED0).withValues(alpha: 0.1),
            child: Center(
              child: Image.asset(
                icon,
                width: 38,
                height: 38,
                fit: BoxFit.contain,
              ),
            ),
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
  const PasswordTextForm({super.key, required this.controller});

  @override
  State<PasswordTextForm> createState() => _PasswordTextFormState();
}

class _PasswordTextFormState extends State<PasswordTextForm> {
  final _focusNode = FocusNode();
  bool _obscureText = true;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
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
        obscureText: _obscureText,
        textInputAction: TextInputAction.done,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        style: const TextStyle(color: Colors.black87, fontSize: 16),

        validator: (value) =>
            (value == null || value.length < 6) ? 'Минимум 6 символов' : null,

        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          hintText: 'Пароль',
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
    final isLoading = context.select<AuthBloc, bool>(
      (value) => value.state.status == AuthStatus.loading,
    );
    const brandColor = Color(0xFFB91ED0);

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: isLoading
              ? Colors.white.withValues(alpha: 0.6)
              : Colors.white,
          // Цвет текста и лоадера
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
                  context.read<AuthBloc>().add(
                    SignInRequested(
                      email: emailController.text.trim(),
                      password: passwordController.text.trim(),
                    ),
                  );
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
                'Войти',
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

Route<void> _createRoute(Widget widget) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => widget,
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
