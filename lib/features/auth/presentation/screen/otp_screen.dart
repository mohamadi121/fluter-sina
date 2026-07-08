import 'dart:async';

import 'package:asood/core/constants/constants.dart';
import 'package:asood/core/router/app_routers.dart';
import 'package:asood/features/auth/presentation/blocs/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  // Backend pins expire after 2 minutes (PinVerifyAPIView).
  static const int _resendSeconds = 120;

  String _enteredCode = '';
  int _secondsLeft = _resendSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _secondsLeft = _resendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 1) {
        timer.cancel();
      }
      setState(() => _secondsLeft = _secondsLeft > 0 ? _secondsLeft - 1 : 0);
    });
  }

  void _verify(BuildContext context, String phoneNumber) {
    if (_enteredCode.length < 4) {
      _showToast('کد تایید را کامل وارد کنید');
      return;
    }
    context.read<AuthBloc>().add(
      VerifyOtp(phone: phoneNumber, otp: _enteredCode),
    );
  }

  void _resend(BuildContext context, String phoneNumber) {
    context.read<AuthBloc>().add(SendOtp(phone: phoneNumber));
    _startCountdown();
  }

  @override
  Widget build(BuildContext context) {
    final phoneNumber = context.select(
      (AuthBloc bloc) => bloc.state.phoneNumber,
    );

    return Container(
      color: Colora.primaryColor,
      child: SafeArea(
        child: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              child: BlocConsumer<AuthBloc, AuthState>(
                listener: (context, state) {
                  if (state.status == AuthStatus.authenticated) {
                    context.go(AppRoutes.vendorHome);
                  } else if (state.status == AuthStatus.error) {
                    _showToast(
                      state.error == 'Pin not valid'
                          ? 'کد تایید اشتباه است'
                          : state.error,
                    );
                  }
                },
                builder: (context, state) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Spacer(),
                      _buildLogoSection(),
                      const SizedBox(height: 20),
                      _buildOtpField(context, phoneNumber),
                      const SizedBox(height: 20),
                      _buildSubmitButton(state, context, phoneNumber),
                      const SizedBox(height: 12),
                      _buildResendSection(context, phoneNumber),
                      const Spacer(),
                      _buildFooter(),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    return Column(
      children: [
        SizedBox(
          height: Dimensions.height * 0.2,
          width: Dimensions.width,
          child: Center(
            child: AspectRatio(
              aspectRatio: 1,
              child: Assets.images.asood.image(
                fit: BoxFit.scaleDown,
                color: Colors.blue.shade900,
              ),
            ),
          ),
        ),
        Container(width: 150.0, height: 2, color: Colors.blue.shade900),
        const SizedBox(height: 20),
        Image.asset(
          'assets/images/logo.png',
          width: 100,
          height: 100,
          color: Colors.blue.shade900,
        ),
        const SizedBox(height: 20),
        Text(
          'آسودگی خیال , با آسود',
          style: TextStyle(
            fontSize: 22.0,
            color: Colors.blue.shade900,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'کد تایید',
          style: TextStyle(fontSize: 15.0, color: Colora.lightBlue),
        ),
      ],
    );
  }

  Widget _buildOtpField(BuildContext context, String phoneNumber) {
    return Container(
      width: Dimensions.width,
      padding: const EdgeInsets.only(bottom: 10),
      margin: EdgeInsets.symmetric(horizontal: Dimensions.width * 0.2),
      decoration: BoxDecoration(
        color: Colora.primaryColor,
        borderRadius: BorderRadius.circular(28),
      ),
      height: Dimensions.height * 0.06,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: OtpTextField(
          enabledBorderColor: Colora.scaffold,
          borderColor: const Color(0xFF512DA8),
          cursorColor: Colora.scaffold,
          textStyle: const TextStyle(color: Colora.scaffold),
          showFieldAsBox: false,
          onSubmit: (String verificationCode) {
            _enteredCode = verificationCode;
            _verify(context, phoneNumber);
          },
        ),
      ),
    );
  }

  Widget _buildSubmitButton(
    AuthState state,
    BuildContext context,
    String phoneNumber,
  ) {
    return ElevatedButton(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all<Color>(Colora.primaryColor),
      ),
      onPressed:
          state.status == AuthStatus.verifying
              ? null
              : () => _verify(context, phoneNumber),
      child:
          (state.status == AuthStatus.verifying)
              ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white),
              )
              : const Text('ورود', style: TextStyle(color: Colors.white)),
    );
  }

  Widget _buildResendSection(BuildContext context, String phoneNumber) {
    if (_secondsLeft > 0) {
      final minutes = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
      final seconds = (_secondsLeft % 60).toString().padLeft(2, '0');
      return Text(
        'ارسال مجدد کد تا $minutes:$seconds',
        style: const TextStyle(color: Colora.lightBlue, fontSize: 13),
      );
    }
    return TextButton(
      onPressed: () => _resend(context, phoneNumber),
      child: const Text(
        'ارسال مجدد کد',
        style: TextStyle(color: Colora.lightBlue, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildFooter() {
    return CustomPaint(
      painter: CCurvedPainter(),
      child: const SizedBox(
        height: 100,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: Text(
                "copyright",
                style: TextStyle(color: Colora.scaffold, fontSize: 13),
              ),
            ),
            Center(
              child: Text(
                "ASUD   2021",
                style: TextStyle(
                  color: Colora.scaffold,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }
}
