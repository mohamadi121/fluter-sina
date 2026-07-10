import 'package:asood/core/constants/constants.dart';
import 'package:asood/core/http_client/api_client.dart';
import 'package:asood/core/http_client/api_status.dart';
import 'package:asood/features/business_card/presentation/screens/business_list.dart';
import 'package:asood/features/business_card/presentation/screens/without_market_visit.dart';
import 'package:asood/locator.dart';
import 'package:flutter/material.dart';

class BusinessPart extends StatefulWidget {
  const BusinessPart({super.key});

  @override
  State<BusinessPart> createState() => _BusinessPartState();
}

class _BusinessPartState extends State<BusinessPart> {
  List<Map<String, dynamic>> dataList = [];

  final DioClient _dio = locator<DioClient>();

  void getVisitCard() async {
    final res = await _dio.getData('owner/market/list/');
    final result = apiStatus(res);
    if (!mounted || result is! Success || result.response is! List) {
      return;
    }
    dataList.clear();

    for (final market in result.response as List) {
      final businessId = market['business_id']?.toString();
      if (businessId == null) {
        continue;
      }
      try {
        final card = await _dio.dio.get('https://asoud.ir/$businessId');
        if (card.data is Map) {
          setState(() => dataList.add(Map<String, dynamic>.from(card.data)));
        }
      } catch (_) {
        // Visit card page unavailable for this business — skip it.
      }
    }

    if (dataList.isEmpty && mounted) {
      setState(() => dataList.add({'first': 'null'}));
    }
  }

  @override
  void initState() {
    getVisitCard();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          dataList.isEmpty
              ? Center(
                child: SizedBox(
                  height: Dimensions.width * 0.1,
                  width: Dimensions.width * 0.1,
                  child: CircularProgressIndicator(
                    color: Colora.backgroundDialog,
                  ),
                ),
              )
              : dataList[0] == {'first': 'null'}
              // : true
              ? WithoutMarketVisit()
              : BusinessList(data: dataList),
    );
  }
}
