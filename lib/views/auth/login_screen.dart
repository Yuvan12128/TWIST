import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/cached_image.dart';
import '../../widgets/twist_button.dart';
import '../main_navigation_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isGoogleLoading = false;
  bool _isGuestLoading = false;

  void _showEmailSheet({bool isSignUp = false}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => _EmailAuthBottomSheet(initialIsSignUp: isSignUp),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isGoogleLoading = true);
    final authProv = context.read<AuthProvider>();
    final success = await authProv.signInWithGoogle();
    setState(() => _isGoogleLoading = false);

    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    } else if (mounted && authProv.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProv.errorMessage!),
          backgroundColor: AppColors.accentRed,
        ),
      );
    }
  }

  Future<void> _handleGuestSignIn() async {
    setState(() => _isGuestLoading = true);
    final authProv = context.read<AuthProvider>();
    final success = await authProv.signInAsGuest();
    setState(() => _isGuestLoading = false);

    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    } else if (mounted && authProv.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProv.errorMessage!),
          backgroundColor: AppColors.accentRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Ambient background artwork with dark gradient overlay
          Positioned.fill(
            child: Opacity(
              opacity: 0.35,
              child: CachedImage(
                imageUrl: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=1200&auto=format&fit=crop&q=80',
                fit: BoxFit.cover,
                errorWidget: const SizedBox(),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xB3090A0F),
                    Color(0xE6090A0F),
                    AppColors.background,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // Main Interactive Layout
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Spacer(flex: 1),

                          // Brand Logo Emblem
                          ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.asset(
                              'assets/images/logo.png',
                              width: 80,
                              height: 80,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Brand Header: Yellow TWIST + Tagline
                          Text(
                            AppStrings.appName,
                            style: AppTypography.brandTitle.copyWith(
                              fontSize: 42,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.0,
                              color: AppColors.primaryYellow,
                            ),
                          ),
                          const SizedBox(height: 8),

                          Text(
                            AppStrings.appTagline,
                            style: AppTypography.splashTagline.copyWith(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w500,
                              color: AppColors.secondaryText,
                            ),
                          ),

                          const Spacer(flex: 2),

                          // Buttons matching Reference Panel 2
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // 1. Continue with Google (White button)
                              TwistButton(
                                text: context.tr('continue_with_google'),
                                icon: CachedImage(
                                  imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1200px-Google_%22G%22_logo.svg.png',
                                  width: 20,
                                  height: 20,
                                  fit: BoxFit.contain,
                                  errorWidget: const Icon(
                                    Icons.g_mobiledata_rounded,
                                    color: Colors.red,
                                    size: 24,
                                  ),
                                ),
                                variant: TwistButtonVariant.white,
                                isLoading: _isGoogleLoading,
                                onPressed: _handleGoogleSignIn,
                              ),
                              const SizedBox(height: 14),

                              // 2. Continue with Email (Dark card button)
                              TwistButton(
                                text: context.tr('continue_with_email'),
                                icon: const Icon(Icons.email_outlined, color: Colors.white, size: 20),
                                variant: TwistButtonVariant.glass,
                                onPressed: () => _showEmailSheet(),
                              ),
                              const SizedBox(height: 18),

                              // "or" Divider
                              Row(
                                children: [
                                  const Expanded(child: Divider(color: AppColors.border, thickness: 1)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 14.0),
                                    child: Text(
                                      'or',
                                      style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                                    ),
                                  ),
                                  const Expanded(child: Divider(color: AppColors.border, thickness: 1)),
                                ],
                              ),
                              const SizedBox(height: 18),

                              // 3. Continue as Guest (Dark card button)
                              TwistButton(
                                text: context.tr('continue_as_guest'),
                                icon: const Icon(Icons.person_outline_rounded, color: Colors.white, size: 20),
                                variant: TwistButtonVariant.glass,
                                isLoading: _isGuestLoading,
                                onPressed: _handleGuestSignIn,
                              ),
                            ],
                          ),

                          const Spacer(flex: 2),

                          // Footer: Terms of Service and Privacy Policy with Yellow highlight
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                                children: const [
                                  TextSpan(text: 'By continuing, you agree to our\n'),
                                  TextSpan(
                                    text: 'Terms of Service',
                                    style: TextStyle(
                                      color: AppColors.primaryYellow,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  TextSpan(text: ' and '),
                                  TextSpan(
                                    text: 'Privacy Policy',
                                    style: TextStyle(
                                      color: AppColors.primaryYellow,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmailAuthBottomSheet extends StatefulWidget {
  final bool initialIsSignUp;
  const _EmailAuthBottomSheet({this.initialIsSignUp = false});

  @override
  State<_EmailAuthBottomSheet> createState() => _EmailAuthBottomSheetState();
}

class _EmailAuthBottomSheetState extends State<_EmailAuthBottomSheet> {
  late bool _isSignUp;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  String? _localError;

  @override
  void initState() {
    super.initState();
    _isSignUp = widget.initialIsSignUp;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      setState(() => _localError = 'Please enter a valid email address.');
      return;
    }
    if (password.length < 6) {
      setState(() => _localError = 'Password must be at least 6 characters.');
      return;
    }

    setState(() {
      _isLoading = true;
      _localError = null;
    });

    final authProv = context.read<AuthProvider>();
    bool success;
    if (_isSignUp) {
      success = await authProv.signUpWithEmail(email, password, name);
    } else {
      success = await authProv.signInWithEmail(email, password);
    }

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.of(context).pop(); // close sheet
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    } else if (mounted) {
      setState(() {
        _localError = authProv.errorMessage ?? 'Authentication failed. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isSignUp ? context.tr('sign_up') : context.tr('sign_in'),
                  style: AppTypography.screenTitle.copyWith(fontSize: 20),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_localError != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accentRed.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accentRed.withOpacity(0.4)),
                ),
                child: Text(
                  _localError!,
                  style: const TextStyle(color: AppColors.accentRed, fontSize: 13),
                ),
              ),
              const SizedBox(height: 14),
            ],

            if (_isSignUp) ...[
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: context.tr('storyteller_alias'),
                  prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.textMuted),
                ),
              ),
              const SizedBox(height: 14),
            ],

            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: context.tr('email_address'),
                prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textMuted),
              ),
            ),
            const SizedBox(height: 14),

            TextField(
              controller: _passwordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: context.tr('password'),
                prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.textMuted),
              ),
            ),
            const SizedBox(height: 20),

            TwistButton(
              text: _isSignUp ? context.tr('join_twist') : context.tr('sign_in'),
              isLoading: _isLoading,
              onPressed: _submit,
            ),
            const SizedBox(height: 14),

            Center(
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _isSignUp = !_isSignUp;
                    _localError = null;
                  });
                },
                child: Text(
                  _isSignUp
                      ? context.tr('already_have_account')
                      : context.tr('dont_have_account'),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.primaryYellow,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
