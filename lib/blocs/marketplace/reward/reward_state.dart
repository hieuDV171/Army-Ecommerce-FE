import 'package:army_ecommerce/models/checkout_model.dart';
import 'package:equatable/equatable.dart';

class RewardState extends Equatable {
  final List<RewardHistoryModel> history;
  final bool isLoadingHistory;
  final bool isLoadingMoreHistory;
  final bool hasReachedEndHistory;
  final int currentPage;
  final bool isSubmittingProof;
  final Map<String, dynamic>? proofResult;
  final bool isSubmittingAppeal;
  final RewardAppealModel? appealResult;
  final bool isLoadingDetail;
  final Map<String, dynamic>? proofDetail;
  final String? errorMessage;
  final String? successMessage;
  final int count;

  const RewardState({
    this.history = const [],
    this.isLoadingHistory = false,
    this.isLoadingMoreHistory = false,
    this.hasReachedEndHistory = false,
    this.currentPage = 1,
    this.isSubmittingProof = false,
    this.proofResult,
    this.isSubmittingAppeal = false,
    this.appealResult,
    this.isLoadingDetail = false,
    this.proofDetail,
    this.errorMessage,
    this.successMessage,
    this.count = 20,
  });

  RewardState copyWith({
    List<RewardHistoryModel>? history,
    bool? isLoadingHistory,
    bool? isLoadingMoreHistory,
    bool? hasReachedEndHistory,
    int? currentPage,
    bool? isSubmittingProof,
    Map<String, dynamic>? proofResult,
    bool? isSubmittingAppeal,
    RewardAppealModel? appealResult,
    bool? isLoadingDetail,
    Map<String, dynamic>? proofDetail,
    String? errorMessage,
    String? successMessage,
    int? count,
    bool clearMessages = false,
    bool clearProofResult = false,
    bool clearAppealResult = false,
    bool clearProofDetail = false,
  }) {
    return RewardState(
      history: history ?? this.history,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
      isLoadingMoreHistory: isLoadingMoreHistory ?? this.isLoadingMoreHistory,
      hasReachedEndHistory: hasReachedEndHistory ?? this.hasReachedEndHistory,
      currentPage: currentPage ?? this.currentPage,
      isSubmittingProof: isSubmittingProof ?? this.isSubmittingProof,
      proofResult: clearProofResult ? null : proofResult ?? this.proofResult,
      isSubmittingAppeal: isSubmittingAppeal ?? this.isSubmittingAppeal,
      appealResult: clearAppealResult ? null : appealResult ?? this.appealResult,
      isLoadingDetail: isLoadingDetail ?? this.isLoadingDetail,
      proofDetail: clearProofDetail ? null : proofDetail ?? this.proofDetail,
      errorMessage: clearMessages ? null : errorMessage ?? this.errorMessage,
      successMessage: clearMessages ? null : successMessage ?? this.successMessage,
      count: count ?? this.count,
    );
  }

  @override
  List<Object?> get props => [
        history,
        isLoadingHistory,
        isLoadingMoreHistory,
        hasReachedEndHistory,
        currentPage,
        isSubmittingProof,
        proofResult,
        isSubmittingAppeal,
        appealResult,
        isLoadingDetail,
        proofDetail,
        errorMessage,
        successMessage,
        count,
      ];
}
