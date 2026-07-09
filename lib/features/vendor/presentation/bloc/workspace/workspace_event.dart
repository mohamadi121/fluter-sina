part of 'workspace_bloc.dart';

sealed class WorkspaceEvent {
  const WorkspaceEvent();
}

class ChangeTabView extends WorkspaceEvent {
  final int activeTabIndex;
  const ChangeTabView({required this.activeTabIndex});
}

//invoice
class ShowInvoice extends WorkspaceEvent {
  final bool isShow;
  const ShowInvoice({required this.isShow});
}

class InvoiceOption extends WorkspaceEvent {
  final int option;
  const InvoiceOption({required this.option});
}

class InvoiceConfirm extends WorkspaceEvent {
  final bool isConfirm;
  const InvoiceConfirm({required this.isConfirm});
}

class LoadStores extends WorkspaceEvent {}

class SelectMarket extends WorkspaceEvent {
  final int marketId;
  const SelectMarket({required this.marketId});
}
