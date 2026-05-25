import 'package:army_ecommerce/blocs/settings/push_setting_event.dart';
import 'package:army_ecommerce/blocs/settings/push_setting_state.dart';
import 'package:army_ecommerce/core/constants/response_code.dart';
import 'package:army_ecommerce/models/push_setting_model.dart';
import 'package:army_ecommerce/repositories/setting_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PushSettingBloc extends Bloc<PushSettingEvent, PushSettingState> {
  final SettingRepository settingRepository;
  PushSettingModel? _cachedSettings;

  PushSettingBloc({required this.settingRepository}) : super(PushSettingInitial()) {
    on<FetchPushSettingEvent>(_onFetchPushSetting);
    on<UpdatePushSettingEvent>(_onUpdatePushSetting);
  }

  Future<void> _onFetchPushSetting(
      FetchPushSettingEvent event,
      Emitter<PushSettingState> emit,
      ) async {
    emit(PushSettingLoading());
    try {
      final response = await settingRepository.getPushSetting();
      final responseCode = ResponseCode.fromCode(response.code);

      if (responseCode == ResponseCode.ok && response.data != null) {
        // Lưu cache khi fetch thành công
        _cachedSettings = response.data;
        emit(PushSettingSuccess(code: response.code, message: response.message, data: response.data!));
      } else {
        emit(PushSettingError(error: response.message, code: response.code));
      }
    } catch (e) {
      emit(PushSettingError(error: e.toString(), code: ResponseCode.exception.code));
    }
  }

  Future<void> _onUpdatePushSetting(
      UpdatePushSettingEvent event,
      Emitter<PushSettingState> emit,
      ) async {
    emit(PushSettingLoading());
    try {
      final response = await settingRepository.setPushSetting(
        like: event.like,
        comment: event.comment,
        transaction: event.transaction,
        announcement: event.announcement,
        soundOn: event.soundOn,
        soundDefault: event.soundDefault,
      );


      final responseCode = ResponseCode.fromCode(response.code);
      if (responseCode == ResponseCode.ok) {
        // Cập nhật cache bằng cách merge settings cũ + thay đổi mới
        final base = _cachedSettings ??
            PushSettingModel(
              like: 0,
              comment: 0,
              transaction: 0,
              announcement: 0,
              soundOn: 0,
              soundDefault: 1,
            );
        final updatedSettings = base.copyWith(
          like: _parseSetting(event.like),
          comment: _parseSetting(event.comment),
          transaction: _parseSetting(event.transaction),
          announcement: _parseSetting(event.announcement),
          soundOn: _parseSetting(event.soundOn),
          soundDefault: _parseSetting(event.soundDefault),
        );
        _cachedSettings = updatedSettings;

        // Emit Success ngay với dữ liệu local đã update
        emit(PushSettingSuccess(
          code: response.code,
          message: response.message,
          data: updatedSettings,
        ));

        // Tự động fetch lại từ server ở background để sync dữ liệu mới nhất
        // Nếu fail thì cũng không quan trọng vì user đã thấy success rồi
        _syncSettingsInBackground();
      } else {
        emit(PushSettingError(code: response.code, error: response.message,));
      }
    } catch (e) {
      emit(PushSettingError(error: e.toString(), code: ResponseCode.exception.code));
    }
  }

  /// Fetch dữ liệu từ server ở background mà không emit state thay đổi
  Future<void> _syncSettingsInBackground() async {
    try {
      final response = await settingRepository.getPushSetting();
      final responseCode = ResponseCode.fromCode(response.code);

      if (responseCode == ResponseCode.ok && response.data != null) {
        // Cập nhật cache nếu khác
        _cachedSettings = response.data;
        // Chỉ cập nhật cache mà không emit gì cả
        // Lần sau user tương tác hoặc quay lại màn hình sẽ thấy dữ liệu mới nhất
      }
    } catch (e) {
      // Im lặng nếu sync fail, user đã quá tải rồi
    }
  }

  int? _parseSetting(String? value) {
    if (value == null) return null;
    return int.tryParse(value);
  }
}
