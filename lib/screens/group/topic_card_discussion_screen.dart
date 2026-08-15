import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../models/group_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/time_formatter.dart';
import '../../widgets/echo_loading_state.dart';
import '../../widgets/gradient_scaffold.dart';

/// 群专属话题讨论页：话题信息 + 群内私域讨论（消息与群消息流同步）
class TopicCardDiscussionScreen extends ConsumerStatefulWidget {
  final String groupId;
  final String cardId;

  const TopicCardDiscussionScreen({
    super.key,
    required this.groupId,
    required this.cardId,
  });

  @override
  ConsumerState<TopicCardDiscussionScreen> createState() =>
      _TopicCardDiscussionScreenState();
}

class _TopicCardDiscussionScreenState
    extends ConsumerState<TopicCardDiscussionScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  Map<String, dynamic>? _card;
  Map<String, dynamic>? _vote;
  List<GroupMessageModel> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final service = ref.read(groupServiceProvider);
    try {
      // 进入讨论页即计为参与
      service.joinTopicCard(widget.groupId, widget.cardId).catchError((_) => 0);

      final results = await Future.wait([
        service.getTopicCard(widget.groupId, widget.cardId),
        service.getGroupMessages(widget.groupId, cardId: widget.cardId),
      ]);

      final card = results[0] as Map<String, dynamic>;
      final topicId = (card['topic'] as Map<String, dynamic>?)?['id'] as String?;
      final vote = topicId == null
          ? null
          : await service.getVote(widget.groupId, topicId).catchError((_) => null);

      if (mounted) {
        setState(() {
          _card = card;
          _vote = vote;
          // 讨论页不重复展示卡片消息本身
          _messages = (results[1] as List<GroupMessageModel>)
              .where((m) => m.type != 'topic_card')
              .toList();
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _submitVote(String option) async {
    final topicId = (_card?['topic'] as Map<String, dynamic>?)?['id'] as String?;
    if (topicId == null) return;
    try {
      final vote = await ref.read(groupServiceProvider).submitVote(
            groupId: widget.groupId,
            topicId: topicId,
            option: option,
          );
      if (mounted) setState(() => _vote = vote);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('投票失败: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  Future<void> _send() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    try {
      final message = await ref.read(groupServiceProvider).sendCardMessage(
            groupId: widget.groupId,
            cardId: widget.cardId,
            content: content,
          );
      if (mounted) {
        setState(() {
          _messages.add(message);
          _messageController.clear();
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('发送失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final topic = _card?['topic'] as Map<String, dynamic>?;

    return GradientScaffold(
      appBar: AppBar(title: Text(topic?['title'] as String? ?? '话题讨论')),
      body: _isLoading
          ? const EchoLoadingState.detail()
          : _error != null
              ? Center(child: Text('加载失败: $_error'))
              : Column(
                  children: [
                    if (topic != null) _buildTopicHeader(topic),
                    if (_vote != null) _buildVotePanel(),
                    Expanded(
                      child: _messages.isEmpty
                          ? const Center(child: Text('还没有讨论，来说第一句吧'))
                          : ListView.builder(
                              controller: _scrollController,
                              padding: EdgeInsets.all(16.w),
                              itemCount: _messages.length,
                              itemBuilder: (context, index) =>
                                  _buildMessageItem(_messages[index]),
                            ),
                    ),
                    _buildInputBar(),
                  ],
                ),
    );
  }

  Widget _buildTopicHeader(Map<String, dynamic> topic) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if ((_card?['guideText'] as String?)?.isNotEmpty == true)
            Padding(
              padding: EdgeInsets.only(bottom: 6.h),
              child: Text(
                _card!['guideText'] as String,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          Text(
            topic['description'] as String? ?? '',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13.sp,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            '已有 ${_card?['participantCount'] ?? 0} 人参与',
            style: TextStyle(
              fontSize: 11.sp,
              color: AppTheme.textTertiaryColor,
            ),
          ),
        ],
      ),
    );
  }

  /// 匿名投票区：比例可见、谁投的不可见，可改投
  Widget _buildVotePanel() {
    final vote = _vote!;
    final options = (vote['options'] as List).cast<String>();
    final counts = (vote['counts'] as Map).cast<String, num>();
    final total = (vote['total'] as num).toInt();
    final myVote = vote['myVote'] as String?;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.how_to_vote_outlined,
                  size: 16.w, color: AppTheme.primaryColor),
              SizedBox(width: 6.w),
              Text(
                '匿名投票 · $total 人参与',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          ...options.map((option) {
            final count = counts[option]?.toInt() ?? 0;
            final ratio = total == 0 ? 0.0 : count / total;
            final isMine = myVote == option;
            return GestureDetector(
              onTap: () => _submitVote(option),
              child: Container(
                margin: EdgeInsets.only(bottom: 6.h),
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: isMine
                      ? AppTheme.primaryColor.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: isMine ? AppTheme.primaryColor : AppTheme.borderColor,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        option,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                    ),
                    if (myVote != null)
                      Text(
                        '${(ratio * 100).toStringAsFixed(0)}% · $count票',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    if (isMine) ...[
                      SizedBox(width: 4.w),
                      Icon(Icons.check_circle,
                          size: 14.w, color: AppTheme.primaryColor),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMessageItem(GroupMessageModel message) {
    final currentUser = ref.read(authStateProvider).value;
    final isMe = message.senderId == currentUser?.id;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        constraints: BoxConstraints(maxWidth: 280.w),
        decoration: BoxDecoration(
          color: isMe ? AppTheme.primaryColor : AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: EdgeInsets.only(bottom: 2.h),
                child: Text(
                  message.senderName ?? '群友',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppTheme.textTertiaryColor,
                  ),
                ),
              ),
            Text(
              message.content,
              style: TextStyle(
                fontSize: 14.sp,
                color: isMe ? Colors.white : AppTheme.textPrimaryColor,
              ),
            ),
            if (message.createdAt != null)
              Padding(
                padding: EdgeInsets.only(top: 2.h),
                child: Text(
                  TimeFormatter.formatChatTime(message.createdAt),
                  style: TextStyle(
                    fontSize: 9.sp,
                    color: isMe
                        ? Colors.white70
                        : AppTheme.textTertiaryColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.borderColor)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: '参与讨论...',
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
            IconButton(
              icon: _isSending
                  ? SizedBox(
                      width: 18.w,
                      height: 18.w,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send, color: AppTheme.primaryColor),
              onPressed: _isSending ? null : _send,
            ),
          ],
        ),
      ),
    );
  }
}
