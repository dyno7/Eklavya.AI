import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../../core/services/chat_seed_service.dart';
import '../../core/services/chat_service.dart';
import '../../core/services/roadmap_sync_service.dart';
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
  List<ChatSession> _sessions = [];
  bool _sessionsLoading = false;
  bool _sessionsDirty = true; // reload only when drawer is opened

  @override
  void initState() {
    super.initState();
    _addGreeting();
    _loadSessions();
    ChatSeedService.pending.addListener(_handleSeedMessage);
    // Handle a seed that was set before this widget was first built
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleSeedMessage());
  }

  void _handleSeedMessage() {
    final msg = ChatSeedService.pending.value;
    if (msg != null && mounted) {
      ChatSeedService.consume();
      _sendMessage(msg);
    }
  }

  void _addGreeting() {
    _messages.add(ChatMessage(
      text: "Hey! What skill or goal do you want to master? 🧠",
      isUser: false,
    ));
  }

  Future<void> _loadSessions({bool force = false}) async {
    if (!force && !_sessionsDirty) return;
    setState(() => _sessionsLoading = true);
    final sessions = await _chatService.getSessions();
    if (mounted) {
      setState(() {
        _sessions = sessions;
        _sessionsLoading = false;
        _sessionsDirty = false;
      });
    }
  }

  Future<void> _startNewChat() async {
    await _chatService.startNewSession();
    if (!mounted) return;
    setState(() {
      _messages.clear();
      _roadmapReady = false;
      _roadmap = null;
    });
    _addGreeting();
    Navigator.of(context).pop(); // close drawer
  }

  Future<void> _loadSession(ChatSession session) async {
    Navigator.of(context).pop(); // close drawer
    setState(() {
      _messages.clear();
      _roadmapReady = false;
      _roadmap = null;
      _isTyping = true;
    });

    final messages = await _chatService.loadSession(session.sessionId);
    if (mounted) {
      setState(() {
        _messages.addAll(messages);
        _isTyping = false;
      });
      _scrollToBottom();
    }
  }

  @override
  void dispose() {
    ChatSeedService.pending.removeListener(_handleSeedMessage);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage([String? overrideText]) async {
    final text = overrideText ?? _controller.text.trim();
    if (text.isEmpty || _isTyping) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _controller.clear();
      _isTyping = true;
    });
    _scrollToBottom();

    await Future.delayed(Duration(milliseconds: 400));

    final (reply, isReady, roadmap, navigateToRoadmap, options, resources, tone) = await _chatService.sendMessage(text);

    setState(() {
      _isTyping = false;
      _messages.add(ChatMessage(text: reply, isUser: false, options: options, resources: resources, tone: tone));
      if (isReady) {
        _roadmapReady = true;
        _roadmap = roadmap;
      }
    });

    if (isReady) {
      RoadmapSyncService.notifyRoadmapUpdated();
    }

    _scrollToBottom();
    _sessionsDirty = true; // refresh sidebar next time drawer opens

    if (navigateToRoadmap || isReady) {
      if (mounted) context.go('/goals');
    }
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
      drawer: _buildSessionsDrawer(context, theme),
      body: SafeArea(
        child: Column(
          children: [
            // ─── Header ───
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              child: Row(
                children: [
                  // Hamburger menu for sessions drawer
                  Builder(builder: (ctx) => GestureDetector(
                    onTap: () {
                      _loadSessions();
                      Scaffold.of(ctx).openDrawer();
                    },
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: context.colors.surfaceLight,
                        border: Border.all(color: context.colors.glassBorder),
                      ),
                      child: Icon(Icons.menu_rounded, color: context.colors.textSecondary, size: 18),
                    ),
                  )),
                  SizedBox(width: AppSpacing.md),
                  Container(
                    width: 36, height: 36,
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
                        Text('Goal Planner & Mentor', style: theme.textTheme.labelSmall?.copyWith(color: context.colors.textSecondary)),
                      ],
                    ),
                  ),
                  // New Chat button
                  GestureDetector(
                    onTap: () async {
                      await _chatService.startNewSession();
                      if (!mounted) return;
                      setState(() {
                        _messages.clear();
                        _roadmapReady = false;
                        _roadmap = null;
                      });
                      _addGreeting();
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: context.colors.primary.withAlpha(30),
                        borderRadius: AppRadii.pill,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_rounded, size: 14, color: context.colors.primaryLight),
                          SizedBox(width: 4),
                          Text('New', style: TextStyle(fontSize: 11, color: context.colors.primaryLight, fontWeight: FontWeight.w600)),
                        ],
                      ),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_roadmapReady) ...[
                    _buildSuccessBar(context, theme),
                    SizedBox(height: AppSpacing.md),
                  ],
                  if (_hasActiveOptions && !_roadmapReady)
                    _buildOptionChips(context, theme)
                  else
                    _buildInputBar(context, theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionsDrawer(BuildContext context, ThemeData theme) {
    return Drawer(
      backgroundColor: context.colors.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drawer header
            Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Icon(Icons.chat_bubble_outline_rounded, color: context.colors.primary, size: 22),
                  SizedBox(width: AppSpacing.md),
                  Text('Conversations', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            ),

            // New Chat button
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: GestureDetector(
                onTap: _startNewChat,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    gradient: context.colors.primaryGradient,
                    borderRadius: AppRadii.md,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_rounded, color: Colors.white, size: 18),
                      SizedBox(width: 6),
                      Text('New Chat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: AppSpacing.lg),

            Divider(height: 1, color: context.colors.glassBorder),

            // Sessions list
            Expanded(
              child: _sessionsLoading
                  ? Center(child: CircularProgressIndicator(strokeWidth: 2, color: context.colors.primary))
                  : _sessions.isEmpty
                      ? Center(child: Text('No past conversations', style: theme.textTheme.bodySmall?.copyWith(color: context.colors.textTertiary)))
                      : ListView.builder(
                          padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                          itemCount: _sessions.length,
                          itemBuilder: (context, index) {
                            final session = _sessions[index];
                            final isActive = session.sessionId == _chatService.currentSessionId;
                            return _buildSessionTile(context, theme, session, isActive);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionTile(BuildContext context, ThemeData theme, ChatSession session, bool isActive) {
    String timeAgo = '';
    if (session.lastMessageAt != null) {
      final dt = DateTime.tryParse(session.lastMessageAt!);
      if (dt != null) {
        final diff = DateTime.now().difference(dt);
        if (diff.inMinutes < 60) {
          timeAgo = '${diff.inMinutes}m ago';
        } else if (diff.inHours < 24) {
          timeAgo = '${diff.inHours}h ago';
        } else {
          timeAgo = '${dt.month}/${dt.day}';
        }
      }
    }

    return GestureDetector(
      onTap: () => _loadSession(session),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 2),
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
        decoration: BoxDecoration(
          color: isActive ? context.colors.primary.withAlpha(20) : Colors.transparent,
          borderRadius: AppRadii.md,
          border: isActive ? Border.all(color: context.colors.primary.withAlpha(40)) : null,
        ),
        child: Row(
          children: [
            Icon(Icons.chat_outlined, size: 16, color: context.colors.textSecondary),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                      color: context.colors.textPrimary,
                    ),
                  ),
                  if (timeAgo.isNotEmpty)
                    Text(timeAgo, style: theme.textTheme.labelSmall?.copyWith(color: context.colors.textTertiary, fontSize: 10)),
                ],
              ),
            ),
            Text('${session.messageCount}', style: theme.textTheme.labelSmall?.copyWith(color: context.colors.textTertiary)),
          ],
        ),
      ),
    );
  }

  bool get _hasActiveOptions {
    if (_messages.isEmpty) return false;
    final last = _messages.last;
    return !last.isUser && last.options != null && last.options!.isNotEmpty;
  }

  Widget _buildOptionChips(BuildContext context, ThemeData theme) {
    final options = _messages.last.options!;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      alignment: WrapAlignment.center,
      children: options.map((option) {
        return GestureDetector(
          onTap: () => _sendMessage(option),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              gradient: context.colors.primaryGradient,
              borderRadius: AppRadii.pill,
              boxShadow: [
                BoxShadow(
                  color: context.colors.primary.withAlpha(60),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              option,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ).animate().fadeIn(duration: 300.ms).scale(begin: Offset(0.9, 0.9), end: Offset(1, 1), duration: 300.ms);
      }).toList(),
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
        _AnimatedSendButton(onTap: _sendMessage),
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
            context.go('/goals');
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

/// Send button that springs (scale down on press, bounce back on release).
class _AnimatedSendButton extends StatefulWidget {
  final VoidCallback onTap;
  const _AnimatedSendButton({required this.onTap});

  @override
  State<_AnimatedSendButton> createState() => _AnimatedSendButtonState();
}

class _AnimatedSendButtonState extends State<_AnimatedSendButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 80),
    reverseDuration: const Duration(milliseconds: 300),
    lowerBound: 0.0,
    upperBound: 1.0,
    value: 1.0,
  );

  late final Animation<double> _scale = CurvedAnimation(
    parent: _ctrl,
    curve: Curves.easeIn,
    reverseCurve: Curves.elasticOut,
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _ctrl.reverse(from: 0.82);
  void _onTapUp(TapUpDetails _) {
    _ctrl.forward();
    widget.onTap();
  }
  void _onTapCancel() => _ctrl.forward();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: context.colors.primaryGradient,
          ),
          child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}
