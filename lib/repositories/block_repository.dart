import 'package:army_ecommerce/models/message_model.dart';
import 'package:army_ecommerce/models/user_follow_model.dart';

abstract class BlockRepository {
  Future<SimpleResponse> setBlocks({
    required String userId,
    required String action,
  });

  Future<UserFollowListResponse> getListBlocks({
    required int index,
    required int count,
  });
}
