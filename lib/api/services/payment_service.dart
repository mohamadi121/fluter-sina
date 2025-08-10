// Payment Service - Wrapper around PaymentApiClient with payment business logic
import 'package:asoud/api/asoud_api_service.dart';
import 'package:asoud/core/models/dto/payment_dto.dart';
import 'package:asoud/core/network/app_error.dart';

/// Payment service providing high-level payment operations
/// 
/// This service:
/// - Manages payment creation and verification
/// - Handles different payment targets (order, advertisement, wallet, market)
/// - Provides payment history and status tracking
/// - Integrates with Zarinpal gateway
class PaymentService {
  final AsoudApiService apiService;
  
  PaymentService(this.apiService);

  // ===============================
  // PAYMENT OPERATIONS
  // ===============================

  /// Create payment for an order
  Future<PaymentCreateResponseWrapperDto> createOrderPayment(
    String orderId,
    int amount,
  ) async {
    try {
      final payment = PaymentCreateDto(
        target: 'order',
        targetId: orderId,
        amount: amount,
      );
      return await apiService.payment.createPayment(payment);
    } catch (e) {
      throw AppError.fromException(e);
    }
  }

  /// Create payment for an advertisement
  Future<PaymentCreateResponseWrapperDto> createAdvertisementPayment(
    String advertisementId,
    int amount,
  ) async {
    try {
      final payment = PaymentCreateDto(
        target: 'advertisement',
        targetId: advertisementId,
        amount: amount,
      );
      return await apiService.payment.createPayment(payment);
    } catch (e) {
      throw AppError.fromException(e);
    }
  }

  /// Create payment for wallet top-up
  Future<PaymentCreateResponseWrapperDto> createWalletPayment(
    String walletId,
    int amount,
  ) async {
    try {
      final payment = PaymentCreateDto(
        target: 'wallet',
        targetId: walletId,
        amount: amount,
      );
      return await apiService.payment.createPayment(payment);
    } catch (e) {
      throw AppError.fromException(e);
    }
  }

  /// Create payment for market subscription
  Future<PaymentCreateResponseWrapperDto> createMarketPayment(
    String marketId,
    int amount,
  ) async {
    try {
      final payment = PaymentCreateDto(
        target: 'market',
        targetId: marketId,
        amount: amount,
      );
      return await apiService.payment.createPayment(payment);
    } catch (e) {
      throw AppError.fromException(e);
    }
  }

  /// Get payment details
  Future<PaymentResponseDto> getPayment(String paymentId) async {
    try {
      return await apiService.payment.getPayment(paymentId);
    } catch (e) {
      throw AppError.fromException(e);
    }
  }

  /// Get user's payment history
  Future<PaymentListResponseDto> getPaymentHistory() async {
    try {
      return await apiService.payment.getPayments();
    } catch (e) {
      throw AppError.fromException(e);
    }
  }

  /// Verify payment after gateway callback
  Future<PaymentResponseDto> verifyPayment({
    String? authority,
    String? status,
  }) async {
    try {
      return await apiService.payment.verifyPayment(
        authority: authority,
        status: status,
      );
    } catch (e) {
      throw AppError.fromException(e);
    }
  }

  /// Get advertisement payment details
  Future<PaymentResponseDto> getAdvertisementPayment(String adId) async {
    try {
      return await apiService.payment.getAdvertisementPayment(adId);
    } catch (e) {
      throw AppError.fromException(e);
    }
  }

  // ===============================
  // PAYMENT GATEWAY OPERATIONS
  // ===============================

  /// Redirect to payment gateway
  Future<void> redirectToPayment(String paymentId) async {
    try {
      await apiService.payment.redirectToPayment(paymentId);
    } catch (e) {
      throw AppError.fromException(e);
    }
  }

  /// Generate payment URL for external navigation
  String generatePaymentUrl(String paymentId) {
    // This would typically be handled by the backend
    // but we can construct the URL if needed
    return 'https://sandbox.zarinpal.com/pg/StartPay/$paymentId';
  }

  // ===============================
  // PAYMENT STATUS TRACKING
  // ===============================

  /// Check if payment is completed
  bool isPaymentCompleted(PaymentDto payment) {
    // This would need to be determined based on payment status
    // which might be part of the payment data structure
    return payment.targetContent == 'completed';
  }

  /// Check if payment is pending
  bool isPaymentPending(PaymentDto payment) {
    return payment.targetContent == 'pending';
  }

  /// Check if payment failed
  bool isPaymentFailed(PaymentDto payment) {
    return payment.targetContent == 'failed';
  }

  /// Get payment status display text
  String getPaymentStatusText(PaymentDto payment) {
    switch (payment.targetContent) {
      case 'completed':
        return 'پرداخت موفق';
      case 'pending':
        return 'در انتظار پرداخت';
      case 'failed':
        return 'پرداخت ناموفق';
      default:
        return 'نامشخص';
    }
  }

  // ===============================
  // UTILITY METHODS
  // ===============================

  /// Format amount for display
  String formatAmount(int amount) {
    return '${amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )} تومان';
  }

  /// Get payment target display name
  String getPaymentTargetDisplayName(String target) {
    switch (target) {
      case 'order':
        return 'سفارش';
      case 'advertisement':
        return 'آگهی';
      case 'wallet':
        return 'کیف پول';
      case 'market':
        return 'فروشگاه';
      default:
        return target;
    }
  }

  /// Get payment target options
  List<String> getPaymentTargetOptions() {
    return ['order', 'advertisement', 'wallet', 'market'];
  }

  /// Validate payment amount
  bool isValidPaymentAmount(int amount) {
    return amount > 0 && amount <= 50000000; // Max 50M Toman
  }

  /// Get minimum payment amount
  int getMinimumPaymentAmount() {
    return 1000; // 1000 Toman minimum
  }

  /// Get maximum payment amount
  int getMaximumPaymentAmount() {
    return 50000000; // 50M Toman maximum
  }

  /// Convert Rial to Toman
  int rialToToman(int rial) {
    return (rial / 10).round();
  }

  /// Convert Toman to Rial
  int tomanToRial(int toman) {
    return toman * 10;
  }

  /// Check if payment requires verification
  bool requiresVerification(PaymentDto payment) {
    return payment.gateway.name == 'zarinpal';
  }

  /// Get payment gateway display name
  String getGatewayDisplayName(String gatewayName) {
    switch (gatewayName.toLowerCase()) {
      case 'zarinpal':
        return 'زرین‌پال';
      case 'mellat':
        return 'ملت';
      case 'parsian':
        return 'پارسیان';
      default:
        return gatewayName;
    }
  }
}
