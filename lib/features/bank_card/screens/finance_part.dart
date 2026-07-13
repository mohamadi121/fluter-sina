import 'package:flutter/material.dart';

import 'package:asood/features/bank_card/screens/bank_card_list.dart';

/// Finance currently exposes only the persisted bank-information capability.
/// Transaction dashboards and statements stay absent until backed by real APIs.
class Finance extends StatelessWidget {
  const Finance({super.key});

  @override
  Widget build(BuildContext context) => const BankCardListScreen();
}
