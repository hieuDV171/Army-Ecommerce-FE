class PushSettingModel {
  final int like;
  final int comment;
  final int transaction;
  final int announcement;
  final int soundOn;
  final int soundDefault;

  PushSettingModel({
    required this.like,
    required this.comment,
    required this.transaction,
    required this.announcement,
    required this.soundOn,
    required this.soundDefault,
  });

  factory PushSettingModel.fromJson(Map<String, dynamic> json) {
    return PushSettingModel(
        like: _toInt(json['like']),
        comment: _toInt(json['comment']),
        transaction: _toInt(json['transaction']),
        announcement: _toInt(json['announcement']),
        soundOn: _toInt(json['sound_on']),
        soundDefault: _toInt(json['sound_default'])
    );
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is bool) return value ? 1 : 0;
    return 0;
  }

  PushSettingModel copyWith({
    int? like,
    int? comment,
    int? transaction,
    int? announcement,
    int? soundOn,
    int? soundDefault
  }) {
    return PushSettingModel(
        like: like ?? this.like,
        comment: comment ?? this.comment,
        transaction: transaction ?? this.transaction,
        announcement: announcement ?? this.announcement,
        soundOn: soundOn ?? this.soundOn,
        soundDefault: soundDefault ?? this.soundDefault);
  }

}

class SetPushSettingRequest {
  final String token;
  final String? like;
  final String? comment;
  final String? transaction;
  final String? announcement;
  final String? soundOn;
  final String? soundDefault;

  SetPushSettingRequest({
    required this.token,
    this.like,
    this.comment,
    this.transaction,
    this.announcement,
    this.soundOn,
    this.soundDefault,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {'token': token};

    if (like != null) data['like'] = like;
    if (comment != null) data['comment'] = comment;
    if (transaction != null) data['transaction'] = transaction;
    if (announcement != null) data['announcement'] = announcement;
    if (soundOn != null) data['sound_on'] = soundOn;
    if (soundDefault != null) data['sound_default'] = soundDefault;

    return data;
  }
}