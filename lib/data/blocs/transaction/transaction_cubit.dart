import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roomily/data/blocs/transaction/transaction_state.dart';
import 'package:roomily/data/models/transaction.dart';
import 'package:roomily/data/repositories/transaction_repository_impl.dart';
import 'package:roomily/core/utils/result.dart';

class TransactionCubit extends Cubit<TransactionState> {
  final TransactionRepository _transactionRepository;

  TransactionCubit({required TransactionRepository transactionRepository})
      : _transactionRepository = transactionRepository,
        super(const TransactionInitial());

  Future<void> getTransactions(String rentedRoomId) async {
    emit(const TransactionLoading());
    
    final result = await _transactionRepository.getTransactionsByRentedRoomId(rentedRoomId);
    
    if (result is Success<List<Transaction>>) {
      emit(TransactionLoaded(result.data));
    } else if (result is Failure) {
      emit(TransactionError('Lỗi không xác định: $result'));
    }
  }

  void reset() {
    emit(const TransactionInitial());
  }
}
