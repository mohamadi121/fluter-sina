import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:asoud/api/auth_api_client.dart';
import 'package:asoud/core/models/dto/base_response_dto.dart';
import 'package:asoud/core/models/dto/auth_dto.dart';

class _StubbedInterceptor extends Interceptor {
  final List<_Stub> _stubs = [];
  FormData? lastForm;
  void addStub({required String method, required String path, required int status, required Map<String,dynamic> body}) {
    _stubs.add(_Stub(method, path, status, body));
  }
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.data is FormData) lastForm = options.data as FormData;
    final stub = _stubs.firstWhere(
      (s) => s.method == options.method && s.path == options.path,
      orElse: () => _Stub.none(),
    );
    if (stub.isValid) {
      handler.resolve(Response<Map<String,dynamic>>(
        requestOptions: options,
        statusCode: stub.status,
        data: stub.body,
      ));
      return;
    }
    super.onRequest(options, handler);
  }
}
class _Stub {
  final String method; final String path; final int status; final Map<String,dynamic> body; final bool isValid;
  _Stub(this.method,this.path,this.status,this.body):isValid=true;
  _Stub.none():method='',path='',status=0,body=const{},isValid=false;
}

void main() {
  group('AuthApiClient Contract', () {
    late Dio dio; late AuthApiClient api; late _StubbedInterceptor stub;

    setUp(() {
      dio = Dio(BaseOptions(baseUrl: 'https://api.asoud.ir/api/v1'));
      stub = _StubbedInterceptor();
      dio.interceptors.add(stub);
      api = AuthApiClient(dio);
    });

    group('createPin', () {
      test('success sends mobile_number field', () async {
        const mobile = '+989123456789';
        stub.addStub(method: 'POST', path: '/user/pin/create/', status: 200, body: {
          'success': true,'code':200,'data':{},'message':'Pin has been created successfully'
        });
        final res = await api.createPin(mobile);
        expect(res.success, true); expect(res.code, 200);
        final fields = Map.fromEntries(stub.lastForm!.fields);
        expect(fields['mobile_number'], mobile);
      });
      test('failure envelope', () async {
        const mobile='invalid_number';
        stub.addStub(method:'POST', path:'/user/pin/create/', status:500, body:{
          'success': false,'code':500,'error':{'code':'value too long for type character varying(15)','detail':'Server error'}
        });
        final res = await api.createPin(mobile);
        expect(res.success,false); expect(res.code,500);
        final fields = Map.fromEntries(stub.lastForm!.fields);
        expect(fields['mobile_number'], mobile);
      });
    });

    group('verifyPin', () {
      test('success parses token', () async {
        const mobile='+989123456789'; const pin='1234';
        stub.addStub(method:'POST', path:'/user/pin/verify/', status:200, body:{
          'success': true,'code':200,'data':{'token':'1b7b1499174ab437c0b9b668551f83d98a42103b'},'message':'Token has been created successfully'
        });
        final res = await api.verifyPin(mobile, pin);
        expect(res.success,true); expect(res.data?.token,'1b7b1499174ab437c0b9b668551f83d98a42103b');
        final fields = Map.fromEntries(stub.lastForm!.fields);
        expect(fields['mobile_number'], mobile); expect(fields['pin'], pin);
      });
      test('invalid pin failure', () async {
        const mobile='+989123456789'; const pin='0000';
        stub.addStub(method:'POST', path:'/user/pin/verify/', status:401, body:{
          'success': false,'code':401,'error':{'code':'pin_not_valid','detail':'Pin not valid'}
        });
        final res = await api.verifyPin(mobile, pin);
        expect(res.success,false); expect(res.code,401);
        final fields = Map.fromEntries(stub.lastForm!.fields);
        expect(fields['mobile_number'], mobile); expect(fields['pin'], pin);
        expect((res.error as Map)['code'],'pin_not_valid');
      });
    });
  });
}
