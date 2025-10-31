import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../main.dart';
import '../widgets/support_fab.dart';

enum PasswordStrength {
  empty,
  veryWeak,
  weak,
  medium,
  strong,
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLogin = true;
  bool _isPasswordObscured = true;
  PasswordStrength _passwordStrength = PasswordStrength.empty;

  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;
  late TextEditingController _displayNameController;
  late TextEditingController _phoneNumberController;
  late TextEditingController _dobController;
  late TextEditingController _countryController;
  late TextEditingController _provinceController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _displayNameController = TextEditingController();
    _phoneNumberController = TextEditingController();
    _dobController = TextEditingController();
    _countryController = TextEditingController();
    _provinceController = TextEditingController();
    
    _passwordController.addListener(_updatePasswordStrength);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _displayNameController.dispose();
    _phoneNumberController.dispose();
    _dobController.dispose();
    _countryController.dispose();
    _provinceController.dispose();
    super.dispose();
  }

  void _updatePasswordStrength() {
    final password = _passwordController.text;
    if (password.isEmpty) {
      setState(() => _passwordStrength = PasswordStrength.empty);
      return;
    }

    double strength = 0;
    if (password.length >= 8) strength += 0.25;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength += 0.25;
    if (RegExp(r'[a-z]').hasMatch(password)) strength += 0.25;
    if (RegExp(r'[0-9]').hasMatch(password)) strength += 0.25;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)) strength += 0.25;

    strength = strength > 1.0 ? 1.0 : strength;

    if (strength < 0.3) {
      setState(() => _passwordStrength = PasswordStrength.veryWeak);
    } else if (strength < 0.6) {
      setState(() => _passwordStrength = PasswordStrength.weak);
    } else if (strength < 0.9) {
      setState(() => _passwordStrength = PasswordStrength.medium);
    } else {
      setState(() => _passwordStrength = PasswordStrength.strong);
    }
  }
  
  String? _validateDOB(String? value) {
    if (value == null || value.isEmpty) {
      return 'Insira a sua data de nascimento.';
    }
    try {
      final parts = value.split('/');
      if (parts.length != 3) return 'Formato inválido. Use DD/MM/AAAA.';
      
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);

      final birthDate = DateTime(year, month, day);
      final today = DateTime.now();
      int age = today.year - birthDate.year;
      
      if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }
      
      if (age < 18) {
        return 'Você deve ter pelo menos 18 anos para se registar.';
      }
    } catch (e) {
      return 'Data inválida. Use o formato DD/MM/AAAA.';
    }
    return null;
  }

  void _trySubmit() async {
    final isValid = _formKey.currentState!.validate();
    FocusScope.of(context).unfocus();

    final authService = context.read<AuthService>();

    if (isValid) {
      authService.setLoading(true);
      final locationService = LocationService();
      final scaffoldMessenger = ScaffoldMessenger.of(context);

      try {
        if (_isLogin) {
          await authService.signInWithEmailPassword(
            _emailController.text,
            _passwordController.text,
          );
          await locationService.handleLocationPermission();
        } else {
          await authService.signUpWithEmailPassword(
            _emailController.text,
            _passwordController.text,
            _displayNameController.text,
            _phoneNumberController.text,
            _dobController.text,
            _countryController.text,
            _provinceController.text,
          );
        }
      } on EmailNotVerifiedException {
        // Handled by global redirect
      } catch (err) {
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(err.toString().replaceAll('Exception: ', '')),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      } finally {
        authService.setLoading(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final authService = context.watch<AuthService>();

    return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        floatingActionButton: const SupportFab(),
        body: Stack(
          children: [
            _buildBackground(theme, isDarkMode),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildHeader(theme),
                    const SizedBox(height: 32),
                    _buildAuthCard(theme, authService.isLoading),
                    const SizedBox(height: 24),
                    _buildSecurityFooter(theme), 
                  ],
                ),
              ),
            ),
          ],
        ),
      );
  }

  Widget _buildBackground(ThemeData theme, bool isDarkMode) {
    return ClipPath(
      clipper: AuthWaveClipper(),
      child: Container(
        height: 300,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primaryGreen.withAlpha(isDarkMode ? 180 : 255),
              AppColors.secondaryBlue,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      children: [
        Image.asset(
          'assets/afercon.logo.png',
          height: 100,
        ),
        const SizedBox(height: 24),
        Text(
          _isLogin ? 'Bem-vindo de volta!' : 'Crie a sua conta',
          style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          _isLogin ? 'Entre para continuar' : 'Comece a usar o Afercon Pay',
          style: theme.textTheme.titleMedium,
        ),
      ],
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _buildAuthCard(ThemeData theme, bool isLoading) {
    return Card(
      elevation: 8,
      shadowColor: theme.shadowColor.withAlpha(25),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!_isLogin) ..._buildRegisterFields(),
              if (_isLogin) ..._buildLoginFields(),
              const SizedBox(height: 24),
              _buildAuthButtons(theme, isLoading),
              const SizedBox(height: 16),
              TextButton(
                onPressed: isLoading
                    ? null
                    : () {
                        if (mounted) {
                          setState(() => _isLogin = !_isLogin);
                        }
                      },
                child: Text(_isLogin ? 'Criar nova conta' : 'Já tenho uma conta'),
              ),
              if (_isLogin)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: isLoading ? null : () => context.push('/reset-password'),
                    child: const Text('Esqueceu a senha?'),
                  ),
                ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2, curve: Curves.easeOutCubic);
  }

  List<Widget> _buildLoginFields() {
      return [
          TextFormField(
              controller: _emailController,
              key: const ValueKey('email'),
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Iconsax.direct)),
              validator: (value) => (value == null || !value.contains('@')) ? 'Email inválido.' : null,
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            key: const ValueKey('password'),
            obscureText: _isPasswordObscured,
            decoration: InputDecoration(
              labelText: 'Senha',
              prefixIcon: const Icon(Iconsax.key),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordObscured ? Iconsax.eye_slash : Iconsax.eye,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordObscured = !_isPasswordObscured;
                  });
                },
              ),
            ),
            validator: (value) => (value == null || value.isEmpty) ? 'A senha não pode estar em branco.' : null,
          ).animate().fadeIn(delay: 300.ms),
      ];
  }

  List<Widget> _buildRegisterFields() {
      return [
          TextFormField(
              controller: _displayNameController,
              key: const ValueKey('displayName'),
              decoration: const InputDecoration(labelText: 'Nome Completo', prefixIcon: Icon(Iconsax.user)),
              validator: (value) => (value == null || value.isEmpty) ? 'Insira o seu nome.' : null,
          ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.2),
          const SizedBox(height: 16),
          TextFormField(
              controller: _phoneNumberController,
              key: const ValueKey('phoneNumber'),
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Número de Telefone', prefixIcon: Icon(Iconsax.call)),
              validator: (value) => (value == null || value.length < 9) ? 'Insira um número de telefone válido.' : null,
          ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.2),
           const SizedBox(height: 16),
          TextFormField(
            controller: _dobController,
            key: const ValueKey('dob'),
            decoration: const InputDecoration(
              labelText: 'Data de Nascimento (DD/MM/AAAA)',
              prefixIcon: Icon(Iconsax.calendar),
            ),
            validator: _validateDOB,
          ).animate().fadeIn(delay: 400.ms),
          const SizedBox(height: 16),
          TextFormField(
            controller: _countryController,
            key: const ValueKey('country'),
            decoration: const InputDecoration(
              labelText: 'País',
              prefixIcon: Icon(Iconsax.location),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Insira o seu país.';
              }
              return null;
            },
          ).animate().fadeIn(delay: 500.ms),
          const SizedBox(height: 16),
          TextFormField(
            controller: _provinceController,
            key: const ValueKey('province'),
            decoration: const InputDecoration(
              labelText: 'Província',
              prefixIcon: Icon(Iconsax.map),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Insira a sua província.';
              }
              return null;
            },
          ).animate().fadeIn(delay: 600.ms),
          const SizedBox(height: 16),
          TextFormField(
              controller: _emailController,
              key: const ValueKey('email_register'),
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Iconsax.direct)),
              validator: (value) => (value == null || !value.contains('@')) ? 'Email inválido.' : null,
          ).animate().fadeIn(delay: 700.ms),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            key: const ValueKey('password_register'),
            obscureText: _isPasswordObscured,
            decoration: InputDecoration(
              labelText: 'Senha',
              prefixIcon: const Icon(Iconsax.key),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordObscured ? Iconsax.eye_slash : Iconsax.eye,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordObscured = !_isPasswordObscured;
                  });
                },
              ),
            ),
             validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, insira uma senha.';
              }
              if (_passwordStrength != PasswordStrength.strong && _passwordStrength != PasswordStrength.medium) {
                return 'A senha deve ser média ou forte.';
              }
              return null;
            },
          ).animate().fadeIn(delay: 800.ms),
          const SizedBox(height: 12),
          PasswordStrengthIndicator(strength: _passwordStrength),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmPasswordController,
            key: const ValueKey('confirm_password'),
            obscureText: _isPasswordObscured,
            decoration: const InputDecoration(
              labelText: 'Confirmar Senha',
              prefixIcon: Icon(Iconsax.key),
            ),
            validator: (value) {
              if (value != _passwordController.text) {
                return 'As senhas não correspondem.';
              }
              return null;
            },
          ).animate().fadeIn(delay: 900.ms),
      ];
  }

  Widget _buildAuthButtons(ThemeData theme, bool isLoading) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : _trySubmit,
        child: Text(_isLogin ? 'Entrar' : 'Registar'),
      ),
    ).animate().fadeIn(delay: 600.ms);
  }

   Widget _buildSecurityFooter(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.shield_tick,
            size: 16,
            color: theme.textTheme.bodySmall?.color?.withAlpha((255 * 0.6).round()),
          ),
          const SizedBox(width: 8),
          Text(
            'A sua segurança é a nossa prioridade. Nunca partilhe a sua senha.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withAlpha((255 * 0.6).round()),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 800.ms);
  }
}

class PasswordStrengthIndicator extends StatelessWidget {
  final PasswordStrength strength;

  const PasswordStrengthIndicator({super.key, required this.strength});

  @override
  Widget build(BuildContext context) {
    if (strength == PasswordStrength.empty) {
      return const SizedBox.shrink();
    }

    final double value = _getStrengthValue();
    final Color color = _getStrengthColor();
    final String text = _getStrengthText();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: value,
          backgroundColor: Colors.grey[300],
          color: color,
          minHeight: 6,
        ),
        const SizedBox(height: 4),
        Text(text, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color)),
      ],
    ).animate().fadeIn();
  }

  double _getStrengthValue() {
    switch (strength) {
      case PasswordStrength.veryWeak:
        return 0.2;
      case PasswordStrength.weak:
        return 0.4;
      case PasswordStrength.medium:
        return 0.7;
      case PasswordStrength.strong:
        return 1.0;
      default:
        return 0.0;
    }
  }

  Color _getStrengthColor() {
    switch (strength) {
      case PasswordStrength.veryWeak:
        return Colors.red;
      case PasswordStrength.weak:
        return Colors.orange;
      case PasswordStrength.medium:
        return Colors.yellow.shade700;
      case PasswordStrength.strong:
        return AppColors.primaryGreen;
      default:
        return Colors.transparent;
    }
  }

  String _getStrengthText() {
    switch (strength) {
      case PasswordStrength.veryWeak:
        return 'Muito Fraca';
      case PasswordStrength.weak:
        return 'Fraca';
      case PasswordStrength.medium:
        return 'Média';
      case PasswordStrength.strong:
        return 'Forte';
      default:
        return '';
    }
  }
}

class AuthWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height * 0.8);
    path.quadraticBezierTo(size.width / 4, size.height, size.width / 2, size.height * 0.8);
    path.quadraticBezierTo(size.width * 3 / 4, size.height * 0.6, size.width, size.height * 0.7);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}