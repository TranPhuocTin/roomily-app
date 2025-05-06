import 'package:roomily/data/models/withdraw_info.dart';

abstract class WalletState {
  const WalletState();
}

/// The initial state of the wallet
class WalletInitial extends WalletState {
  const WalletInitial();
}

class WithdrawInfoLoading extends WalletState {
  const WithdrawInfoLoading();
}

class WithdrawInfoSuccess extends WalletState {
  final WithdrawInfo withdrawInfo;

  const WithdrawInfoSuccess(this.withdrawInfo);
}

class WithdrawInfoFailure extends WalletState {
  final String errorMessage;

  const WithdrawInfoFailure(this.errorMessage);
}

class WithdrawInfoCreateInit extends WalletState {
  const WithdrawInfoCreateInit();
}

class WithdrawInfoCreateLoading extends WalletState {
  const WithdrawInfoCreateLoading();
}

class WithdrawInfoCreateSuccess extends WalletState {
  const WithdrawInfoCreateSuccess();
}

class WithdrawInfoCreateFailure extends WalletState {
  final String errorMessage;

  const WithdrawInfoCreateFailure(this.errorMessage);
}

class WithdrawMoneyInitial extends WalletState {
  const WithdrawMoneyInitial();
}

class WithdrawMoneyLoading extends WalletState {
  const WithdrawMoneyLoading();
}

class WithdrawMoneySuccess extends WalletState {
  const WithdrawMoneySuccess();
}

class WithdrawMoneyFailure extends WalletState {
  final String errorMessage;

  const WithdrawMoneyFailure(this.errorMessage);
}

