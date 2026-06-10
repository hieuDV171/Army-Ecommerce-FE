import 'package:equatable/equatable.dart';

abstract class SimpleListEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class SimpleListRequested extends SimpleListEvent {}

class SimpleListRefreshed extends SimpleListEvent {}

class SimpleListLoadMoreRequested extends SimpleListEvent {}

class SimpleActionRequested extends SimpleListEvent {
  final String path;
  final Map<String, dynamic> data;

  SimpleActionRequested({required this.path, required this.data});

  @override
  List<Object?> get props => [path, data];
}
