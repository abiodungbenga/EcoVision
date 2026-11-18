import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../shared/widgets/app_logo.dart';

class AuthView extends StatefulWidget {
  const AuthView({super.key});

  @override
  State<AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends State<AuthView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = Get.find<AuthService>();

  bool _isBusy = false;
  bool _obscurePassword = true;

  Future<void> _signIn() async {
    if (_isBusy || !_formKey.currentState!.validate()) return;
    setState(() => _isBusy = true);
    try {
      await _authService.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (mounted) Get.offAllNamed(AppRoutes.home);
    } on FirebaseAuthException catch (error) {
      if (mounted) SnackbarUtils.showError(_authErrorMessage(error));
    } catch (error) {
      if (mounted) SnackbarUtils.showError('Sign in failed: $error');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _AuthPageLayout(
      title: 'Welcome back',
      subtitle: 'Sign in to keep your fieldwork and observations together.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _emailField(
              controller: _emailController,
              onSubmitted: (_) => FocusScope.of(context).nextFocus(),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                  ),
                ),
              ),
              validator: _validatePassword,
              onFieldSubmitted: (_) => _signIn(),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _isBusy
                    ? null
                    : () => Get.toNamed(AppRoutes.forgotPassword),
                child: const Text('Forgot password?'),
              ),
            ),
            const SizedBox(height: 8),
            _submitButton(
              label: 'Sign in',
              isBusy: _isBusy,
              onPressed: _signIn,
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('New here?'),
                TextButton(
                  onPressed: _isBusy
                      ? null
                      : () => Get.toNamed(AppRoutes.createAccount),
                  child: const Text('Create account'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CreateAccountView extends StatefulWidget {
  const CreateAccountView({super.key});

  @override
  State<CreateAccountView> createState() => _CreateAccountViewState();
}

class _CreateAccountViewState extends State<CreateAccountView> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = Get.find<AuthService>();

  bool _isBusy = false;
  bool _obscurePassword = true;

  Future<void> _createAccount() async {
    if (_isBusy || !_formKey.currentState!.validate()) return;
    setState(() => _isBusy = true);
    try {
      await _authService.createAccount(
        username: _usernameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (mounted) Get.offAllNamed(AppRoutes.home);
    } on FirebaseAuthException catch (error) {
      if (mounted) SnackbarUtils.showError(_authErrorMessage(error));
    } catch (error) {
      if (mounted) SnackbarUtils.showError('Account creation failed: $error');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _AuthPageLayout(
      showBackButton: true,
      title: 'Create your account',
      subtitle: 'Set up an account to keep your fieldwork together.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _usernameController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.nickname],
              decoration: const InputDecoration(
                labelText: 'Username',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter a username.'
                  : null,
            ),
            const SizedBox(height: 14),
            _emailField(
              controller: _emailController,
              onSubmitted: (_) => FocusScope.of(context).nextFocus(),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                  ),
                ),
              ),
              validator: _validatePassword,
              onFieldSubmitted: (_) => _createAccount(),
            ),
            const SizedBox(height: 20),
            _submitButton(
              label: 'Create account',
              isBusy: _isBusy,
              onPressed: _createAccount,
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('Already have an account?'),
                TextButton(
                  onPressed: _isBusy ? null : () => Get.back(),
                  child: const Text('Sign in'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _authService = Get.find<AuthService>();

  bool _isBusy = false;

  Future<void> _sendResetLink() async {
    if (_isBusy || !_formKey.currentState!.validate()) return;
    setState(() => _isBusy = true);
    try {
      await _authService.sendPasswordResetEmail(_emailController.text);
      if (!mounted) return;
      Get.back();
      SnackbarUtils.showSuccess('Password reset link sent to your email.');
    } on FirebaseAuthException catch (error) {
      if (mounted) SnackbarUtils.showError(_authErrorMessage(error));
    } catch (error) {
      if (mounted) SnackbarUtils.showError('Could not send reset link: $error');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _AuthPageLayout(
      showBackButton: true,
      title: 'Reset your password',
      subtitle: 'We will email you a link to choose a new password.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _emailField(
              controller: _emailController,
              onSubmitted: (_) => _sendResetLink(),
            ),
            const SizedBox(height: 20),
            _submitButton(
              label: 'Send reset link',
              isBusy: _isBusy,
              onPressed: _sendResetLink,
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('Remember your password?'),
                TextButton(
                  onPressed: _isBusy ? null : () => Get.back(),
                  child: const Text('Sign in'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthPageLayout extends StatelessWidget {
  const _AuthPageLayout({
    required this.title,
    required this.subtitle,
    required this.child,
    this.showBackButton = false,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Scaffold(
      appBar: showBackButton
          ? AppBar(
              leading: BackButton(onPressed: () => Get.back()),
              backgroundColor: Colors.transparent,
            )
          : null,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => Get.focusScope?.unfocus(),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(
                      child: AppLogo(showWordmark: true, width: 188),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: AppTypography.heading.copyWith(
                        color: palette.text,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: AppTypography.body.copyWith(
                        color: palette.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 28),
                    child,
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

Widget _emailField({
  required TextEditingController controller,
  required ValueChanged<String> onSubmitted,
}) {
  return TextFormField(
    controller: controller,
    keyboardType: TextInputType.emailAddress,
    textInputAction: TextInputAction.next,
    autofillHints: const [AutofillHints.email],
    decoration: const InputDecoration(
      labelText: 'Email',
      prefixIcon: Icon(Icons.email_outlined),
    ),
    validator: (value) {
      final email = value?.trim() ?? '';
      return email.isEmpty || !email.contains('@')
          ? 'Enter a valid email address.'
          : null;
    },
    onFieldSubmitted: onSubmitted,
  );
}

String? _validatePassword(String? value) {
  if (value == null || value.length < 6) {
    return 'Use a password with at least 6 characters.';
  }
  return null;
}

Widget _submitButton({
  required String label,
  required bool isBusy,
  required VoidCallback onPressed,
}) {
  return FilledButton(
    onPressed: isBusy ? null : onPressed,
    child: isBusy
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
        : Text(label),
  );
}

String _authErrorMessage(FirebaseAuthException error) {
  switch (error.code) {
    case 'email-already-in-use':
      return 'An account already exists for this email.';
    case 'invalid-email':
      return 'Enter a valid email address.';
    case 'weak-password':
      return 'Choose a stronger password with at least 6 characters.';
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
      return 'The email or password is incorrect.';
    case 'network-request-failed':
      return 'Check your internet connection and try again.';
    case 'too-many-requests':
      return 'Too many attempts. Please wait and try again.';
    default:
      return error.message ?? 'Authentication failed. Please try again.';
  }
}
