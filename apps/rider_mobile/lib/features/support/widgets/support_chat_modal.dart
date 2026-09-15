// lib/features/support/widgets/support_chat_modal.dart

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rider_app/core/theme/app_theme.dart';
import 'package:rider_app/features/support/models/support_models.dart';
import 'package:rider_app/features/support/providers/support_provider.dart';

class SupportChatModal extends ConsumerStatefulWidget {
  final SupportCategoryType category;
  final String description;

  const SupportChatModal({
    super.key,
    required this.category,
    required this.description,
  });

  static Future<void> show(
    BuildContext context, {
    required SupportCategoryType category,
    required String description,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => SupportChatModal(
        category: category,
        description: description,
      ),
    );
  }

  @override
  ConsumerState<SupportChatModal> createState() => _SupportChatModalState();
}

class _SupportChatModalState extends ConsumerState<SupportChatModal> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _pendingImageUrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(supportChatNotifierProvider.notifier).initiateChat(
            category: widget.category.code,
            subject: '${widget.category.label}: ${widget.description.isNotEmpty ? widget.description.split('.').first : 'Customer support request'}',
            description: widget.description.isNotEmpty
                ? widget.description
                : 'Customer initiated live support chat.',
          );
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSend() {
    final text = _textController.text.trim();
    if (text.isEmpty && _pendingImageUrl == null) return;

    ref.read(supportChatNotifierProvider.notifier).sendMessage(
          text,
          attachmentUrl: _pendingImageUrl,
        );

    _textController.clear();
    setState(() => _pendingImageUrl = null);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(supportChatNotifierProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final size = MediaQuery.of(context).size;

    _scrollToBottom();

    return Container(
      height: size.height * 0.88,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // 1. Header with presence and controls
            _buildHeader(context, chatState),

            // 2. Reconnection or Queue Banner
            if (chatState.status == ChatConnectionStatus.reconnecting)
              _buildBanner(
                icon: Icons.sync_rounded,
                text: 'Connection interrupted. Reconnecting…',
                bgColor: const Color(0xFFFDE8E4),
                textColor: AppColors.primary,
              ),

            if (chatState.status == ChatConnectionStatus.inQueue)
              _buildBanner(
                icon: Icons.hourglass_top_rounded,
                text: 'You\'re in the queue (Position ${chatState.queuePosition}). Specialist connecting soon…',
                bgColor: const Color(0xFFD7ECE6),
                textColor: const Color(0xFF236C5F),
              ),

            // 3. Message Stream
            Expanded(
              child: chatState.status == ChatConnectionStatus.connecting
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: AppColors.primary),
                          SizedBox(height: 16),
                          Text(
                            'Connecting you to a support specialist…',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              color: AppColors.onSurfaceMuted,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: chatState.messages.length,
                      itemBuilder: (context, index) {
                        final msg = chatState.messages[index];
                        return _buildMessageBubble(msg);
                      },
                    ),
            ),

            // 4. Typing Indicator
            if (chatState.isAgentTyping)
              Padding(
                padding: const EdgeInsets.only(left: 20, bottom: 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${chatState.agentName ?? 'Specialist'} is typing…',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: AppColors.onSurfaceMuted,
                    ),
                  ),
                ),
              ),

            // 5. Image attachment preview thumbnail if selected
            if (_pendingImageUrl != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: AppColors.surface,
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 48,
                        height: 48,
                        color: const Color(0xFFF3EDE4),
                        child: const Icon(Icons.image_rounded, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Screenshot attached',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () => setState(() => _pendingImageUrl = null),
                    ),
                  ],
                ),
              ),

            // 6. Input Bar or Ended CSAT prompt
            if (chatState.status == ChatConnectionStatus.ended)
              _buildEndedCsatBar(context, chatState)
            else
              _buildInputBar(context, chatState, bottomInset),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, SupportChatState state) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(bottom: BorderSide(color: AppColors.surfaceBorder, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFFF3EDE4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.support_agent_rounded, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          state.agentName ?? 'Support Specialist',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onBackground,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (state.isAgentOnline)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD7ECE6),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.circle, size: 6, color: Color(0xFF2E7D32)),
                                SizedBox(width: 4),
                                Text(
                                  'Online',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF236C5F),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    Text(
                      state.ticketNumber != null ? 'Case #${state.ticketNumber}' : 'FairGo 24/7 Live Care',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.onSurfaceMuted,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.minimize_rounded, size: 20, color: AppColors.onSurfaceMuted),
                tooltip: 'Minimize',
                onPressed: () => Navigator.of(context).pop(),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.error),
                tooltip: 'End Chat',
                onPressed: () => _confirmEndChat(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBanner({
    required IconData icon,
    required String text,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      width: double.infinity,
      color: bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessageModel msg) {
    if (msg.sender == ChatMessageSender.system) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF3EDE4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            msg.content,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.onSurfaceMuted,
            ),
          ),
        ),
      );
    }

    final isMe = msg.sender == ChatMessageSender.customer;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.76),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
          border: isMe ? null : Border.all(color: AppColors.surfaceBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (msg.type == 'IMAGE' && msg.attachmentUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 120,
                  width: double.infinity,
                  color: isMe ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFF3EDE4),
                  child: const Center(
                    child: Icon(Icons.image_rounded, size: 36, color: AppColors.onSurfaceMuted),
                  ),
                ),
              ),
              const SizedBox(height: 6),
            ],
            Text(
              msg.content,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: isMe ? Colors.white : AppColors.onBackground,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${msg.createdAt.hour.toString().padLeft(2, '0')}:${msg.createdAt.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                color: isMe ? Colors.white.withValues(alpha: 0.7) : AppColors.onSurfaceMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(BuildContext context, SupportChatState state, double bottomInset) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.surfaceBorder, width: 1)),
      ),
      padding: EdgeInsets.fromLTRB(16, 10, 16, 12 + bottomInset),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file_rounded, color: AppColors.onSurfaceMuted),
            tooltip: 'Attach Screenshot',
            onPressed: () {
              setState(() {
                _pendingImageUrl = 'https://storage.fairgo.in/support-attachments/screenshot.png';
              });
            },
          ),
          Expanded(
            child: TextField(
              controller: _textController,
              onChanged: (text) {
                ref.read(supportChatNotifierProvider.notifier).sendTyping(text.isNotEmpty);
              },
              onSubmitted: (_) => _handleSend(),
              decoration: const InputDecoration(
                hintText: 'Type a message…',
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                fillColor: Color(0xFFFBF9F5),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
            ),
            onPressed: _handleSend,
          ),
        ],
      ),
    );
  }

  Widget _buildEndedCsatBar(BuildContext context, SupportChatState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.surfaceBorder, width: 1)),
      ),
      child: Column(
        children: [
          const Text(
            'Chat ended • Was this conversation helpful?',
            style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(supportChatNotifierProvider.notifier).submitCsat(5, 'Helpful');
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.thumb_up_rounded, size: 16),
                label: const Text('Helpful'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD7ECE6),
                  foregroundColor: const Color(0xFF236C5F),
                  minimumSize: const Size(120, 42),
                  elevation: 0,
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(supportChatNotifierProvider.notifier).submitCsat(2, 'Not resolved');
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.thumb_down_rounded, size: 16),
                label: const Text('Not resolved'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFDE8E4),
                  foregroundColor: AppColors.primary,
                  minimumSize: const Size(120, 42),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmEndChat(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End Chat?'),
        content: const Text('Are you sure you want to end this conversation with the support specialist?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(supportChatNotifierProvider.notifier).endChat();
            },
            child: const Text('End Chat', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
