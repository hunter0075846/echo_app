import '../models/friend_model.dart';
import '../models/private_message_model.dart';
import 'api_exception.dart';
import 'api_service.dart';

class MessageService {
  final ApiService _api = ApiService();

  Future<List<ConversationModel>> getConversations() async {
    final response = await _api.get('/messages/conversations');
    final List<dynamic> data = response.data;
    return data.map((item) => ConversationModel.fromJson(item)).toList();
  }

  Future<List<PrivateMessageModel>> getMessages(String receiverId) async {
    final response = await _api.get('/messages?receiverId=$receiverId');
    final List<dynamic> data = response.data;
    return data.map((item) => PrivateMessageModel.fromJson(item)).toList();
  }

  Future<PrivateMessageModel> sendMessage({
    required String receiverId,
    required String content,
    String type = 'text',
    String? mediaUrl,
  }) async {
    final response = await _api.post('/messages', data: {
      'receiverId': receiverId,
      'content': content,
      'type': type,
      if (mediaUrl != null) 'mediaUrl': mediaUrl,
    });
    return PrivateMessageModel.fromJson(response.data);
  }
}