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
    return ApiResponse<T>(
      code: json['code']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      data: _parseData(json['data'], fromJsonT)
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