import 'package:equatable/equatable.dart';

abstract class RewardEvent extends Equatable {
  const RewardEvent();

  @override
  List<Object?> get props => [];
}

class RewardHistoryRequested extends RewardEvent {
  final bool isRefresh;

  const RewardHistoryRequested({this.isRefresh = false});

  @override
  List<Object?> get props => [isRefresh];
}

class RewardLoadMoreHistoryRequested extends RewardEvent {
  const RewardLoadMoreHistoryRequested();
}

class RewardProofSubmitted extends RewardEvent {
  final String description;
  final String filePath;
  final bool isImage;

  const RewardProofSubmitted({
    required this.description,
    required this.filePath,
    required this.isImage,
  });

  @override
  List<Object?> get props => [description, filePath, isImage];
}

class RewardAppealSubmitted extends RewardEvent {
  final String rewardId;
  final String? reason;

  const RewardAppealSubmitted({
    required this.rewardId,
    this.reason,
  });

  @override
  List<Object?> get props => [rewardId, reason];
}

class RewardProofDetailRequested extends RewardEvent {
  final String rewardId;

  const RewardProofDetailRequested(this.rewardId);

  @override
  List<Object?> get props => [rewardId];
}
