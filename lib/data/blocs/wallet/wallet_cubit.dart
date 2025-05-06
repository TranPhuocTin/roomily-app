import 'package:roomily/data/blocs/wallet/wallet_state.dart';
import 'package:roomily/data/repositories/wallet_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roomily/data/models/withdraw_info_create.dart';

class WalletCubit extends Cubit<WalletState> {
  final WalletRepository _walletRepository;

  WalletCubit({required WalletRepository walletRepository})
      : _walletRepository = walletRepository,
        super(const WalletInitial());

  Future<void> getWithdrawInfo() async {
    emit(const WithdrawInfoLoading());
    try {
      final withdrawInfo = await _walletRepository.getWithdrawInfo();
      emit(WithdrawInfoSuccess(withdrawInfo));
    } catch (e) {
      emit(WithdrawInfoFailure(e.toString()));
    }
  }

  Future<void> createWithdrawInfo(WithdrawInfoCreate withdrawInfoCreate) async {
    emit(const WithdrawInfoCreateLoading());
    try {
      final success = await _walletRepository.createWithdrawInfo(withdrawInfoCreate);
      if (success) {
        emit(const WithdrawInfoCreateSuccess());
      } else {
        emit(const WithdrawInfoCreateFailure('Failed to create withdraw info'));
      }
    } catch (e) {
      emit(WithdrawInfoCreateFailure(e.toString()));
    }
  }

  Future<void> withdrawMoney(double amount) async {
    emit(const WithdrawMoneyLoading());
    try {
      final success = await _walletRepository.withdrawMoney(amount);
      if (success) {
        emit(const WithdrawMoneySuccess());
      } else {
        emit(const WithdrawMoneyFailure('Failed to withdraw money'));
      }
    } catch (e) {
      emit(WithdrawMoneyFailure(e.toString()));
    }
  }
}