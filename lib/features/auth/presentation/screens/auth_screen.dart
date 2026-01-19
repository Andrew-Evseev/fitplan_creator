import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:fitplan_creator/core/constants/app_colors.dart';
import 'package:fitplan_creator/core/widgets/custom_button.dart';
import 'package:fitplan_creator/core/widgets/button_variant.dart';
import 'package:fitplan_creator/features/auth/services/auth_service.dart';
import 'package:fitplan_creator/data/repositories/preferences_repository.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _authService = AuthService();
  final _preferencesRepo = PreferencesRepository();
  
  bool _isLoginMode = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isLoginMode) {
        // Вход существующего пользователя
        print('🔐 Попытка входа: ${_emailController.text.trim()}');
        final user = await _authService.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        print('✅ Вход успешен: ${user.id}');
      } else {
        // Регистрация нового пользователя
        final name = _nameController.text.trim().isNotEmpty
            ? _nameController.text.trim()
            : _emailController.text.trim().split('@')[0];
        
        print('📝 Попытка регистрации: ${_emailController.text.trim()}, имя: $name');
        final user = await _authService.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          name: name,
        );
        print('✅ Регистрация успешна: ${user.id}, email: ${user.email}');
        print('📧 Email подтвержден: ${user.emailConfirmedAt != null}');
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        // Проверяем, проходил ли пользователь анкету
        await _redirectAfterAuth();
      }
    } on supabase.AuthException catch (e) {
      print('❌ Ошибка авторизации: ${e.message}');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = _getErrorMessage(e.message);
        });
      }
    } catch (e, stackTrace) {
      print('❌ Неожиданная ошибка: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Произошла ошибка: $e';
        });
      }
    }
  }

  String _getErrorMessage(String message) {
    if (message.contains('email_provider_disabled') || message.contains('Email provider disabled')) {
      return 'Email аутентификация отключена. Обратитесь к администратору.';
    } else if (message.contains('Invalid login credentials') || message.contains('Invalid credentials')) {
      return 'Неверный email или пароль';
    } else if (message.contains('User already registered') || message.contains('already registered')) {
      return 'Пользователь с таким email уже зарегистрирован';
    } else if (message.contains('Password') || message.contains('password')) {
      return 'Пароль должен содержать минимум 6 символов';
    } else if (message.contains('Email') || message.contains('email')) {
      return 'Некорректный email адрес';
    } else if (message.contains('email_not_confirmed') || message.contains('Email not confirmed')) {
      return 'Пожалуйста, подтвердите email. Проверьте почту.';
    } else if (message.contains('signup_disabled')) {
      return 'Регистрация временно отключена';
    }
    return message.isNotEmpty ? message : 'Произошла неизвестная ошибка';
  }

  /// Перенаправление после успешной авторизации/регистрации
  Future<void> _redirectAfterAuth() async {
    try {
      print('🔍 Проверка preferences пользователя...');
      // Проверяем, есть ли у пользователя сохраненные preferences
      final preferences = await _preferencesRepo.getPreferences();
      
      if (preferences == null) {
        print('📝 Preferences не найдены, переход на анкету');
        if (mounted) {
          context.go('/questionnaire');
        }
        return;
      }
      
      print('📋 Preferences найдены:');
      print('  - isComplete: ${preferences.isComplete}');
      print('  - gender: ${preferences.gender}');
      print('  - age: ${preferences.age}');
      print('  - goal: ${preferences.goal}');
      
      if (preferences.isComplete) {
        // Пользователь уже проходил анкету - переходим в личный кабинет
        print('✅ Пользователь уже проходил анкету, переход в личный кабинет');
        if (mounted) {
          context.go('/planner');
        }
      } else {
        // Preferences есть, но не заполнены полностью - переходим на анкету
        print('📝 Preferences не заполнены полностью, переход на анкету');
        if (mounted) {
          context.go('/questionnaire');
        }
      }
    } catch (e, stackTrace) {
      // В случае ошибки переходим на анкету
      print('⚠️ Ошибка при проверке preferences: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        context.go('/questionnaire');
      }
    }
  }

  void _skipAuth() {
    context.go('/questionnaire');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                
                // Логотип
                const Icon(
                  Icons.fitness_center,
                  size: 80,
                  color: AppColors.primaryColor,
                ),
                const SizedBox(height: 24),
                
                // Заголовок
                Text(
                  _isLoginMode ? 'Вход' : 'Регистрация',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                
                // Подзаголовок
                Text(
                  _isLoginMode
                      ? 'Войдите в свой аккаунт'
                      : 'Создайте новый аккаунт',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                
                // Поле имени (только для регистрации)
                if (!_isLoginMode) ...[
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Имя',
                      hintText: 'Введите ваше имя',
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (value) {
                      if (!_isLoginMode && (value == null || value.isEmpty)) {
                        return 'Введите ваше имя';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Поле email/логина
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email или логин',
                    hintText: 'Введите email или логин',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Введите email';
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Введите корректный email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Поле пароля
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Пароль',
                    hintText: 'Введите пароль',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Введите пароль';
                    }
                    if (!_isLoginMode && value.length < 6) {
                      return 'Пароль должен содержать минимум 6 символов';
                    }
                    if (!_isLoginMode && value.length > 72) {
                      return 'Пароль слишком длинный (максимум 72 символа)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Поле подтверждения пароля (только для регистрации)
                if (!_isLoginMode) ...[
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Подтвердите пароль',
                      hintText: 'Повторите пароль',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Подтвердите пароль';
                      }
                      if (value != _passwordController.text) {
                        return 'Пароли не совпадают';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Отображение ошибки
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Кнопка входа/регистрации
                CustomButton(
                  text: _isLoginMode ? 'Войти' : 'Зарегистрироваться',
                  onPressed: _handleSubmit,
                  isLoading: _isLoading,
                  fullWidth: true,
                ),
                const SizedBox(height: 16),
                
                // Переключение между входом и регистрацией
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isLoginMode
                          ? 'Нет аккаунта? '
                          : 'Уже есть аккаунт? ',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isLoginMode = !_isLoginMode;
                          _errorMessage = null;
                          _formKey.currentState?.reset();
                        });
                      },
                      child: Text(
                        _isLoginMode ? 'Зарегистрироваться' : 'Войти',
                        style: const TextStyle(
                          color: AppColors.primaryColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Разделитель
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey[300])),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'или',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey[300])),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Кнопка пропуска
                CustomButton(
                  text: 'Попробовать без регистрации',
                  onPressed: _skipAuth,
                  variant: ButtonVariant.outline,
                  fullWidth: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
