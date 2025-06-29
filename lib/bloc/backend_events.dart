import 'package:equatable/equatable.dart';

abstract class Event extends Equatable {
  const Event();

  @override
  List<Object?> get props => [];
}

/// Base class for all backend events.

class FetchData extends Event {
  const FetchData();

  @override
  List<Object?> get props => [];

  @override
  String toString() => 'FetchData';
} 
