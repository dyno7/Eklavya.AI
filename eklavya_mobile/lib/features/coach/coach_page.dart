import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/services/coach_context_service.dart';
import '../../core/services/coach_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/glass_card.dart';

class CoachPage extends StatefulWidget {
  const CoachPage({super.key});

  @override
  State<CoachPage> createState() => _CoachPageState();
}

class _CoachPageState extends State<CoachPage> {
  final _service = CoachService();
  final _messages = <_Msg>[];
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _isTyping = false;
  CoachTaskContext? _taskContext;

  @override
  void initState() {
    super.initState();
    CoachContextService.pending.addListener(_handleContextChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleContextChange();
      if (_messages.isEmpty) _addGreeting(null);
    });
  }

  void _handleContextChange() {
    final ctx = CoachContextService.pending.value;
    if (ctx != null && mounted) {
      CoachContextService.consume();
      _service.startNewSession();
      setState(() {
        _taskContext = ctx;
        _messages.clear();
      });
      _addGreeting(ctx);
    }
  }

  void _addGreeting(CoachTaskContext? ctx) {
    final text = ctx != null
        ? "I'm ready to help with \"${ctx.taskTitle}\". What's your question?"
        : "Hey! I'm your learning Coach. Ask me anything about a concept, task, or resource.";
    setState(() {
      _messages.add(_Msg(text: text, isUser: false));
    });
  }

  @override
  void dispose() {
    CoachContextService.pending.removeListener(_handleContextChange);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send([String? override]) async {
    final text = override ?? _controller.text.trim();
    if (text.isEmpty || _isTyping) return;

    setState(() {
      _messages.add(_Msg(text: text, isUser: true));
      _controller.clear();
      _isTyping = true;
    });
    _scrollToBottom();

    final reply = await _service.ask(message: text, taskContext: _taskContext);

    if (!mounted) return;
    setState(() {
      _isTyping = false;
      if (reply != null) {
        _messages.add(_Msg(text: reply.text, isUser: false, resourceUrls: reply.resourceUrls));
      } else {
        _messages.add(_Msg(text: "Couldn't reach the Coach right now — try again.", isUser: false));
      }
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 300),
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
            _buildHeader(theme),
            if (_taskContext != null) _buildContextCard(theme),
            Expanded(child: _buildMessageList(theme)),
            _buildInputBar(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [context.colors.secondary, context.colors.accent],
              ),
            ),
            child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Learning Coach', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                Text('Concepts · Resources · Doubts', style: theme.textTheme.labelSmall?.copyWith(color: context.colors.textSecondary)),
              ],
            ),
          ),
          if (_taskContext != null)
            GestureDetector(
              onTap: () {
                _service.startNewSession();
                setState(() {
                  _taskContext = null;
                  _messages.clear();
                });
                _addGreeting(null);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: context.colors.surfaceLight,
                  borderRadius: AppRadii.pill,
                  border: Border.all(color: context.colors.glassBorder),
                ),
                child: Text('Clear task', style: TextStyle(fontSize: 11, color: context.colors.textSecondary)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContextCard(ThemeData theme) {
    final ctx = _taskContext!;
    return Container(
      margin: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
      decoration: BoxDecoration(
        color: context.colors.secondary.withAlpha(20),
        borderRadius: AppRadii.md,
        border: Border.all(color: context.colors.secondary.withAlpha(60)),
      ),
      child: Row(
        children: [
          Icon(Icons.bookmark_rounded, size: 16, color: context.colors.secondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (ctx.milestoneTitle != null)
                  Text(ctx.milestoneTitle!, style: theme.textTheme.labelSmall?.copyWith(color: context.colors.textSecondary)),
                Text(ctx.taskTitle, style: theme.textTheme.labelLarge?.copyWith(color: context.colors.secondary, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(ThemeData theme) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      itemCount: _messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, i) {
        if (i == _messages.length) return _buildTypingIndicator();
        final msg = _messages[i];
        return _buildBubble(theme, msg, i);
      },
    );
  }

  Widget _buildBubble(ThemeData theme, _Msg msg, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: msg.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!msg.isUser) ...[
                Container(
                  width: 28, height: 28,
                  margin: const EdgeInsets.only(right: 8, bottom: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [context.colors.secondary, context.colors.accent]),
                  ),
                  child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 14),
                ),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
                  decoration: BoxDecoration(
                    color: msg.isUser
                        ? context.colors.primary
                        : context.colors.surfaceLight,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(msg.isUser ? 18 : 4),
                      bottomRight: Radius.circular(msg.isUser ? 4 : 18),
                    ),
                    border: msg.isUser ? null : Border.all(color: context.colors.glassBorder),
                  ),
                  child: Text(
                    msg.text,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: msg.isUser ? Colors.white : context.colors.textPrimary,
                      height: 1.45,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (!msg.isUser && msg.resourceUrls.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 36, top: AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: msg.resourceUrls.map((url) => _buildResourceChip(theme, url)).toList(),
              ),
            ),
        ],
      ),
    ).animate(delay: (index * 40).ms).fadeIn(duration: 250.ms).slideY(begin: 0.05, end: 0, duration: 250.ms);
  }

  Widget _buildResourceChip(ThemeData theme, String url) {
    String label = url;
    try {
      final uri = Uri.parse(url);
      label = uri.host.replaceFirst('www.', '');
    } catch (_) {}

    return GestureDetector(
      onTap: () async {
        final uri = Uri.tryParse(url);
        if (uri != null && await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
        decoration: BoxDecoration(
          color: context.colors.primary.withAlpha(20),
          borderRadius: AppRadii.pill,
          border: Border.all(color: context.colors.primary.withAlpha(50)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.open_in_new_rounded, size: 12, color: context.colors.primaryLight),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(color: context.colors.primaryLight),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [context.colors.secondary, context.colors.accent]),
            ),
            child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 14),
          ),
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) => Container(
                width: 6, height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(shape: BoxShape.circle, color: context.colors.textSecondary),
              ).animate(onPlay: (c) => c.repeat()).fadeOut(delay: (i * 200).ms, duration: 400.ms).then().fadeIn(duration: 400.ms)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.md, AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.colors.surface.withAlpha(200),
        border: Border(top: BorderSide(color: context.colors.glassBorder)),
      ),
      child: Row(
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
                  hintText: 'Ask your Coach...',
                  hintStyle: TextStyle(color: context.colors.textTertiary),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onSubmitted: (_) => _send(),
                textInputAction: TextInputAction.send,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          GestureDetector(
            onTap: _send,
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [context.colors.secondary, context.colors.accent]),
              ),
              child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}

class _Msg {
  final String text;
  final bool isUser;
  final List<String> resourceUrls;

  const _Msg({required this.text, required this.isUser, this.resourceUrls = const []});
}
