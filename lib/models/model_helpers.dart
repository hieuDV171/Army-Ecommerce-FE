import 'package:equatable/equatable.dart';

class MarketplaceItem extends Equatable {
  final String id;
  final String title;
  final String subtitle;
  final String? trailing;
  // Trường ảnh — BE chưa trả về; parse sẵn để khi BE thêm sẽ hoạt động ngay
  final String? imageUrl;

  const MarketplaceItem({
    required this.id,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.imageUrl,
  });

  factory MarketplaceItem.fromJson(Map<String, dynamic> json) {
    return MarketplaceItem(
      id: readString(json, [
        'id',
        'notification_id',
        'purchase_id',
        'conversation_id',
      ]),
      title: readString(json, [
        'title',
        'name',
        'username',
        'status',
        'keyword',
      ], fallback: 'Mục dữ liệu'),
      subtitle: readString(json, [
        'message',
        'content',
        'description',
        'address',
        'last_message',
      ], fallback: ''),
      trailing: readOptionalString(json, [
        'created_at',
        'time',
        'state',
        'total',
      ]),
      imageUrl: readOptionalString(json, [
        'image_url',
        'thumbnail',
        'image',
        'cover',
      ]),
    );
  }

  @override
  List<Object?> get props => [id, title, subtitle, trailing, imageUrl];
}

List<T> parseListFromData<T>(
  dynamic data,
  T Function(Map<String, dynamic> json) fromJson,
) {
  final rawList = findList(data);
  return rawList
      .whereType<Map>()
      .map((item) => fromJson(Map<String, dynamic>.from(item)))
      .toList();
}

Map<String, dynamic> parseMapFromData(dynamic data) {
  final rawMap = findMap(data);
  return rawMap == null
      ? <String, dynamic>{}
      : Map<String, dynamic>.from(rawMap);
}

List<dynamic> findList(dynamic data) {
  if (data is List) return data;
  if (data is Map) {
    for (final key in [
      'items',
      'data',
      'products',
      'categories',
      'list',
      'rows',
      'result',
    ]) {
      final value = data[key];
      if (value is List) return value;
      if (value is Map || value is List) {
        final nested = findList(value);
        if (nested.isNotEmpty) return nested;
      }
    }
  }
  return const [];
}

Map? findMap(dynamic data) {
  if (data is Map) {
    final nestedData = data['data'];
    if (nestedData is Map) return nestedData;
    return data;
  }
  return null;
}

String readString(
  Map<String, dynamic> json,
  List<String> keys, {
  String fallback = '',
}) {
  for (final key in keys) {
    final value = json[key];
    if (value != null && value.toString().isNotEmpty) return value.toString();
  }
  return fallback;
}

String? readOptionalString(Map<String, dynamic> json, List<String> keys) {
  final value = readString(json, keys);
  return value.isEmpty ? null : value;
}

num readNum(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is num) return value;
    final parsed = num.tryParse(value?.toString() ?? '');
    if (parsed != null) return parsed;
  }
  return 0;
}

int? readInt(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is int) return value;
    final parsed = int.tryParse(value?.toString() ?? '');
    if (parsed != null) return parsed;
  }
  return null;
}

double? readDouble(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is double) return value;
    if (value is int) return value.toDouble();
    final parsed = double.tryParse(value?.toString() ?? '');
    if (parsed != null) return parsed;
  }
  return null;
}

bool? readBool(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is bool) return value;
    final normalized = value?.toString().toLowerCase();
    if (normalized == '1' || normalized == 'true') return true;
    if (normalized == '0' || normalized == 'false') return false;
  }
  return null;
}

List<String> readStringList(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is List) {
      return value
          .map((item) => item.toString())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    if (value is String && value.isNotEmpty) return [value];
  }
  return const [];
}

Map<String, dynamic>? readMap(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is Map) return Map<String, dynamic>.from(value);
  }
  return null;
}
