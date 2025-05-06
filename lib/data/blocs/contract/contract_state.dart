import 'package:equatable/equatable.dart';

/// Base contract state class
abstract class ContractState extends Equatable {
  const ContractState();

  @override
  List<Object?> get props => [];
}

/// Initial state for contract
class ContractInitial extends ContractState {
  const ContractInitial();
}

/// Loading state while fetching contract data
class ContractLoading extends ContractState {
  const ContractLoading();
}

/// State for when contract data is loaded successfully
class ContractLoaded extends ContractState {
  final String htmlContent;

  const ContractLoaded(this.htmlContent);

  @override
  List<Object?> get props => [htmlContent];
}

/// Error state for contract-related errors
class ContractError extends ContractState {
  final String message;

  const ContractError(this.message);

  @override
  List<Object?> get props => [message];
} 