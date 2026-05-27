class ApiResponse<T> {
  final String code;
  final String message;
  final T? data;

  ApiResponse({
    required this.code,
    required this.message,
    this.data
  });

  factory ApiResponse.fromJson(
      Map<String, dynamic> json,
      T Function(dynamic json)? fromJsonT
  ) {
    final hasEnvelopeData = json.containsKey('data');
    final rawData = hasEnvelopeData ? json['data'] : json;

    return ApiResponse<T>(
      code: json['code']?.toString() ?? '1000',
      message: json['message']?.toString() ?? '',
      data: _parseData(rawData, fromJsonT)
    );
  }

  factory ApiResponse.fromDynamic(
      dynamic rawData,
      T Function(dynamic json)? fromJsonT,
  ) {
    if (rawData is Map) {
      return ApiResponse<T>.fromJson(
        Map<String, dynamic>.from(rawData),
        fromJsonT,
      );
    }

    return ApiResponse<T>(
      code: '1000',
      message: '',
      data: _parseData(rawData, fromJsonT),
    );
  }

  static T? _parseData<T>(
      dynamic rawData,
      T Function(dynamic json)? fromJsonT,
  ) {
    if (rawData == null) return null;
    if (fromJsonT == null) return rawData as T;
    return fromJsonT(rawData);
  }
}
