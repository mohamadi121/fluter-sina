// Cart Service - Wrapper around CartApiClient with shopping cart business logic
import 'package:asoud/api/asoud_api_service.dart';
import 'package:asoud/core/models/dto/cart_dto.dart';
import 'package:asoud/core/network/app_error.dart';

/// Cart service providing high-level shopping cart operations
/// 
/// This service:
/// - Manages cart state and operations
/// - Handles item additions, updates, and removals
/// - Provides checkout functionality
/// - Manages order lifecycle
class CartService {
  final AsoudApiService apiService;
  
  CartService(this.apiService);

  // ===============================
  // CART OPERATIONS
  // ===============================

  /// Get current cart contents
  Future<OrderResponseDto> getCart() async {
    try {
      return await apiService.cart.getCart();
    } catch (e) {
      throw AppError.fromException(e);
    }
  }

  /// Add item to cart
  Future<CartItemResponseDto> addItemToCart({
    String? productId,
    String? productName,
    String? affiliateId,
    String? affiliateName,
    required int quantity,
  }) async {
    try {
      final item = CartItemDto(
        product: productId,
        productName: productName,
        affiliate: affiliateId,
        affiliateName: affiliateName,
        quantity: quantity,
      );
      return await apiService.cart.addItem(item);
    } catch (e) {
      throw AppError.fromException(e);
    }
  }

  /// Update item quantity in cart
  Future<CartItemResponseDto> updateCartItemQuantity(
    String itemId,
    int newQuantity,
  ) async {
    try {
      final updateRequest = CartUpdateItemDto(quantity: newQuantity);
      return await apiService.cart.updateItem(itemId, updateRequest);
    } catch (e) {
      throw AppError.fromException(e);
    }
  }

  /// Remove item from cart
  Future<void> removeItemFromCart(String itemId) async {
    try {
      await apiService.cart.removeItem(itemId);
    } catch (e) {
      throw AppError.fromException(e);
    }
  }

  /// Clear entire cart
  Future<void> clearCart() async {
    try {
      final cart = await getCart();
      for (final item in cart.data?.items ?? []) {
        // Note: We need item IDs from the cart response to remove items
        // This might require additional cart structure information
      }
    } catch (e) {
      throw AppError.fromException(e);
    }
  }

  /// Checkout cart (convert to order)
  Future<OrderResponseDto> checkout() async {
    try {
      return await apiService.cart.checkout();
    } catch (e) {
      throw AppError.fromException(e);
    }
  }

  // ===============================
  // ORDER OPERATIONS
  // ===============================

  /// Create a new order directly
  Future<OrderResponseDto> createOrder({
    required String description,
    required String type, // "cash" or "online"
    required List<({String productId, int quantity})> items,
  }) async {
    try {
      final orderItems = items
          .map((item) => OrderCreateItemDto(
                productId: item.productId,
                quantity: item.quantity,
              ))
          .toList();

      final order = OrderCreateDto(
        description: description,
        type: type,
        items: orderItems,
      );

      return await apiService.cart.createOrder(order);
    } catch (e) {
      throw AppError.fromException(e);
    }
  }

  /// Get user's orders
  Future<OrderListResponseDto> getOrders() async {
    try {
      return await apiService.cart.getOrders();
    } catch (e) {
      throw AppError.fromException(e);
    }
  }

  /// Get specific order details
  Future<OrderResponseDto> getOrder(String orderId) async {
    try {
      return await apiService.cart.getOrder(orderId);
    } catch (e) {
      throw AppError.fromException(e);
    }
  }

  /// Update an order
  Future<OrderResponseDto> updateOrder(
    String orderId, {
    String? description,
    String? type,
    List<({String productId, int quantity})>? items,
  }) async {
    try {
      // Get current order to preserve unchanged fields
      final currentOrder = await getOrder(orderId);
      
      final orderItems = items
          ?.map((item) => OrderCreateItemDto(
                productId: item.productId,
                quantity: item.quantity,
              ))
          .toList() ?? [];

      final updatedOrder = OrderCreateDto(
        description: description ?? currentOrder.data?.description ?? '',
        type: type ?? currentOrder.data?.type ?? 'online',
        items: orderItems,
      );

      return await apiService.cart.updateOrder(orderId, updatedOrder);
    } catch (e) {
      throw AppError.fromException(e);
    }
  }

  /// Delete an order
  Future<void> deleteOrder(String orderId) async {
    try {
      await apiService.cart.deleteOrder(orderId);
    } catch (e) {
      throw AppError.fromException(e);
    }
  }

  // ===============================
  // OWNER OPERATIONS
  // ===============================

  /// Verify/reject an order (owner)
  Future<void> verifyOrder(
    String orderId,
    bool verified,
    String description,
  ) async {
    try {
      final verification = OrderVerifyDto(
        id: orderId,
        verified: verified,
        description: description,
      );
      await apiService.cart.verifyOrder(verification);
    } catch (e) {
      throw AppError.fromException(e);
    }
  }

  /// Get orders for owner
  Future<OrderListResponseDto> getOwnerOrders() async {
    try {
      return await apiService.cart.getOwnerOrders();
    } catch (e) {
      throw AppError.fromException(e);
    }
  }

  /// Get specific order for owner
  Future<OrderResponseDto> getOwnerOrder(String orderId) async {
    try {
      return await apiService.cart.getOwnerOrder(orderId);
    } catch (e) {
      throw AppError.fromException(e);
    }
  }

  // ===============================
  // UTILITY METHODS
  // ===============================

  /// Calculate cart total (if not provided by API)
  Future<int> calculateCartTotal() async {
    try {
      final cart = await getCart();
      return cart.data?.total ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Get cart item count
  Future<int> getCartItemCount() async {
    try {
      final cart = await getCart();
      return cart.data?.items.length ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Check if cart has items
  Future<bool> hasItemsInCart() async {
    try {
      final count = await getCartItemCount();
      return count > 0;
    } catch (e) {
      return false;
    }
  }

  /// Get order type options
  List<String> getOrderTypeOptions() {
    return ['cash', 'online'];
  }

  /// Get order status options
  List<String> getOrderStatusOptions() {
    return ['pending', 'verified', 'rejected'];
  }

  /// Check if order can be modified
  bool canModifyOrder(String? status) {
    return status == null || status == 'pending';
  }

  /// Check if order is paid
  bool isOrderPaid(OrderDto order) {
    return order.isPaid;
  }

  /// Get order total with formatting
  String getFormattedOrderTotal(OrderDto order) {
    return '${order.total.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )} تومان';
  }
}
