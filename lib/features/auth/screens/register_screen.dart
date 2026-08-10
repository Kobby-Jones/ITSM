// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../providers/auth_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../shared/widgets/gradient_button.dart';
import 'auth_scaffold.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _department = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  bool _agreed = false;

  static const _departments = [
    'Operations',
    'Finance',
    'Human Resources',
    'IT Operations',
    'Engineering',
    'Procurement',
    'Health & Safety',
    'Geology',
    'Plant Maintenance',
  ];

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _department.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreed) {
      context.showSnack('Please accept the terms to continue.', error: true);
      return;
    }
    await ref.read(authProvider.notifier).register(
          name: _name.text,
          email: _email.text,
          department: _department.text,
          password: _password.text,
        );
    if (!mounted) return;
    if (ref.read(authProvider).isAuthenticated) {
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    return AuthScaffold(
      title: 'Create your account',
      subtitle: 'Get set up in less than a minute.',
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _label('Full name'),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                hintText: 'Akosua Mensah',
                prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            _label('Work email'),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'name@company.gh',
                prefixIcon: Icon(Icons.alternate_email_rounded, size: 20),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (!v.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 16),
            _label('Department'),
            DropdownButtonFormField<String>(
              value: _department.text.isEmpty ? null : _department.text,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.apartment_rounded, size: 20),
                hintText: 'Select your department',
              ),
              items: [
                for (final d in _departments)
                  DropdownMenuItem(value: d, child: Text(d)),
              ],
              onChanged: (v) => _department.text = v ?? '',
              validator: (v) => v == null ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            _label('Password'),
            TextFormField(
              controller: _password,
              obscureText: _obscure,
              decoration: InputDecoration(
                hintText: 'At least 8 characters',
                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (v.length < 8) return 'Min. 8 characters';
                return null;
              },
            ),
            const SizedBox(height: 16),
            _label('Confirm password'),
            TextFormField(
              controller: _confirm,
              obscureText: _obscure,
              decoration: const InputDecoration(
                hintText: 'Re-enter password',
                prefixIcon: Icon(Icons.lock_outline_rounded, size: 20),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (v != _password.text) return 'Passwords do not match';
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: _agreed,
                  onChanged: (v) => setState(() => _agreed = v ?? false),
                  visualDensity: VisualDensity.compact,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          color: context.colors.onSurface.withOpacity(0.7),
                          fontSize: 12.5,
                          height: 1.4,
                        ),
                        children: [
                          const TextSpan(text: 'I agree to the '),
                          TextSpan(
                            text: 'Terms of Service',
                            style: TextStyle(
                                color: context.colors.primary, fontWeight: FontWeight.w600),
                          ),
                          const TextSpan(text: ' and '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: TextStyle(
                                color: context.colors.primary, fontWeight: FontWeight.w600),
                          ),
                          const TextSpan(text: '.'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GradientButton(
              label: 'Create account',
              icon: Icons.person_add_alt_1_rounded,
              loading: auth.loading,
              onPressed: _submit,
            ),
            const SizedBox(height: 20),
            Center(
              child: Wrap(
                children: [
                  Text('Already have an account? ',
                      style: TextStyle(color: context.colors.onSurface.withOpacity(0.7))),
                  GestureDetector(
                    onTap: () => context.go(AppRoutes.login),
                    child: Text(
                      'Sign in',
                      style: TextStyle(
                        color: context.colors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
