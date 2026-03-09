import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../services/api_service.dart';

import 'package:shared_preferences/shared_preferences.dart';

// --- Data Model for Messages
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;
  final List<String> suggestions;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.time,
    this.suggestions = const [],
  });

  Map<String, dynamic> toJson() => {
    'text': text,
    'isUser': isUser,
    'time': time.toIso8601String(),
    'suggestions': suggestions,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    text: json['text'],
    isUser: json['isUser'],
    time: DateTime.parse(json['time']),
    suggestions: List<String>.from(json['suggestions'] ?? []),
  );
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  bool _isTyping = false;

  final ApiService _apiService = ApiService();
  String get _baseUrl => _apiService.baseUrl;

  List<Map<String, dynamic>> _subjects = [];
  List<Map<String, dynamic>> _units = [];
  String? _selectedSubjectId;
  String? _selectedUnitId;
  String _currentGreeting = '';

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    final user = Supabase.instance.client.auth.currentUser;
    final name =
        user?.userMetadata?['full_name']?.toString().split(' ').first ??
        user?.email?.split('@').first ??
        'there';

    _currentGreeting =
        "Hello, $name! I'm Lumen AI. How can I help you with your studies today?";

    // Fetch subjects from DB
    try {
      final data = await Supabase.instance.client
          .from('subjects')
          .select('id, name')
          .eq('user_id', user?.id ?? '')
          .order('created_at', ascending: false);

      final unitData = await Supabase.instance.client
          .from('units')
          .select('id, subject_id, name')
          .eq('user_id', user?.id ?? '')
          .order('created_at', ascending: true);

      if (mounted) {
        setState(() {
          _subjects = List<Map<String, dynamic>>.from(data);
          _units = List<Map<String, dynamic>>.from(unitData);
        });
      }
    } catch (e) {
      debugPrint('Failed to load subjects/units for chat: $e');
    }

    await _loadMessages('general');
  }

  Future<void> _loadMessages(String subjectId) async {
    final prefs = await SharedPreferences.getInstance();
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final key = 'chat_${user.id}_$subjectId';
    final saved = prefs.getString(key);

    if (saved != null) {
      final List<dynamic> decoded = jsonDecode(saved);
      setState(() {
        _messages = decoded.map((e) => ChatMessage.fromJson(e)).toList();
      });
    } else {
      // Setup initial greeting
      setState(() {
        _messages = [
          ChatMessage(
            text: _currentGreeting,
            isUser: false,
            time: DateTime.now(),
          ),
        ];
      });
    }
    _scrollToBottom();
  }

  Future<void> _saveMessages(String subjectId) async {
    final prefs = await SharedPreferences.getInstance();
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final key = 'chat_${user.id}_$subjectId';
    final encoded = jsonEncode(_messages.map((m) => m.toJson()).toList());
    await prefs.setString(key, encoded);
  }

  void _onSubjectChanged(String? newSubjectId) {
    if (newSubjectId == _selectedSubjectId) return;
    setState(() {
      _selectedSubjectId = newSubjectId;
      _selectedUnitId = null; // Reset unit filter when subject changes
    });
    // Load local history for new subject or "general"
    _loadMessages(newSubjectId ?? 'general');
  }

  Future<void> _clearMessages(String subjectId) async {
    final prefs = await SharedPreferences.getInstance();
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final key = 'chat_${user.id}_$subjectId';
    await prefs.remove(key);

    if (mounted) {
      setState(() {
        _messages = [
          ChatMessage(
            text: _currentGreeting,
            isUser: false,
            time: DateTime.now(),
          ),
        ];
      });
    }
  }

  void _showUnitPicker() {
    final subjectUnits = _units
        .where((u) => u['subject_id'].toString() == _selectedSubjectId)
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Filter by Unit",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text(
                  "All Units",
                  style: TextStyle(color: Colors.white70),
                ),
                trailing: _selectedUnitId == null
                    ? const Icon(Icons.check, color: Colors.purpleAccent)
                    : null,
                onTap: () {
                  setState(() => _selectedUnitId = null);
                  Navigator.pop(context);
                },
              ),
              ...subjectUnits.map((u) {
                final isSelected = _selectedUnitId == u['id'].toString();
                return ListTile(
                  title: Text(
                    u['name']?.toString() ?? 'Unnamed Unit',
                    style: const TextStyle(color: Colors.white),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: Colors.purpleAccent)
                      : null,
                  onTap: () {
                    setState(() => _selectedUnitId = u['id'].toString());
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  /// Build conversation history string from recent messages for multi-turn context.
  String _buildConversationHistory() {
    // Take last 10 messages (excluding the initial greeting)
    final recent = _messages.length > 1
        ? _messages.sublist(1).take(10).toList()
        : <ChatMessage>[];
    if (recent.isEmpty) return '';

    final buffer = StringBuffer();
    for (final msg in recent) {
      buffer.writeln(
        msg.isUser ? 'User: ${msg.text}' : 'Assistant: ${msg.text}',
      );
    }
    return buffer.toString();
  }

  Future<void> _handleSubmitted(String text) async {
    _textController.clear();
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(
        ChatMessage(text: text, isUser: true, time: DateTime.now()),
      );
      _saveMessages(_selectedSubjectId ?? 'general');
      _isTyping = true;
    });
    _scrollToBottom();

    try {
      // Build conversation history for multi-turn memory
      final history = _buildConversationHistory();

      final headers = await _apiService.authHeaders;
      headers['Content-Type'] = 'application/x-www-form-urlencoded';

      final body = {'question': text, 'context': history};

      if (_selectedSubjectId != null) {
        body['subject_id'] = _selectedSubjectId!;
      }
      if (_selectedUnitId != null) {
        body['unit_id'] = _selectedUnitId!;
      }

      final response = await http
          .post(Uri.parse('$_baseUrl/chat/ask'), headers: headers, body: body)
          .timeout(const Duration(seconds: 45));

      final data = jsonDecode(response.body);
      final answer = data['answer'] ?? 'Sorry, I could not get a response.';

      // Parse suggested follow-up questions
      final suggestions =
          (data['suggestions'] as List<dynamic>?)
              ?.map((s) => s.toString())
              .toList() ??
          [];

      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add(
            ChatMessage(
              text: answer,
              isUser: false,
              time: DateTime.now(),
              suggestions: suggestions,
            ),
          );
          _saveMessages(_selectedSubjectId ?? 'general');
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
          _saveMessages(_selectedSubjectId ?? 'general');
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
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
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
            if (_subjects.isEmpty)
              const Text(
                "Lumen AI",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              )
            else
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedSubjectId,
                  hint: const Text(
                    "General Chat",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  dropdownColor: Theme.of(context).cardColor,
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text("General Chat"),
                    ),
                    ..._subjects.map(
                      (sub) => DropdownMenuItem<String>(
                        value: sub['id'].toString(),
                        child: Text(
                          sub['name']?.toString() ?? 'Unnamed',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: _onSubjectChanged,
                ),
              ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: Theme.of(context).cardColor,
            onSelected: (value) async {
              if (value == 'clear') {
                await _clearMessages(_selectedSubjectId ?? 'general');
              } else if (value == 'unit') {
                _showUnitPicker();
              }
            },
            itemBuilder: (context) => [
              if (_selectedSubjectId != null)
                const PopupMenuItem(
                  value: 'unit',
                  child: Text(
                    'Filter by Unit',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              const PopupMenuItem(
                value: 'clear',
                child: Text(
                  'Clear Chat History',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ),
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

    return Column(
      crossAxisAlignment: isMe
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            decoration: BoxDecoration(
              gradient: isMe
                  ? const LinearGradient(
                      colors: [Color(0xFF448AFF), Color(0xFF8E24AA)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isMe ? null : const Color(0xFF1E2746),
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
                MarkdownBody(
                  data: message.text,
                  styleSheet: MarkdownStyleSheet(
                    p: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.4,
                    ),
                    strong: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    listBullet: const TextStyle(color: Colors.white),
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
        ),
        // Suggested follow-up questions
        if (!isMe && message.suggestions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 12),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: message.suggestions.map((s) {
                return ActionChip(
                  label: Text(
                    s,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  backgroundColor: const Color(0xFF2A3A5C),
                  side: BorderSide(color: Colors.blueAccent.withOpacity(0.3)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  onPressed: () => _handleSubmitted(s),
                );
              }).toList(),
            ),
          ),
      ],
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
            opacity: value.clamp(0.2, 1.0),
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
