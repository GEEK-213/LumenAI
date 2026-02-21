import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

// --- Data Model for Messages
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;

  ChatMessage({required this.text, required this.isUser, required this.time});
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  final String _baseUrl = Platform.isAndroid
      ? 'http://10.0.2.2:8001'
      : 'http://127.0.0.1:8001';

  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;
    final name =
        user?.userMetadata?['full_name']?.toString().split(' ').first ??
        user?.email?.split('@').first ??
        'there';
    _messages.add(
      ChatMessage(
        text:
            "Hello, $name! I'm Lumen AI. How can I help you with your studies today?",
        isUser: false,
        time: DateTime.now(),
      ),
    );
  }

  Future<void> _handleSubmitted(String text) async {
    _textController.clear();
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(
        ChatMessage(text: text, isUser: true, time: DateTime.now()),
      );
      _isTyping = true;
    });
    _scrollToBottom();

    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/chat/ask'),
            body: {'question': text, 'context': ''},
          )
          .timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);
      final answer = data['answer'] ?? 'Sorry, I could not get a response.';

      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add(
            ChatMessage(text: answer, isUser: false, time: DateTime.now()),
          );
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add(
            ChatMessage(
              text:
                  'Sorry, I could not connect to the backend. Make sure the server is running.',
              isUser: false,
              time: DateTime.now(),
            ),
          );
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // --- App Bar ---
      appBar: AppBar(
        backgroundColor: const Color(0xFF050B18),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () {},
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.smart_toy,
                color: Colors.purpleAccent,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              "Lumen AI",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.more_horiz)),
        ],
      ),

      // --- Body ---
      body: Column(
        children: [
          // 1. Message List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),

          // 2. Typing Indicator
          if (_isTyping)
            Padding(
              padding: const EdgeInsets.only(left: 20, bottom: 10),
              child: Row(
                children: [
                  const Text(
                    "Lumen AI is typing",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  _buildDot(0),
                  _buildDot(150),
                  _buildDot(300),
                ],
              ),
            ),

          // 3. Input Area
          _buildInputArea(),
        ],
      ),
    );
  }

  // --- Widget: Message Bubble ---
  Widget _buildMessageBubble(ChatMessage message) {
    final isMe = message.isUser;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          // Gradient for User, Solid Dark Color for AI
          gradient: isMe
              ? const LinearGradient(
                  colors: [Color(0xFF448AFF), Color(0xFF8E24AA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isMe ? null : const Color(0xFF1E2746), // AI Bubble Color
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: isMe
                ? const Radius.circular(20)
                : const Radius.circular(0),
            bottomRight: isMe
                ? const Radius.circular(0)
                : const Radius.circular(20),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "${message.time.hour}:${message.time.minute.toString().padLeft(2, '0')}",
              style: TextStyle(
                color: isMe
                    ? Colors.white.withOpacity(0.7)
                    : Colors.grey.shade500,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Widget: Input Area ---
  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF050B18), // Match background
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        children: [
          // Text Field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E2746),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 15),
                  const Icon(
                    Icons.auto_awesome,
                    color: Colors.purpleAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: "Ask anything...",
                        hintStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                      ),
                      onSubmitted: _handleSubmitted,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.mic, color: Colors.grey),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Send Button
          GestureDetector(
            onTap: () => _handleSubmitted(_textController.text),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF448AFF), Color(0xFF8E24AA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper: Typing Dot Animation ---
  Widget _buildDot(int delay) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      child: TweenAnimationBuilder(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        builder: (context, value, child) {
          return Opacity(
            opacity: (value as double).clamp(0.2, 1.0),
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Colors.grey,
                shape: BoxShape.circle,
              ),
            ),
          );
        },
        onEnd: () {}, // Loop logic would go here in a real app
      ),
    );
  }
}
