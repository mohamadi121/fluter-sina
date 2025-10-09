import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';

import '../../../core/theme/app_theme.dart';
import '../../../core/responsive/responsive_design.dart';
import '../../../core/components/base_components.dart';
import '../../../core/performance/loading_states.dart';
import '../../../core/performance/animation_optimizer.dart';
import '../../../core/firebase/firebase_manager.dart';
import '../blocs/auth_bloc.dart';

/// Enhanced Material Design 3 OTP Verification Screen
class EnhancedOtpScreen extends StatefulWidget {
  const EnhancedOtpScreen({super.key});

  @override
  State<EnhancedOtpScreen> createState() => _EnhancedOtpScreenState();
}

class _EnhancedOtpScreenState extends State<EnhancedOtpScreen>
    with TickerProviderStateMixin {
  
  // OTP input controllers
  final List<TextEditingController> _otpControllers = List.generate(
    6, 
    (index) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(
    6, 
    (index) => FocusNode(),
  );
  
  // Animation controllers
  late AnimationController _slideAnimationController;
  late AnimationController _pulseAnimationController;
  late AnimationController _progressAnimationController;
  
  // Animations
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _progressAnimation;
  
  // State variables
  String _otpCode = '';
  String _phoneNumber = '';
  Timer? _resendTimer;
  int _resendCountdown = 120; // 2 minutes
  bool _canResend = false;
  bool _autoVerifying = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _getPhoneNumber();
    _startResendTimer();
    _trackScreenView();
  }

  /// Initialize animation controllers and animations
  void _initializeAnimations() {
    // Slide animation for form entry
    _slideAnimationController = AnimationOptimizer().createOptimizedController(
      this,
      duration: const Duration(milliseconds: 600),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideAnimationController,
      curve: Curves.easeOutCubic,
    ));
    
    // Pulse animation for active input
    _pulseAnimationController = AnimationOptimizer().createOptimizedController(
      this,
      duration: const Duration(milliseconds: 1000),
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseAnimationController,
      curve: Curves.easeInOut,
    ));
    
    // Progress animation
    _progressAnimationController = AnimationOptimizer().createOptimizedController(
      this,
      duration: const Duration(milliseconds: 300),
    );
    
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressAnimationController,
      curve: Curves.easeOut,
    ));
    
    // Start animations
    _slideAnimationController.forward();
    _pulseAnimationController.repeat(reverse: true);
  }

  /// Get phone number from previous screen
  void _getPhoneNumber() {
    final authBloc = context.read<AuthBloc>();
    _phoneNumber = authBloc.state.phoneNumber;
  }

  /// Start resend countdown timer
  void _startResendTimer() {
    _resendTimer?.cancel();
    _resendCountdown = 120;
    _canResend = false;
    
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _resendCountdown--;
          if (_resendCountdown <= 0) {
            _canResend = true;
            timer.cancel();
          }
        });
      } else {
        timer.cancel();
      }
    });
  }

  /// Track screen view for analytics
  void _trackScreenView() {
    AnalyticsHelper.trackScreenView('enhanced_otp_screen');
  }

  /// Handle OTP input change
  void _onOtpChanged(String value, int index) {
    if (value.length == 1) {
      _otpControllers[index].text = value;
      
      // Move to next field
      if (index < 5) {
        _otpFocusNodes[index + 1].requestFocus();
      } else {
        // Last digit entered, hide keyboard and verify
        _otpFocusNodes[index].unfocus();
        _buildOtpCode();
        _autoVerifyOtp();
      }
    } else if (value.isEmpty && index > 0) {
      // Move to previous field
      _otpFocusNodes[index - 1].requestFocus();
    }
    
    _buildOtpCode();
    _updateProgress();
  }

  /// Handle backspace key
  void _onOtpKeyEvent(KeyEvent event, int index) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_otpControllers[index].text.isEmpty && index > 0) {
        _otpFocusNodes[index - 1].requestFocus();
        _otpControllers[index - 1].clear();
      }
    }
  }

  /// Build complete OTP code
  void _buildOtpCode() {
    _otpCode = _otpControllers.map((controller) => controller.text).join();
  }

  /// Update progress animation based on filled digits
  void _updateProgress() {
    final filledDigits = _otpControllers.where((c) => c.text.isNotEmpty).length;
    final progress = filledDigits / 6.0;
    
    _progressAnimationController.animateTo(progress);
  }

  /// Auto verify OTP when all digits are entered
  void _autoVerifyOtp() {
    if (_otpCode.length == 6 && !_autoVerifying) {
      _autoVerifying = true;
      
      // Add small delay for better UX
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _verifyOtp();
        }
      });
    }
  }

  /// Verify OTP code
  void _verifyOtp() {
    if (_otpCode.length != 6) {
      _showErrorSnackBar('لطفاً کد ۶ رقمی را کامل وارد کنید');
      return;
    }

    // Haptic feedback
    HapticFeedback.lightImpact();
    
    // Track verification attempt
    AnalyticsHelper.trackUserAction('otp_verify_attempt', parameters: {
      'phone_number': _phoneNumber,
      'code_length': _otpCode.length,
    });
    
    // Send verification request
    context.read<AuthBloc>().add(
      VerifyOtp(phone: _phoneNumber, otp: _otpCode),
    );
  }

  /// Resend OTP code
  void _resendOtp() {
    if (!_canResend) return;

    // Haptic feedback
    HapticFeedback.selectionClick();
    
    // Track resend attempt
    AnalyticsHelper.trackUserAction('otp_resend_attempt', parameters: {
      'phone_number': _phoneNumber,
    });
    
    // Clear current OTP
    _clearOtp();
    
    // Send new OTP
    context.read<AuthBloc>().add(SendOtp(phone: _phoneNumber));
    
    // Restart timer
    _startResendTimer();
  }

  /// Clear OTP input fields
  void _clearOtp() {
    for (final controller in _otpControllers) {
      controller.clear();
    }
    _otpCode = '';
    _autoVerifying = false;
    _otpFocusNodes[0].requestFocus();
    _updateProgress();
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
        action: SnackBarAction(
          label: 'تلاش مجدد',
          textColor: Theme.of(context).colorScheme.onError,
          onPressed: _clearOtp,
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

  /// Format countdown time
  String _formatCountdown(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  /// Navigate back to login
  void _navigateBack() {
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveDesign(context);
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: _handleAuthStateChanges,
          builder: (context, state) {
            return CustomScrollView(
              slivers: [
                // App Bar
                SliverAppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    onPressed: _navigateBack,
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  title: Text(
                    'تأیید شماره موبایل',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  centerTitle: true,
                ),
                
                // Main Content
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: responsive.scale(24),
                      ),
                      child: Column(
                        children: [
                          SizedBox(height: responsive.scale(32)),
                          
                          // Progress Indicator
                          _buildProgressIndicator(responsive, theme),
                          
                          SizedBox(height: responsive.scale(40)),
                          
                          // Verification Icon
                          _buildVerificationIcon(responsive, theme),
                          
                          SizedBox(height: responsive.scale(32)),
                          
                          // Description Text
                          _buildDescriptionText(responsive, theme),
                          
                          SizedBox(height: responsive.scale(40)),
                          
                          // OTP Input Fields
                          _buildOtpInputFields(responsive, theme, state),
                          
                          SizedBox(height: responsive.scale(32)),
                          
                          // Verify Button
                          _buildVerifyButton(responsive, theme, state),
                          
                          SizedBox(height: responsive.scale(24)),
                          
                          // Resend Section
                          _buildResendSection(responsive, theme),
                          
                          const Spacer(),
                          
                          // Change Number Option
                          _buildChangeNumberOption(responsive, theme),
                          
                          SizedBox(height: responsive.scale(24)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Build progress indicator
  Widget _buildProgressIndicator(ResponsiveDesign responsive, ThemeData theme) {
    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        return Column(
          children: [
            LinearProgressIndicator(
              value: _progressAnimation.value,
              backgroundColor: theme.colorScheme.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
              minHeight: responsive.scale(4),
            ),
            SizedBox(height: responsive.scale(8)),
            Text(
              '${(_progressAnimation.value * 100).toInt()}% تکمیل شده',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        );
      },
    );
  }

  /// Build verification icon
  Widget _buildVerificationIcon(ResponsiveDesign responsive, ThemeData theme) {
    return Container(
      width: responsive.scale(100),
      height: responsive.scale(100),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.colorScheme.primaryContainer,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.2),
            blurRadius: responsive.scale(16),
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        Icons.sms_rounded,
        size: responsive.scale(48),
        color: theme.colorScheme.onPrimaryContainer,
      ),
    );
  }

  /// Build description text
  Widget _buildDescriptionText(ResponsiveDesign responsive, ThemeData theme) {
    return Column(
      children: [
        Text(
          'کد تأیید ارسال شد',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: responsive.scale(8)),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            children: [
              const TextSpan(text: 'کد ۶ رقمی به شماره '),
              TextSpan(
                text: _phoneNumber,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
              const TextSpan(text: ' ارسال شد'),
            ],
          ),
        ),
      ],
    );
  }

  /// Build OTP input fields
  Widget _buildOtpInputFields(ResponsiveDesign responsive, ThemeData theme, AuthState state) {
    final fieldWidth = responsive.scale(48);
    final fieldHeight = responsive.scale(56);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(6, (index) {
        return AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            final isActive = _otpFocusNodes[index].hasFocus;
            final scale = isActive ? _pulseAnimation.value : 1.0;
            
            return Transform.scale(
              scale: scale,
              child: Container(
                width: fieldWidth,
                height: fieldHeight,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border.all(
                    color: isActive 
                        ? theme.colorScheme.primary
                        : _otpControllers[index].text.isNotEmpty
                            ? theme.colorScheme.primary.withOpacity(0.5)
                            : theme.colorScheme.outline,
                    width: isActive ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(responsive.scale(12)),
                  boxShadow: isActive ? [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.2),
                      blurRadius: responsive.scale(8),
                      offset: const Offset(0, 2),
                    ),
                  ] : null,
                ),
                child: TextField(
                  controller: _otpControllers[index],
                  focusNode: _otpFocusNodes[index],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 1,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    counterText: '',
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  onChanged: (value) => _onOtpChanged(value, index),
                  onTap: () {
                    HapticFeedback.selectionClick();
                  },
                ),
              ),
            );
          },
        );
      }),
    );
  }

  /// Build verify button
  Widget _buildVerifyButton(ResponsiveDesign responsive, ThemeData theme, AuthState state) {
    return LoadingStateBuilder(
      operationId: 'otp_verification',
      builder: (context, loadingState) {
        final isLoading = loadingState?.isLoading ?? false;
        final canVerify = _otpCode.length == 6;
        
        return AsoudButton(
          text: 'تأیید کد',
          onPressed: (canVerify && !isLoading) ? _verifyOtp : null,
          variant: ButtonVariant.filled,
          size: ButtonSize.large,
          isLoading: isLoading,
          icon: Icons.check_circle_rounded,
        );
      },
    );
  }

  /// Build resend section
  Widget _buildResendSection(ResponsiveDesign responsive, ThemeData theme) {
    return Column(
      children: [
        if (!_canResend) ...[
          Text(
            'ارسال مجدد در ${_formatCountdown(_resendCountdown)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: responsive.scale(8)),
          LinearProgressIndicator(
            value: (_resendCountdown / 120),
            backgroundColor: theme.colorScheme.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.colorScheme.primary.withOpacity(0.5),
            ),
            minHeight: responsive.scale(2),
          ),
        ] else ...[
          AsoudButton(
            text: 'ارسال مجدد کد',
            onPressed: _resendOtp,
            variant: ButtonVariant.text,
            icon: Icons.refresh_rounded,
          ),
        ],
      ],
    );
  }

  /// Build change number option
  Widget _buildChangeNumberOption(ResponsiveDesign responsive, ThemeData theme) {
    return TextButton.icon(
      onPressed: _navigateBack,
      icon: Icon(
        Icons.edit_rounded,
        size: responsive.scale(18),
      ),
      label: const Text('تغییر شماره موبایل'),
      style: TextButton.styleFrom(
        foregroundColor: theme.colorScheme.primary,
      ),
    );
  }

  /// Handle auth state changes
  void _handleAuthStateChanges(BuildContext context, AuthState state) {
    LoadingStateManager().clearState('otp_verification');
    
    if (state.status == StateStatus.loading) {
      LoadingStateManager().setLoading(
        'otp_verification',
        message: 'در حال تأیید کد...',
      );
    } else if (state.status == StateStatus.success) {
      LoadingStateManager().setSuccess(
        'otp_verification',
        message: 'کد تأیید شد',
      );
      
      AnalyticsHelper.trackUserAction('otp_verify_success');
      _showSuccessSnackBar('ورود موفق بود');
      
      // Navigate to dashboard
      context.go('/dashboard');
    } else if (state.status == StateStatus.error) {
      LoadingStateManager().setError(
        'otp_verification',
        message: state.error ?? 'خطا در تأیید کد',
      );
      
      AnalyticsHelper.trackError('otp_verify_error', state.error ?? 'Unknown error');
      _showErrorSnackBar(state.error ?? 'کد تأیید اشتباه است');
      
      // Clear OTP and let user try again
      _clearOtp();
    }
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    
    for (final controller in _otpControllers) {
      controller.dispose();
    }
    
    for (final focusNode in _otpFocusNodes) {
      focusNode.dispose();
    }
    
    _slideAnimationController.dispose();
    _pulseAnimationController.dispose();
    _progressAnimationController.dispose();
    
    super.dispose();
  }
}