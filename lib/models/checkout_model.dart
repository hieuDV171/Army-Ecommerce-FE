import 'model_helpers.dart';

class ShipFeeModel {
  final num shipFee;
  final int leatime;

  const ShipFeeModel({required this.shipFee, required this.leatime});

  factory ShipFeeModel.fromJson(Map<String, dynamic> json) {
    return ShipFeeModel(
      shipFee: (json['ship_fee'] ?? json['shipfee'] ?? 0) as num,
      leatime: (json['leatime'] ?? 0) as int,
    );
  }
}

class ShipFromModel {
  final String id;
  final String name;
  final String? pickSupport;
  final String? messagePickSupport;

  const ShipFromModel({
    required this.id,
    required this.name,
    this.pickSupport,
    this.messagePickSupport,
  });

  factory ShipFromModel.fromJson(Map<String, dynamic> json) {
    return ShipFromModel(
      id: readString(json, ['id']),
      name: readString(json, ['name'], fallback: 'Kho hàng'),
      pickSupport: readOptionalString(json, ['pick_support']),
      messagePickSupport: readOptionalString(json, ['message_pick_support']),
    );
  }
}

class RewardHistoryModel {
  final String userId;
  final String? rewardId;
  final int receivedCoin;
  final int availableBalance;
  final String? description;
  final num? aiScore;
  final String? createdAt;
  final String? videoUrl;
  final String? imageUrl;

  const RewardHistoryModel({
    required this.userId,
    this.rewardId,
    required this.receivedCoin,
    required this.availableBalance,
    this.description,
    this.aiScore,
    this.createdAt,
    this.videoUrl,
    this.imageUrl,
  });

  factory RewardHistoryModel.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'];
    final parsedUserId = userJson is Map ? readString(Map<String, dynamic>.from(userJson), ['id']) : readString(json, ['user_id']);

    return RewardHistoryModel(
      userId: parsedUserId,
      rewardId: readOptionalString(json, ['id', 'reward_id']),
      receivedCoin: readNum(json, ['reward_coin', 'received_coin']).toInt(),
      availableBalance: readNum(json, ['available_balance']).toInt(),
      description: readOptionalString(json, ['description']),
      aiScore: readDouble(json, ['ai_score']),
      createdAt: readOptionalString(json, ['created_at']),
      videoUrl: readOptionalString(json, ['video_url']),
      imageUrl: readOptionalString(json, ['image_url']),
    );
  }
}

class RewardAppealModel {
  final String? appealId;
  final String? rewardId;
  final String? videoId;
  final String? status;

  const RewardAppealModel({
    this.appealId,
    this.rewardId,
    this.videoId,
    this.status,
  });

  factory RewardAppealModel.fromJson(Map<String, dynamic> json) {
    final proofJson = json['proof'];
    final parsedRewardId = proofJson is Map ? readOptionalString(Map<String, dynamic>.from(proofJson), ['id']) : readOptionalString(json, ['reward_id', 'proof_id']);

    return RewardAppealModel(
      appealId: readOptionalString(json, ['id', 'appeal_id']),
      rewardId: parsedRewardId,
      videoId: readOptionalString(json, ['video_id']),
      status: readOptionalString(json, ['status']),
    );
  }
}

class UploadVideoResponseModel {
  final String videoId;
  final String video; // url_video
  final String thumb; // url_thumb
  final int bonusCoin;

  const UploadVideoResponseModel({
    required this.videoId,
    required this.video,
    required this.thumb,
    required this.bonusCoin,
  });

  factory UploadVideoResponseModel.fromJson(Map<String, dynamic> json) {
    return UploadVideoResponseModel(
      videoId: readString(json, ['video_id']),
      video: readString(json, ['video']),
      thumb: readString(json, ['thumb']),
      bonusCoin: readInt(json, ['bonus_coin']) ?? 0,
    );
  }
}
