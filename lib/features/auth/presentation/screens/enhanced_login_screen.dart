import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:local_auth/local_auth.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_manager.dart';
import '../../../core/responsive/responsive_design.dart';
import '../../../core/components/base_components.dart';
import '../../../core/performance/loading_states.dart';
import '../../../core/performance/animation_optimizer.dart';
import '../../../core/firebase/firebase_manager.dart';
import '../blocs/auth_bloc.dart';

/// Enhanced Material Design 3 Login Screen
class EnhancedLoginScreen extends StatefulWidget {
  const EnhancedLoginScreen({super.key});

  @override
  State<EnhancedLoginScreen> createState() => _EnhancedLoginScreenState();
}

class _EnhancedLoginScreenState extends State<EnhancedLoginScreen>
    with TickerProviderStateMixin {
  
  // Controllers and form handling
  final TextEditingController _phoneController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final LocalAuthentication _localAuth = LocalAuthentication();
  
  // Animation controllers
  late AnimationController _logoAnimationController;
  late AnimationController _formAnimationController;
  late AnimationController _backgroundAnimationController;
  
  // Animations
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoOpacityAnimation;
  late Animation<Offset> _formSlideAnimation;
  late Animation<double> _formOpacityAnimation;
  late Animation<double> _backgroundAnimation;
  
  // State variables
  bool _termsAccepted = false;
  bool _biometricAvailable = false;
  bool _showPhoneField = false;
  String _selectedCountryCode = 'IR';
  String _completePhoneNumber = '';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkBiometricAvailability();
    _trackScreenView();
    
    // Delayed form appearance for better UX
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _showPhoneField = true;
        });
        _formAnimationController.forward();
      }
    });
  }

  /// Initialize animation controllers and animations
  void _initializeAnimations() {
    // Logo animations
    _logoAnimationController = AnimationOptimizer().createOptimizedController(
      this,
      duration: const Duration(milliseconds: 1200),
    );
    
    _logoScaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoAnimationController,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    ));
    
    _logoOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoAnimationController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    ));
    
    // Form animations
    _formAnimationController = AnimationOptimizer().createOptimizedController(
      this,
      duration: const Duration(milliseconds: 800),
    );
    
    _formSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _formAnimationController,
      curve: Curves.easeOutCubic,
    ));
    
    _formOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _formAnimationController,
      curve: Curves.easeOut,
    ));
    
    // Background animation
    _backgroundAnimationController = AnimationOptimizer().createOptimizedController(
      this,
      duration: const Duration(seconds: 20),
    );
    
    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_backgroundAnimationController);
    
    // Start animations
    _logoAnimationController.forward();
    _backgroundAnimationController.repeat();
  }

  /// Check if biometric authentication is available
  Future<void> _checkBiometricAvailability() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      
      setState(() {
        _biometricAvailable = isAvailable && availableBiometrics.isNotEmpty;
      });
    } catch (e) {
      setState(() {
        _biometricAvailable = false;
      });
    }
  }

  /// Track screen view for analytics
  void _trackScreenView() {
    AnalyticsHelper.trackScreenView('enhanced_login_screen');
  }

  /// Handle phone number submission
  Future<void> _submitPhoneNumber() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!_termsAccepted) {
      _showErrorSnackBar('برای ادامه، ابتدا قوانین و مقررات را بپذیرید');
      return;
    }

    // Haptic feedback
    HapticFeedback.lightImpact();
    
    // Track user action
    AnalyticsHelper.trackUserAction('phone_number_submit', parameters: {
      'country_code': _selectedCountryCode,
      'has_biometric': _biometricAvailable,
    });
    
    // Send OTP
    context.read<AuthBloc>().add(SendOtp(phone: _completePhoneNumber));
  }

  /// Handle biometric authentication
  Future<void> _authenticateWithBiometric() async {
    if (!_biometricAvailable) return;

    try {
      HapticFeedback.lightImpact();
      
      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: 'لطفاً هویت خود را تأیید کنید',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (isAuthenticated) {
        // Track successful biometric auth
        AnalyticsHelper.trackUserAction('biometric_auth_success');
        
        // Navigate to dashboard or perform auto-login
        _handleBiometricSuccess();
      }
    } catch (e) {
      // Track biometric auth failure
      AnalyticsHelper.trackError('biometric_auth_error', e.toString());
      _showErrorSnackBar('خطا در احراز هویت بیومتریک');
    }
  }

  /// Handle successful biometric authentication
  void _handleBiometricSuccess() {
    // Check if user has saved credentials
    // For now, show success message
    _showSuccessSnackBar('احراز هویت موفق بود');
    
    // In a real app, you would:
    // 1. Check for saved credentials
    // 2. Auto-login if credentials exist
    // 3. Navigate to dashboard
  }

  /// Handle Google Sign-In
  Future<void> _signInWithGoogle() async {
    try {
      HapticFeedback.lightImpact();
      
      // Track Google sign-in attempt
      AnalyticsHelper.trackUserAction('google_signin_attempt');
      
      final userCredential = await FirebaseManager().signInWithGoogle();
      
      if (userCredential != null) {
        // Track successful Google sign-in
        AnalyticsHelper.trackUserAction('google_signin_success', parameters: {
          'user_id': userCredential.user?.uid,
        });
        
        _showSuccessSnackBar('ورود با Google موفق بود');
        
        // Navigate to dashboard
        if (mounted) {
          context.go('/dashboard');
        }
      }
    } catch (e) {
      // Track Google sign-in error
      AnalyticsHelper.trackError('google_signin_error', e.toString());
      _showErrorSnackBar('خطا در ورود با Google');
    }
  }

  /// Show error snack bar
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Show success snack bar
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveDesign(context);
    final theme = Theme.of(context);
    final themeManager = ThemeManager();
    
    return Scaffold(
      body: Container(
        decoration: _buildBackgroundDecoration(theme, responsive),
        child: SafeArea(
          child: BlocConsumer<AuthBloc, AuthState>(
            listener: _handleAuthStateChanges,
            builder: (context, state) {
              return CustomScrollView(
                slivers: [
                  // App Bar Section
                  SliverAppBar(
                    expandedHeight: responsive.scale(120),
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    flexibleSpace: FlexibleSpaceBar(
                      background: _buildHeaderSection(responsive, theme),
                    ),
                    actions: [
                      // Theme toggle button
                      IconButton(
                        onPressed: () {
                          themeManager.toggleTheme();
                          HapticFeedback.selectionClick();
                        },
                        icon: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Icon(
                            themeManager.isDarkMode 
                                ? Icons.light_mode_rounded
                                : Icons.dark_mode_rounded,
                            key: ValueKey(themeManager.isDarkMode),
                          ),
                        ),
                        tooltip: themeManager.isDarkMode ? 'حالت روشن' : 'حالت تاریک',
                      ),
                    ],
                  ),
                  
                  // Main Content
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: responsive.scale(24),
                      ),
                      child: Column(
                        children: [
                          // Logo Section
                          _buildLogoSection(responsive, theme),
                          
                          SizedBox(height: responsive.scale(40)),
                          
                          // Welcome Text
                          _buildWelcomeText(responsive, theme),
                          
                          SizedBox(height: responsive.scale(32)),
                          
                          // Biometric Authentication Button
                          if (_biometricAvailable)
                            _buildBiometricButton(responsive, theme),
                          
                          if (_biometricAvailable)
                            SizedBox(height: responsive.scale(24)),
                          
                          // Social Login Buttons
                          _buildSocialLoginSection(responsive, theme),
                          
                          SizedBox(height: responsive.scale(24)),
                          
                          // Divider
                          _buildDivider(responsive, theme),
                          
                          SizedBox(height: responsive.scale(24)),
                          
                          // Phone Number Form
                          _buildPhoneNumberForm(responsive, theme, state),
                          
                          const Spacer(),
                          
                          // Terms and Conditions
                          _buildTermsSection(responsive, theme),
                          
                          SizedBox(height: responsive.scale(24)),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// Build background decoration
  BoxDecoration _buildBackgroundDecoration(ThemeData theme, ResponsiveDesign responsive) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          theme.colorScheme.primary.withOpacity(0.1),
          theme.colorScheme.secondary.withOpacity(0.05),
          theme.colorScheme.surface,
        ],
        stops: const [0.0, 0.5, 1.0],
      ),
    );
  }

  /// Build header section
  Widget _buildHeaderSection(ResponsiveDesign responsive, ThemeData theme) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.scale(24),
        vertical: responsive.scale(16),
      ),
      child: Row(
        children: [
          Text(
            'آسود',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const Spacer(),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: responsive.scale(12),
              vertical: responsive.scale(6),
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(responsive.scale(16)),
            ),
            child: Text(
              'نسخه ۱.۰.۰',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontSize: responsive.scale(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build logo section
  Widget _buildLogoSection(ResponsiveDesign responsive, ThemeData theme) {
    return AnimatedBuilder(
      animation: _logoAnimationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _logoScaleAnimation.value,
          child: Opacity(
            opacity: _logoOpacityAnimation.value,
            child: Container(
              width: responsive.scale(120),
              height: responsive.scale(120),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    blurRadius: responsive.scale(20),
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                Icons.home_rounded,
                size: responsive.scale(60),
                color: theme.colorScheme.onPrimary,
              ),
            ),
          ),
        );
      },
    );
  }

  /// Build welcome text
  Widget _buildWelcomeText(ResponsiveDesign responsive, ThemeData theme) {
    return Column(
      children: [
        Text(
          'خوش آمدید',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: responsive.scale(8)),
        Text(
          'برای ادامه وارد حساب کاربری خود شوید',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Build biometric authentication button
  Widget _buildBiometricButton(ResponsiveDesign responsive, ThemeData theme) {
    return AsoudButton(
      text: 'ورود با اثر انگشت',
      onPressed: _authenticateWithBiometric,
      variant: ButtonVariant.outlined,
      icon: Icons.fingerprint_rounded,
      size: ButtonSize.large,
    );
  }

  /// Build social login section
  Widget _buildSocialLoginSection(ResponsiveDesign responsive, ThemeData theme) {
    return Column(
      children: [
        AsoudButton(
          text: 'ورود با Google',
          onPressed: _signInWithGoogle,
          variant: ButtonVariant.outlined,
          icon: Icons.login_rounded,
          size: ButtonSize.large,
        ),
        SizedBox(height: responsive.scale(12)),
        AsoudButton(
          text: 'ورود با Apple',
          onPressed: () {
            // TODO: Implement Apple Sign-In
            _showErrorSnackBar('ورود با Apple به زودی...');
          },
          variant: ButtonVariant.outlined,
          icon: Icons.apple_rounded,
          size: ButtonSize.large,
        ),
      ],
    );
  }

  /// Build divider
  Widget _buildDivider(ResponsiveDesign responsive, ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: theme.colorScheme.outlineVariant,
            thickness: 1,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: responsive.scale(16)),
          child: Text(
            'یا',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: theme.colorScheme.outlineVariant,
            thickness: 1,
          ),
        ),
      ],
    );
  }

  /// Build phone number form
  Widget _buildPhoneNumberForm(ResponsiveDesign responsive, ThemeData theme, AuthState state) {
    if (!_showPhoneField) {
      return const SizedBox.shrink();
    }

    return SlideTransition(
      position: _formSlideAnimation,
      child: FadeTransition(
        opacity: _formOpacityAnimation,
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Phone number input
              AsoudTextField(
                controller: _phoneController,
                labelText: 'شماره موبایل',
                hintText: '۰۹۱۲۳۴۵۶۷۸۹',
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_android_rounded,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'شماره موبایل را وارد کنید';
                  }
                  if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
                    return 'شماره موبایل معتبر نیست';
                  }
                  return null;
                },
                onChanged: (value) {
                  _completePhoneNumber = '0$value';
                },
              ),
              
              SizedBox(height: responsive.scale(24)),
              
              // Submit button
              LoadingStateBuilder(
                operationId: 'auth_login',
                builder: (context, loadingState) {
                  final isLoading = loadingState?.isLoading ?? false;
                  
                  return AsoudButton(
                    text: 'ارسال کد تأیید',
                    onPressed: isLoading ? null : _submitPhoneNumber,
                    variant: ButtonVariant.filled,
                    size: ButtonSize.large,
                    isLoading: isLoading,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build terms and conditions section
  Widget _buildTermsSection(ResponsiveDesign responsive, ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: _termsAccepted,
          onChanged: (value) {
            setState(() {
              _termsAccepted = value ?? false;
            });
            HapticFeedback.selectionClick();
          },
          activeColor: theme.colorScheme.primary,
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _termsAccepted = !_termsAccepted;
              });
              HapticFeedback.selectionClick();
            },
            child: Padding(
              padding: EdgeInsets.only(top: responsive.scale(12)),
              child: RichText(
                text: TextSpan(
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  children: [
                    const TextSpan(text: 'با ادامه، '),
                    TextSpan(
                      text: 'قوانین و مقررات',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    const TextSpan(text: ' و '),
                    TextSpan(
                      text: 'حریم خصوصی',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    const TextSpan(text: ' را می‌پذیرم.'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Handle auth state changes
  void _handleAuthStateChanges(BuildContext context, AuthState state) {
    LoadingStateManager().clearState('auth_login');
    
    if (state.status == StateStatus.loading) {
      LoadingStateManager().setLoading(
        'auth_login',
        message: 'در حال ارسال کد تأیید...',
      );
    } else if (state.status == StateStatus.success) {
      LoadingStateManager().setSuccess(
        'auth_login',
        message: 'کد تأیید ارسال شد',
      );
      
      AnalyticsHelper.trackUserAction('otp_sent_success');
      _showSuccessSnackBar('کد تأیید ارسال شد');
      
      // Navigate to OTP screen
      context.go('/otp');
    } else if (state.status == StateStatus.error) {
      LoadingStateManager().setError(
        'auth_login',
        message: state.error ?? 'خطا در ارسال کد',
      );
      
      AnalyticsHelper.trackError('otp_send_error', state.error ?? 'Unknown error');
      _showErrorSnackBar(state.error ?? 'خطا در ارسال کد تأیید');
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _logoAnimationController.dispose();
    _formAnimationController.dispose();
    _backgroundAnimationController.dispose();
    super.dispose();
  }
}