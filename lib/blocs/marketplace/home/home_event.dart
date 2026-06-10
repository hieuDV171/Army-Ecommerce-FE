import 'package:equatable/equatable.dart';

abstract class HomeEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class HomeRequested extends HomeEvent {}

class HomeRefreshed extends HomeEvent {}

class HomeLoadMoreRequested extends HomeEvent {}
