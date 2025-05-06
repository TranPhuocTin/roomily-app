import '../../models/transaction.dart';

abstract class TransactionState {
  const TransactionState();
}

class TransactionInitial extends TransactionState {
  const TransactionInitial();
}

class TransactionLoading extends TransactionState {
  const TransactionLoading();
}

class TransactionLoaded extends TransactionState {
  final List<Transaction> transactions;
  
  const TransactionLoaded(this.transactions);
}

class TransactionError extends TransactionState {
  final String message;
  
  const TransactionError(this.message);
}
