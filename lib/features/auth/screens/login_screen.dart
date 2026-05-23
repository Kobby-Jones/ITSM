import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/responsive.dart';
import '../../../providers/auth_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../shared/widgets/gradient_button.dart';
import 'auth_scaffold.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController(text: 'tech@goldfields.gh');
  final _passwordCtrl = TextEditingController(text: 'demo1234');
  bool _obscure = true;
  bool _remember = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authProvider.notifier).login(_emailCtrl.text, _passwordCtrl.text);
    if (!mounted) return;
    final auth = ref.read(authProvider);
    if (auth.isAuthenticated) {
      context.go(AppRoutes.home);
    } else if (auth.error != null) {
      context.showSnack(auth.error!, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return AuthScaffold(
      title: 'Welcome back',
      subtitle: 'Sign in to continue to your service desk.',
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _label('Work email'),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                hintText: 'name@company.gh',
                prefixIcon: Icon(Icons.alternate_email_rounded, size: 20),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Email is required';
                if (!v.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 18),
            _label('Password'),
            TextFormField(
              controller: _passwordCtrl,
              obscureText: _obscure,
              autofillHints: const [AutofillHints.password],
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                hintText: '••••••••',
                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Password is required' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Checkbox(
                  value: _remember,
                  onChanged: (v) => setState(() => _remember = v ?? false),
                  visualDensity: VisualDensity.compact,
                ),
                const Text('Remember me', style: TextStyle(fontSize: 13)),
                const Spacer(),
                TextButton(
                  onPressed: () => context.go(AppRoutes.forgotPassword),
                  child: const Text('Forgot password?'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GradientButton(
              label: 'Sign in',
              icon: Icons.login_rounded,
              loading: auth.loading,
              onPressed: _submit,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: Divider(color: context.colors.outline)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('or',
                      style: TextStyle(color: context.colors.onSurface.withOpacity(0.5), fontSize: 12)),
                ),
                Expanded(child: Divider(color: context.colors.outline)),
              ],
            ),
            const SizedBox(height: 16),
            _DemoAccountsPanel(
              onSelect: (email) {
                _emailCtrl.text = email;
                _passwordCtrl.text = 'demo1234';
                setState(() {});
              },
            ),
            const SizedBox(height: 24),
            Center(
              child: Wrap(
                children: [
                  Text("Don't have an account? ",
                      style: TextStyle(color: context.colors.onSurface.withOpacity(0.7))),
                  GestureDetector(
                    onTap: () => context.go(AppRoutes.register),
                    child: Text(
                      'Create one',
                      style: TextStyle(
                        color: context.colors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (Responsive.isMobile(context)) const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      );
}

class _DemoAccountsPanel extends StatelessWidget {
  final void Function(String email) onSelect;
  const _DemoAccountsPanel({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final accounts = AuthController.demoAccounts;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.science_outlined, size: 16, color: context.colors.primary),
              const SizedBox(width: 8),
              const Text('Demo accounts',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const Spacer(),
              Text('any password',
                  style: TextStyle(
                    fontSize: 11,
                    color: context.colors.onSurface.withOpacity(0.6),
                  )),
            ],
          ),
          const SizedBox(height: 10),
          for (final a in accounts) ...[
            _DemoAccountTile(
              email: a.email,
              role: a.role,
              name: a.name,
              onTap: () => onSelect(a.email),
            ),
            if (a != accounts.last) const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}

class _DemoAccountTile extends StatelessWidget {
  final String email;
  final String role;
  final String name;
  final VoidCallback onTap;

  const _DemoAccountTile({
    required this.email,
    required this.role,
    required this.name,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  Text(email,
                      style: TextStyle(
                          fontSize: 11.5,
                          color: context.colors.onSurface.withOpacity(0.6))),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: context.colors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(role,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: context.colors.primary,
                  )),
            ),
            const SizedBox(width: 6),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 12, color: context.colors.onSurface.withOpacity(0.4)),
          ],
        ),
      ),
    );
  }
}
