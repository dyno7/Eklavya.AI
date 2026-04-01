import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../../core/services/chat_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import 'widgets/chat_bubble.dart';
import 'widgets/typing_indicator.dart';

class ChatTab extends StatefulWidget {
  const ChatTab({super.key});

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> {
  final _chatService = ChatService();
  final _messages = <ChatMessage>[];
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _isTyping = false;
  bool _roadmapReady = false;
  Map<String, dynamic>? _roadmap;

  @override
  void initState() {
    super.initState();
    // Add initial guru greeting
    _messages.add(ChatMessage(
      text: "Hello! I'm your Eklavya Guru for Deep Learning 🧠\n\n"
          "I'll help you create a personalized learning roadmap. "
          "Tell me — what aspect of Deep Learning interests you most?",
      isUser: false,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isTyping || _roadmapReady) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _controller.clear();
      _isTyping = true;
    });
    _scrollToBottom();

    // Simulate thinking delay for better UX
    await Future.delayed(Duration(milliseconds: 800));

    final (reply, isReady, roadmap) = await _chatService.sendMessage(text);

    setState(() {
      _isTyping = false;
      _messages.add(ChatMessage(text: reply, isUser: false));
      if (isReady) {
        _roadmapReady = true;
        _roadmap = roadmap;
      }
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            // ─── Header ───
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [context.colors.primary, context.colors.secondary],
                      ),
                    ),
                    child: Icon(Icons.smart_toy_rounded, color: Colors.white, size: 20),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Eklavya Guru', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        Text('Deep Learning', style: theme.textTheme.labelSmall?.copyWith(color: context.colors.textSecondary)),
                      ],
                    ),
                  ),
                  // Domain chip
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: context.colors.primary.withAlpha(30),
                      borderRadius: AppRadii.pill,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.school_rounded, size: 14, color: context.colors.primaryLight),
                        SizedBox(width: 4),
                        Text('Learning', style: TextStyle(fontSize: 11, color: context.colors.primaryLight, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: context.colors.glassBorder),

            // ─── Messages ───
            Expanded(
              child: Stack(
                children: [
                  ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(AppSpacing.lg),
                    itemCount: _messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index < _messages.length) {
                        return ChatBubble(message: _messages[index]);
                      }
                      return TypingIndicator();
                    },
                  ),
                  // Confetti overlay when roadmap is ready
                  if (_roadmapReady)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Lottie.asset(
                          'assets/lottie/confetti.json',
                          repeat: false,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ─── Input / Success State ───
            Container(
              padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.md, AppSpacing.lg),
              decoration: BoxDecoration(
                color: context.colors.surface.withAlpha(200),
                border: Border(top: BorderSide(color: context.colors.glassBorder)),
              ),
              child: _roadmapReady ? _buildSuccessBar(context, theme) : _buildInputBar(context, theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(BuildContext context, ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: context.colors.surfaceLight,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: context.colors.glassBorder),
            ),
            child: TextField(
              controller: _controller,
              style: TextStyle(color: context.colors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Type your message...',
                hintStyle: TextStyle(color: context.colors.textTertiary),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onSubmitted: (_) => _sendMessage(),
              textInputAction: TextInputAction.send,
            ),
          ),
        ),
        SizedBox(width: AppSpacing.sm),
        GestureDetector(
          onTap: _sendMessage,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: context.colors.primaryGradient,
            ),
            child: Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 22),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessBar(BuildContext context, ThemeData theme) {
    final milestoneCount = (_roadmap?['milestones'] as List?)?.length ?? 0;
    return Column(
      children: [
        Text(
          '🎉 Your roadmap has $milestoneCount milestones!',
          style: theme.textTheme.titleSmall?.copyWith(color: context.colors.primaryLight),
        ),
        SizedBox(height: AppSpacing.md),
        GestureDetector(
          onTap: () {
            context.go('/');
          },
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              gradient: context.colors.primaryGradient,
              borderRadius: AppRadii.pill,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'View Your Roadmap',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
              ],
            ),
          ),
        ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0, duration: 400.ms),
      ],
    );
  }
}
