import 'package:army_ecommerce/core/api/dio_client.dart';
import 'package:army_ecommerce/models/conversation_model.dart';
import 'package:army_ecommerce/models/message_model.dart';
import 'package:dio/dio.dart';

class ChatRepository {
  final DioClient _dioClient;

  ChatRepository({required DioClient dioClient}) : _dioClient = dioClient;

  // Gửi tin nhắn tới to_id, tự động tạo conversation nếu chưa tồn tại
  // type_message: 'text' | 'image' | 'video' | 'file'
  // product_id bắt buộc theo spec (truyền 0 nếu không có sản phẩm liên quan)
  Future<SendMessageResponse> sendMessage({
    required String toId,
    required String message,
    required String typeMessage,
    required int productId,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        '/conversation/send_message',
        data: {
          'to_id': int.tryParse(toId) ?? 0,
          'message': message,
          'type_message': typeMessage,
          'product_id': productId,
        },
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
      final response = await _dioClient.dio.post(
        '/conversation/get_list_conversation',
        data: {
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
  // Cả partner_id và conversation_id đều bắt buộc theo spec
  Future<MessageListResponse> getConversation({
    required int partnerId,
    required int conversationId,
    required int index,
    required int count,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        '/conversation/get_conversation',
        data: {
          'partner_id': partnerId,
          'conversation_id': conversationId,
          'index': index,
          'count': count,
        },
      );

      return MessageListResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi kết nối mạng');
    }
  }

  // Đánh dấu đã đọc tất cả tin nhắn trong conversation với partner_id
  // Lưu ý: mobile không hiển thị trạng thái "Đã xem" trên giao diện
  Future<SimpleResponse> setReadMessage({
    required int partnerId,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        '/conversation/set_read_message',
        data: {
          'partner_id': partnerId,
        },
      );

      return SimpleResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi kết nối mạng');
    }
  }
}
