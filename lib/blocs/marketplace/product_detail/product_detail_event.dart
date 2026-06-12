import 'package:equatable/equatable.dart';

abstract class ProductDetailEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class ProductDetailRequested extends ProductDetailEvent {
  final String productId;

  ProductDetailRequested(this.productId);

  @override
  List<Object?> get props => [productId];
}

class ProductLikeToggled extends ProductDetailEvent {}

class ProductCommentSent extends ProductDetailEvent {
  final String content;
  final String? currentUserId;
  final String? currentUserName;
  final String? currentUserAvatar;

  ProductCommentSent(this.content, {this.currentUserId, this.currentUserName, this.currentUserAvatar});

  @override
  List<Object?> get props => [content, currentUserId, currentUserName, currentUserAvatar];
}

class ProductReported extends ProductDetailEvent {
  final String subject;
  final String details;

  ProductReported({required this.subject, required this.details});

  @override
  List<Object?> get props => [subject, details];
}
