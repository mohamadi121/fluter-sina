import 'package:asood/core/http_client/api_client.dart';
import 'package:asood/core/http_client/api_status.dart';

class WalletApiService {
  final DioClient dioClient;
  
  WalletApiService({required this.dioClient});
  
  Future getBalance() async {
    try {
      final res = await dioClient.getData('wallet/balance/');
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }
  
  Future checkBalance(double amount) async {
    try {
      final res = await dioClient.postData('wallet/balance/check/', {
        'amount': amount,
      });
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }
  
  Future getTransactions() async {
    try {
      final res = await dioClient.getData('wallet/transactions/');
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }
  
  Future payWithWallet(Map<String, dynamic> data) async {
    try {
      final res = await dioClient.postData('wallet/pay/', data);
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }
}

