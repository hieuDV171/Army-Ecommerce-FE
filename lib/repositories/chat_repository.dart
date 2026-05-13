import 'package:army_ecommerce/core/api/dio_client.dart';
import 'package:army_ecommerce/core/services/session_manager.dart';
import 'package:army_ecommerce/models/conversation_model.dart';
import 'package:army_ecommerce/models/message_model.dart';
import 'package:dio/dio.dart';

class ChatRepository {
  final DioClient _dioClient;

  ChatRepository({required DioClient dioClient}) : _dioClient = dioClient;

  // Gửi tin nhắn tới to_id, tự động tạo conversation nếu chưa tồn tại
  // product_id không bắt buộc, truyền khi chat từ trang sản phẩm
  Future<SendMessageResponse> sendMessage({
    required String toId,
    required String message,
    String? productId,
  }) async {
    try {
      final token = await SessionManager.getToken();

      final data = <String, dynamic>{
        'token': token,
        'to_id': toId,
        'message': message,
      };
      if (productId != null && productId.isNotEmpty) {
        data['product_id'] = productId;
      }

      final response = await _dioClient.dio.post(
        '/chat/send_message',
        data: data,
      );

      return SendMessageResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi kết nối mạng');
    }
  }

  // Lấy danh sách tất cả conversation của người dùng hiện tại
  Future<ConversationListResponse> getListConversation({
    required int index,
    required int count,
  }) async {
    try {
      final token = await SessionManager.getToken();

      final response = await _dioClient.dio.post(
        '/chat/get_list_conversation',
        data: {
          'token': token,
          'index': index,
          'count': count,
        },
      );

      return ConversationListResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi kết nối mạng');
    }
  }

  // Lấy chi tiết tin nhắn trong một conversation
  // Truyền partner_id + product_id hoặc conversation_id
  Future<MessageListResponse> getConversation({
    String? partnerId,
    String? productId,
    String? conversationId,
    required int index,
    required int count,
  }) async {
    try {
      final token = await SessionManager.getToken();

      final data = <String, dynamic>{
        'token': token,
        'index': index,
        'count': count,
      };

      // Ưu tiên conversation_id nếu có, không thì dùng partner_id + product_id
      if (conversationId != null && conversationId.isNotEmpty) {
        data['conversation_id'] = conversationId;
      } else {
        if (partnerId != null) data['partner_id'] = partnerId;
        if (productId != null) data['product_id'] = productId;
      }

      final response = await _dioClient.dio.post(
        '/chat/get_conversation',
        data: data,
      );

      return MessageListResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi kết nối mạng');
    }
  }

  // Lấy thông tin sản phẩm mà người mua đang trao đổi với người bán
  Future<Map<String, dynamic>> getConversationDetail({
    required String conversationId,
  }) async {
    try {
      final token = await SessionManager.getToken();

      final response = await _dioClient.dio.post(
        '/chat/get_conversation_detail',
        data: {
          'token': token,
          'conversation_id': conversationId,
        },
      );

      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi kết nối mạng');
    }
  }

  // Đánh dấu đã đọc tất cả tin nhắn trong conversation với partner_id
  // Lưu ý: mobile không hiển thị trạng thái "Đã xem" trên giao diện
  Future<SimpleResponse> setReadMessage({
    required String partnerId,
    String? productId,
  }) async {
    try {
      final token = await SessionManager.getToken();

      final data = <String, dynamic>{
        'token': token,
        'partner_id': partnerId,
      };
      if (productId != null && productId.isNotEmpty) {
        data['product_id'] = productId;
      }

      final response = await _dioClient.dio.post(
        '/chat/set_read_message',
        data: data,
      );

      return SimpleResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi kết nối mạng');
    }
  }
}
