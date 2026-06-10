import 'package:equatable/equatable.dart';

abstract class ConversationEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class ConversationsRequested extends ConversationEvent {}

class ConversationsRefreshed extends ConversationEvent {}

class ConversationsLoadMoreRequested extends ConversationEvent {}
