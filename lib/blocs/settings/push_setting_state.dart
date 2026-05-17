import '../../models/push_setting_model.dart';

abstract class PushSettingState {}

class PushSettingInitial extends PushSettingState {}

class PushSettingLoading extends PushSettingState {}

class PushSettingSuccess extends PushSettingState {
  final String code;
  final String? message;
  final PushSettingModel data;

  PushSettingSuccess({required this.code, this.message, required this.data});
}

class PushSettingError extends PushSettingState {
  final String code;
  final String error;

  PushSettingError({required this.code, required this.error, });
}