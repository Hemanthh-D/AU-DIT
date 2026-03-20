import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/session/session_provider.dart';
import '../core/ui/app_spacing.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscure = true;
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim().toLowerCase();
    if (email.isEmpty) {
      setState(() => _error = 'Please enter your email.');
      return;
    }

    setState(() {
      _error = null;
      _isSubmitting = true;
    });

    context.read<SessionProvider>().login(email: email);

    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final minHeight = size.height - padding.top - padding.bottom;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.primary.withAlpha(25),
              scheme.surface,
              scheme.secondary.withAlpha(20),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: minHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 48),
                      _Header(),
                      const SizedBox(height: 48),
                      _LoginCard(
                        emailController: _emailController,
                        passwordController: _passwordController,
                        obscure: _obscure,
                        onObscureToggle: () => setState(() => _obscure = !_obscure),
                        error: _error,
                        onErrorClear: () => setState(() => _error = null),
                        isSubmitting: _isSubmitting,
                        onLogin: _handleLogin,
                      ),
                      const Spacer(),
                      _TestAccounts(
                        onSelect: (email) {
                          setState(() {
                            _emailController.text = email;
                            _passwordController.text = 'password';
                            _error = null;
                          });
                        },
                      ),
                      const SizedBox(height: 32),
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

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 56,
          width: 56,
          decoration: BoxDecoration(
            color: scheme.primaryContainer.withAlpha(180),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withAlpha(40),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(Icons.shield_rounded, color: scheme.primary, size: 28),
        ),
        const SizedBox(height: 20),
        Text(
          'AU-DIT',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                color: scheme.onSurface,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Smart Campus Complaint System',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.emailController,
    required this.passwordController,
    required this.obscure,
    required this.onObscureToggle,
    required this.error,
    required this.onErrorClear,
    required this.isSubmitting,
    required this.onLogin,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscure;
  final VoidCallback onObscureToggle;
  final String? error;
  final VoidCallback onErrorClear;
  final bool isSubmitting;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outlineVariant.withAlpha(150)),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withAlpha(25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Sign in',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Use a test account or enter any email to continue as student.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            onChanged: (_) => onErrorClear(),
            decoration: InputDecoration(
              labelText: 'Email',
              hintText: 'your@campus.edu',
              prefixIcon: Icon(Icons.alternate_email_rounded, size: 20, color: scheme.onSurfaceVariant),
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: passwordController,
            obscureText: obscure,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onLogin(),
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: '••••••••',
              prefixIcon: Icon(Icons.lock_outline_rounded, size: 20, color: scheme.onSurfaceVariant),
              suffixIcon: IconButton(
                onPressed: onObscureToggle,
                icon: Icon(
                  obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 20,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            Text(
              error!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.error,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: isSubmitting ? null : onLogin,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: isSubmitting
                ? SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: scheme.onPrimary),
                  )
                : const Text('Continue'),
          ),
        ],
      ),
    );
  }
}

class _TestAccounts extends StatelessWidget {
  const _TestAccounts({required this.onSelect});

  final void Function(String email) onSelect;

  static const _accounts = [
    ('Student', 'student@campus.edu'),
    ('Tech 1', 'tech1@campus.edu'),
    ('Tech 2', 'tech2@campus.edu'),
    ('Counselor', 'counselor@campus.edu'),
    ('Admin', 'admin@campus.edu'),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick test accounts',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _accounts.map((e) {
            return FilterChip(
              label: Text(e.$1, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              selected: false,
              onSelected: (_) => onSelect(e.$2),
              backgroundColor: scheme.surfaceContainerHighest.withAlpha(120),
              selectedColor: scheme.primaryContainer,
              side: BorderSide(color: scheme.outlineVariant.withAlpha(150)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            );
          }).toList(),
        ),
      ],
    );
  }
}
