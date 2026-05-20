import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:strife/data/repositories/auth_repository.dart';
import 'package:strife/presentation/blocs/auth/auth_bloc.dart';
import 'package:strife/themes/gradient_theme.dart';
import 'package:strife/ui/widgets/app_notifications.dart';

class ResetPasswordView extends StatefulWidget {
  const ResetPasswordView({super.key});

  @override
  State<ResetPasswordView> createState() => _ResetPasswordViewState();
}

class _ResetPasswordViewState extends State<ResetPasswordView> {
  final TextEditingController _emailController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gradient = Theme.of(context).extension<GradientTheme>()!.mainGradient;
    final double keyboardHeight = View.of(context).viewInsets.bottom;

    return BlocProvider(
      create: (context) =>
          AuthBloc(authRepository: context.read<AuthRepository>()),
      child: Container(
        decoration: BoxDecoration(gradient: gradient),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          resizeToAvoidBottomInset: false,
          appBar: AppBar(
            toolbarHeight: 100,
            leading: const BackIconButton(),
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
          body: BlocListener<AuthBloc, AuthState>(
            listenWhen: (previous, current) =>
                previous.status != current.status,
            listener: (context, state) {
              if (state.status == AuthStatus.failure &&
                  state.errorMessage != null) {
                AppNotifications.showError(context, state.errorMessage!);
              }
              if (state.status == AuthStatus.success) {
                if (state.successMessage != null) {
                  AppNotifications.showSuccess(context, state.successMessage!);
                }
                Navigator.of(context).pop();
              }
            },
            child: Form(
              key: _formKey,
              child: SafeArea(
                child: AnimatedPadding(
                  padding: EdgeInsets.only(bottom: keyboardHeight),
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOutCubic,
                  child: CustomScrollView(
                    slivers: [
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20.0,
                            vertical: 24.0,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Icon(
                                Icons.lock_reset_rounded,
                                color: Colors.white,
                                size: 64,
                              ),
                              const SizedBox(height: 24),

                              // Заголовок
                              const Text(
                                'Восстановление доступа',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 28,
                                  letterSpacing: 0.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),

                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16.0),
                                child: Text(
                                  'Введитe адрес электронной почты, на который мы отправим ссылку для безопасного сброса вашего текущего пароля.',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    height: 1.4,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 40),

                              EmailTextForm(controller: _emailController),
                              const SizedBox(height: 20),

                              SendResetPasswordEmailButton(
                                formKey: _formKey,
                                emailController: _emailController,
                              ),

                              const Spacer(flex: 2),
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
      ),
    );
  }
}

class SendResetPasswordEmailButton extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;

  const SendResetPasswordEmailButton({
    super.key,
    required this.formKey,
    required this.emailController,
  });

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select<AuthBloc, bool>(
      (bloc) => bloc.state.status == AuthStatus.loading,
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
                    ResetPasswordRequested(email: emailController.text.trim()),
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
                'Отправить ссылку',
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
