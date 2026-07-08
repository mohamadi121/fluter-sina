import 'package:flutter/material.dart';

import 'package:asood/core/constants/constants.dart';
import 'package:asood/core/http_client/api_client.dart';
import 'package:asood/core/http_client/api_status.dart';
import 'package:asood/locator.dart';

class TermsAndConditions extends StatefulWidget {
  const TermsAndConditions({super.key});

  @override
  State<TermsAndConditions> createState() => _TermsAndConditionsState();
}

class _TermsAndConditionsState extends State<TermsAndConditions> {
  String? terms;
  String? error;

  Future<void> getTerms() async {
    try {
      final res = await locator<DioClient>().getData('info/term/');
      final result = apiStatus(res);
      if (!mounted) {
        return;
      }
      if (result is Success) {
        setState(() {
          terms = ((result.response as Map?)?['content'] ?? '').toString();
        });
      } else {
        setState(() => error = (result as Failure).message);
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => error = apiFailure(e).message);
    }
  }

  @override
  void initState() {
    super.initState();
    getTerms();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                width: Dimensions.width * 0.8,
                height: Dimensions.height * 0.1,
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => Navigator.of(context).pop(),
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(Icons.arrow_back_ios_new_rounded),
                        ),
                      ),
                    ),
                    const Center(
                      child: Text(
                        'توافق نامه کاربری',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              Center(
                child: SizedBox(
                  width: Dimensions.width * 0.8,
                  child: _buildBody(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (error != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(error!, textAlign: TextAlign.center),
      );
    }
    if (terms == null) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Text(terms!);
  }
}
