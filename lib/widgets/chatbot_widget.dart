import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/chatbot_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Colours (matches app design system)
// ─────────────────────────────────────────────────────────────────────────────

const _black = Color(0xFF111111);
const _card  = Color(0xFF1A1A1A);
const _card2 = Color(0xFF222222);
const _lime  = Color(0xFFCDFC49);
const _white = Color(0xFFFFFFFF);
const _grey  = Color(0xFF888888);

TextStyle _heading(double size, {Color color = _white}) =>
    GoogleFonts.bebasNeue(fontSize: size, color: color, letterSpacing: 1.5);
TextStyle _body(double size, {Color color = _white}) =>
    GoogleFonts.nunito(fontSize: size, color: color);

// ─────────────────────────────────────────────────────────────────────────────
// Chatbot floating button + overlay widget
// Add this to any screen's Stack as the last child
// ─────────────────────────────────────────────────────────────────────────────

class ChatbotWidget extends StatefulWidget {
  final ChatPersona persona;

  const ChatbotWidget({super.key, required this.persona});

  @override
  State<ChatbotWidget> createState() => _ChatbotWidgetState();
}

class _ChatbotWidgetState extends State<ChatbotWidget> {
  final ChatbotService        _service = ChatbotService();
  final List<ChatMessage>     _history = [];
  final TextEditingController _ctrl    = TextEditingController();
  final ScrollController      _scroll  = ScrollController();

  bool _isOpen    = false;
  bool _isLoading = false;

  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    requestOpenChat.addListener(_handleOpenRequest);
    WidgetsBinding.instance.addPostFrameCallback((_) => _insertOverlay());
  }

  void _handleOpenRequest() {
    if (requestOpenChat.value == widget.persona) {
      _isOpen = true;
      _refreshOverlay();
      requestOpenChat.value = null;
    }
  }

  void _insertOverlay() {
    _overlayEntry = OverlayEntry(builder: (_) => _buildOverlay());
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _refreshOverlay() {
    _overlayEntry?.markNeedsBuild();
  }

  @override
  void dispose() {
    requestOpenChat.removeListener(_handleOpenRequest);
    _overlayEntry?.remove();
    _service.dispose();
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // ── Send text message ─────────────────────────────────────────────────────

  Future<void> _sendText() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _isLoading) return;

    _ctrl.clear();
    _history.add(ChatMessage(text: text, isUser: true));
    _isLoading = true;
    _refreshOverlay();
    _scrollToBottom();

    try {
      final reply = await _service.sendMessage(
        userMessage: text,
        persona:     widget.persona,
        history:     _history,
      );
      if (mounted) {
        _history.add(ChatMessage(text: reply, isUser: false));
        _isLoading = false;
        _refreshOverlay();
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        _history.add(ChatMessage(
            text: 'Sorry, something went wrong. Try again.', isUser: false));
        _isLoading = false;
        _refreshOverlay();
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String get _botName {
    switch (widget.persona) {
      case ChatPersona.customer:  return 'NikeBot';
      case ChatPersona.inspector: return 'RouteBot';
      case ChatPersona.admin:     return 'DashBot';
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();

  Widget _buildOverlay() {
    if (!_isOpen) return const SizedBox.shrink();
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                _isOpen = false;
                _refreshOverlay();
              },
              child: Container(color: Colors.transparent),
            ),
          ),
          _buildChatPanel(),
        ],
      ),
    );
  }

  // ── Chat panel ────────────────────────────────────────────────────────────

  Widget _buildChatPanel() {
    return Positioned(
      bottom: 182,
      right: 16,
      left: 16,
      child: Material(
        color: Colors.transparent,
        child: Container(
          height: 420,
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _lime, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: _lime.withOpacity(0.12),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              _buildPanelHeader(),
              Expanded(child: _buildMessageList()),
              if (_isLoading) _buildTypingIndicator(),
              _buildInputRow(),
            ],
          ),
        ),
      )
          .animate()
          .fadeIn(duration: 250.ms)
          .slideY(begin: 0.1, end: 0, duration: 250.ms),
    );
  }

  Widget _buildPanelHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: _card2,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: _lime,
              shape: BoxShape.circle,
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(begin: 1.0, end: 1.4, duration: 800.ms),
          const SizedBox(width: 10),
          Text(_botName, style: _heading(18, color: _lime)),
          const Spacer(),
          GestureDetector(
            onTap: () {
              _isOpen = false;
              _refreshOverlay();
            },
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: _black,
                shape: BoxShape.circle,
                border: Border.all(color: _grey.withOpacity(0.5)),
              ),
              child: const Icon(Icons.close, color: _white, size: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    if (_history.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline, color: _grey, size: 32),
            const SizedBox(height: 12),
            Text(
              'Ask me anything.',
              style: _body(14, color: _grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: _history.length,
      itemBuilder: (_, i) => _buildBubble(_history[i]),
    );
  }

  Widget _buildBubble(ChatMessage msg) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: msg.isUser ? _lime : _card2,
          borderRadius: BorderRadius.only(
            topLeft:     const Radius.circular(16),
            topRight:    const Radius.circular(16),
            bottomLeft:  Radius.circular(msg.isUser ? 16 : 4),
            bottomRight: Radius.circular(msg.isUser ? 4 : 16),
          ),
        ),
        child: Text(
          msg.text,
          style: _body(13, color: msg.isUser ? _black : _white),
        ),
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 4),
      child: Row(
        children: [
          Text('${_botName} is typing', style: _body(12, color: _grey)),
          const SizedBox(width: 6),
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
                color: _lime, strokeWidth: 2),
          ),
        ],
      ),
    );
  }

  Widget _buildInputRow() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: const BoxDecoration(
        color: _card2,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
        children: [
          // Text input
          Expanded(
            child: TextField(
              controller: _ctrl,
              style: _body(13, color: _white),
              maxLines: 1,
              onSubmitted: (_) => _sendText(),
              decoration: InputDecoration(
                hintText: 'Ask ${_botName}...',
                hintStyle: _body(13, color: _grey),
                filled: true,
                fillColor: _black,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Send button
          GestureDetector(
            onTap: _sendText,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _isLoading ? _grey : _lime,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.send_rounded,
                color: _black,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
