import 'dart:io';
import 'package:army_ecommerce/repositories/marketplace_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'reward_event.dart';
import 'reward_state.dart';

class RewardBloc extends Bloc<RewardEvent, RewardState> {
  final MarketplaceRepository marketplaceRepository;

  RewardBloc({required this.marketplaceRepository})
    : super(const RewardState()) {
    on<RewardHistoryRequested>(_onHistoryRequested);
    on<RewardLoadMoreHistoryRequested>(_onLoadMoreHistoryRequested);
    on<RewardProofSubmitted>(_onProofSubmitted);
    on<RewardAppealSubmitted>(_onAppealSubmitted);
    on<RewardProofDetailRequested>(_onProofDetailRequested);
  }

  Future<void> _onHistoryRequested(
    RewardHistoryRequested event,
    Emitter<RewardState> emit,
  ) async {
    emit(
      state.copyWith(
        isLoadingHistory: true,
        currentPage: 1,
        clearMessages: true,
        history: [],
      ),
    );
    try {
      final list = await marketplaceRepository.getRewardHistory(
        index: 1,
        count: state.count,
      );
      emit(
        state.copyWith(
          history: list,
          isLoadingHistory: false,
          currentPage: 2,
          hasReachedEndHistory: list.length < state.count,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(isLoadingHistory: false, errorMessage: error.toString()),
      );
    }
  }

  Future<void> _onLoadMoreHistoryRequested(
    RewardLoadMoreHistoryRequested event,
    Emitter<RewardState> emit,
  ) async {
    if (state.isLoadingMoreHistory ||
        state.hasReachedEndHistory ||
        state.isLoadingHistory)
      return;

    emit(state.copyWith(isLoadingMoreHistory: true, clearMessages: true));
    try {
      final list = await marketplaceRepository.getRewardHistory(
        index: state.currentPage,
        count: state.count,
      );
      final merged = [...state.history, ...list];
      emit(
        state.copyWith(
          history: merged,
          isLoadingMoreHistory: false,
          currentPage: state.currentPage + 1,
          hasReachedEndHistory: list.length < state.count,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          isLoadingMoreHistory: false,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onProofSubmitted(
    RewardProofSubmitted event,
    Emitter<RewardState> emit,
  ) async {
    emit(
      state.copyWith(
        isSubmittingProof: true,
        clearMessages: true,
        clearProofResult: true,
      ),
    );
    try {
      final file = File(event.filePath);
      final uploadedUrl = await marketplaceRepository.uploadFile(file);
      if (uploadedUrl == null || uploadedUrl.isEmpty) {
        throw Exception('Không thể tải tệp tin lên máy chủ');
      }
      final result = await marketplaceRepository.addRewardProof(
        description: event.description,
        imageUrl: event.isImage ? uploadedUrl : null,
        videoUrl: !event.isImage ? uploadedUrl : null,
      );
      emit(
        state.copyWith(
          isSubmittingProof: false,
          proofResult: result ?? const {},
          successMessage: 'Gửi minh chứng chiến tích thành công',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          isSubmittingProof: false,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onAppealSubmitted(
    RewardAppealSubmitted event,
    Emitter<RewardState> emit,
  ) async {
    emit(
      state.copyWith(
        isSubmittingAppeal: true,
        clearMessages: true,
        clearAppealResult: true,
      ),
    );
    try {
      final appeal = await marketplaceRepository.createRewardAppeal(
        rewardId: event.rewardId,
        reason: event.reason,
      );
      emit(
        state.copyWith(
          isSubmittingAppeal: false,
          appealResult: appeal,
          successMessage: 'Gửi khiếu nại thành công',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          isSubmittingAppeal: false,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onProofDetailRequested(
    RewardProofDetailRequested event,
    Emitter<RewardState> emit,
  ) async {
    emit(
      state.copyWith(
        isLoadingDetail: true,
        clearMessages: true,
        clearProofDetail: true,
      ),
    );
    try {
      final proof = await marketplaceRepository.getRewardProof(event.rewardId);
      emit(state.copyWith(isLoadingDetail: false, proofDetail: proof));
    } catch (error) {
      emit(
        state.copyWith(isLoadingDetail: false, errorMessage: error.toString()),
      );
    }
  }
}
