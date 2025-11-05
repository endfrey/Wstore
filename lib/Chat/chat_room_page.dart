import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/chat_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ChatRoomPage extends StatefulWidget {
  final String chatId;
  final String currentUserId;

  const ChatRoomPage({
    Key? key,
    required this.chatId,
    required this.currentUserId,
  }) : super(key: key);

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final TextEditingController _controller = TextEditingController();
  final ChatService _chatService = ChatService();

  File? _selectedImage;
  bool _sending = false;

  String chatTitle = "ห้องแชท";
  String? chatImage;

  @override
  void initState() {
    super.initState();
    _loadChatHeader();
    _resetUnread();
  }

  Future<void> _resetUnread() async {
    await _chatService.markAsRead(
      widget.chatId,
      forAdmin: widget.currentUserId == "admin",
    );
  }

  Future<void> _loadChatHeader() async {
    final chatDoc = await FirebaseFirestore.instance
        .collection("chats")
        .doc(widget.chatId)
        .get();

    if (!mounted) return;

    if (chatDoc.exists) {
      if (widget.currentUserId == "admin") {
        setState(() {
          chatTitle = chatDoc["userName"] ?? "ลูกค้า";
          chatImage = chatDoc["userImage"];
        });
      } else {
        setState(() {
          chatTitle = chatDoc["storeName"] ?? "ร้านค้า";
          chatImage = chatDoc["storeImage"];
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty && _selectedImage == null) return;

    setState(() => _sending = true);

    String? imageUrl;
    if (_selectedImage != null) {
      imageUrl = await _chatService.uploadImage(_selectedImage!, widget.chatId);
    }

    await _chatService.sendMessage(
      chatId: widget.chatId,
      senderId: widget.currentUserId,
      text: _controller.text.trim().isEmpty ? null : _controller.text.trim(),
      imageUrl: imageUrl,
    );

    setState(() {
      _controller.clear();
      _selectedImage = null;
      _sending = false;
    });
  }

  // ✅ Bubble ดีไซน์ใหม่
  Widget _buildBubble(Map<String, dynamic> msg, bool isMe) {
    bool hasImage = msg["imageUrl"] != null && msg["imageUrl"] != "";
    String text = msg["text"] ?? "";

    Timestamp? ts = msg["timestamp"];
    String timeStr = ts != null
        ? TimeOfDay.fromDateTime(ts.toDate()).format(context)
        : "";

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 260),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: isMe
                ? const LinearGradient(
                    colors: [Color(0xFF38BDF8), Color(0xFF0EA5E9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : const LinearGradient(
                    colors: [Colors.white, Color(0xFFEFF6FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: isMe ? const Radius.circular(18) : const Radius.circular(4),
              bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(18),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 6,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (hasImage)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(msg["imageUrl"], width: 180),
                  ),

                if (text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      text,
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.black87,
                        fontSize: 15,
                        height: 1.3,
                      ),
                    ),
                  ),

                if (timeStr.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 11,
                        color: isMe ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessages() {
    return StreamBuilder<QuerySnapshot>(
      stream: _chatService.getMessages(widget.chatId),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final msgs = snap.data!.docs;

        if (msgs.isEmpty) {
          return const Center(
            child: Text("เริ่มพูดคุยกับร้านได้เลย 😊",
                style: TextStyle(fontSize: 16, color: Colors.black54)),
          );
        }

        return ListView.builder(
          reverse: true,
          padding: const EdgeInsets.only(top: 10, bottom: 10),
          itemCount: msgs.length,
          physics: const BouncingScrollPhysics(),
          itemBuilder: (context, i) {
            final msg = msgs[i].data() as Map<String, dynamic>;
            bool isMe = msg["senderId"] == widget.currentUserId;
            return _buildBubble(msg, isMe);
          },
        );
      },
    );
  }

  Widget _buildImagePreview() {
    if (_selectedImage == null) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.file(_selectedImage!, height: 120),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: CircleAvatar(
              radius: 14,
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.close, size: 16, color: Colors.red),
                onPressed: () => setState(() => _selectedImage = null),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Input bar ใหม่แบบ modern (ลอย)
  Widget _buildInputBox() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF7F8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.photo, color: Color(0xFF0EA5E9)),
                onPressed: () async {
                  final picked = await ImagePicker().pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 70,
                  );
                  if (picked != null) {
                    setState(() => _selectedImage = File(picked.path));
                  }
                },
              ),

              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: "พิมพ์ข้อความ...",
                    border: InputBorder.none,
                  ),
                ),
              ),

              _sending
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : GestureDetector(
                      onTap: _sendMessage,
                      child: const CircleAvatar(
                        radius: 20,
                        backgroundColor: Color(0xFF0EA5E9),
                        child: Icon(Icons.send, color: Colors.white),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF7F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0EA5E9),
        elevation: 3,
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 19,
                backgroundColor: Colors.white,
                backgroundImage:
                    chatImage != null ? NetworkImage(chatImage!) : null,
                child: chatImage == null
                    ? Icon(
                        widget.currentUserId == "admin"
                            ? Icons.person
                            : Icons.store,
                        color: Colors.teal,
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              chatTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessages()),
          _buildImagePreview(),
          _buildInputBox(),
        ],
      ),
    );
  }
}
