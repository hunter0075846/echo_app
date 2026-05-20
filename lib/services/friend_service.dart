import 'dart:convert';

import '../models/friend_model.dart';
import 'api_exception.dart';
import 'api_service.dart';

class FriendService {
  final ApiService _api = ApiService();

  Future<List<FriendModel>> getFriends() async {
    final response = await _api.get('/friends');
    final List<dynamic> data = response.data;
    return data.map((item) => FriendModel.fromJson(item)).toList();
  }

  Future<List<FriendRequestModel>> getFriendRequests() async {
    final response = await _api.get('/friends/requests');
    final List<dynamic> data = response.data;
    return data.map((item) => FriendRequestModel.fromJson(item)).toList();
  }

  Future<void> sendFriendRequest(String phone) async {
    await _api.post('/friends', data: {'phone': phone});
  }

  Future<void> acceptFriendRequest(String friendId) async {
    await _api.put('/friends', data: {'friendId': friendId});
  }

  Future<void> rejectFriendRequest(String friendId) async {
    await _api.delete('/friends', data: {'friendId': friendId});
  }

  Future<void> deleteFriend(String friendId) async {
    await _api.delete('/friends', data: {'friendId': friendId});
  }
}