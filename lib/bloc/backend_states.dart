import 'package:equatable/equatable.dart';

abstract class State extends Equatable {
  const State();

  @override
  List<Object?> get props => [];
}

class InitialState extends State {
  const InitialState();

  @override
  String toString() => 'InitialState';
}

class LoadingState extends State {
  const LoadingState();

  @override
  String toString() => 'LoadingState';
}

class LoadedState extends State {
  final dynamic data;

  const LoadedState(this.data);

  @override
  List<Object?> get props => [data];

  @override
  String toString() => 'LoadedState { data: $data }';
}

class ErrorState extends State {
  final String message;

  const ErrorState(this.message);

  @override
  List<Object?> get props => [message];

  @override
  String toString() => 'ErrorState { message: $message }';
}



