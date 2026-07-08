import 'package:asood/core/http_client/api_client.dart';
import 'package:asood/core/http_client/api_status.dart';

class CartApiService {
  final DioClient dioClient;
  
  CartApiService({required this.dioClient});
  
  Future getCart() async {
    try {
      final res = await dioClient.getData('user/order/orders');
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }
  
  Future addItem(Map<String, dynamic> data) async {
    try {
      final res = await dioClient.postData('user/order/add_item', data);
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }
  
  Future updateItem(String itemId, Map<String, dynamic> data) async {
    try {
      final res = await dioClient.putData('user/order/update_item/$itemId', data);
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }
  
  Future removeItem(String itemId) async {
    try {
      final res = await dioClient.deleteData('user/order/remove_item/$itemId');
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }
  
  Future checkout(Map<String, dynamic> data) async {
    try {
      final res = await dioClient.postData('user/order/checkout', data);
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }
  
  Future createOrder(Map<String, dynamic> data) async {
    try {
      final res = await dioClient.postData('user/order/create', data);
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }
  
  Future getOrders() async {
    try {
      final res = await dioClient.getData('user/order/list');
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }
  
  Future getOrderDetail(String orderId) async {
    try {
      final res = await dioClient.getData('user/order/$orderId');
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }
  
  Future updateOrder(String orderId, Map<String, dynamic> data) async {
    try {
      final res = await dioClient.putData('user/order/$orderId/update', data);
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }
  
  Future deleteOrder(String orderId) async {
    try {
      final res = await dioClient.deleteData('user/order/$orderId/delete');
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }
}

