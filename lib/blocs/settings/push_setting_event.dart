abstract class PushSettingEvent {}

class FetchPushSettingEvent extends PushSettingEvent {}

class UpdatePushSettingEvent extends PushSettingEvent {
  final String? like;
  final String? comment;
  final String? transaction;
  final String? announcement;
  final String? soundOn;
  final String? soundDefault;

  UpdatePushSettingEvent({
    this.like,
    this.comment,
    this.transaction,
    this.announcement,
    this.soundOn,
    this.soundDefault,
  });
}
