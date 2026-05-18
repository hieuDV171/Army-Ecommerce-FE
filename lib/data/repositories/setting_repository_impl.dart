
import '../../models/api_response.dart';
import '../../models/push_setting_model.dart';
import '../../repositories/setting_repository.dart';
import '../sources/remote/setting_remote_data_source.dart';

class SettingRepositoryImpl implements SettingRepository {
  final SettingRemoteDataSource remoteDataSource;

  SettingRepositoryImpl({required this.remoteDataSource});

  @override
  Future<ApiResponse<PushSettingModel>> getPushSetting() {
    return remoteDataSource.getPushSetting();
  }

  @override
  Future<ApiResponse<String?>> setPushSetting({
    String? like,
    String? comment,
    String? transaction,
    String? announcement,
    String? soundOn,
    String? soundDefault,
  }) {
    return remoteDataSource.setPushSetting(
      like: like,
      comment: comment,
      transaction: transaction,
      announcement: announcement,
      soundOn: soundOn,
      soundDefault: soundDefault,
    );
  }

}