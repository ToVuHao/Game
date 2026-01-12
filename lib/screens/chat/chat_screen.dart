import 'package:flutter/material.dart';
import 'package:signalr_netcore/signalr_client.dart';

class ChatScreen extends StatefulWidget {
  final String userName; // Tên người đang chat (Người dùng hiện tại)

  ChatScreen({required this.userName});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // Thay 5231 bằng port backend của bạn
  final String serverUrl = "http://10.0.2.2:5231/chatHub";
  late HubConnection _hubConnection;

  List<Map<String, String>> messages = [];
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool isConnected = false;

  @override
  void initState() {
    super.initState();
    _initSignalR();
  }

  Future<void> _initSignalR() async {
    _hubConnection = HubConnectionBuilder().withUrl(serverUrl).build();

    _hubConnection.on("ReceiveMessage", _handleNewMessage);

    try {
      await _hubConnection.start();
      setState(() {
        isConnected = true;
      });
      print("Đã kết nối SignalR thành công!");
    } catch (e) {
      print("Lỗi kết nối Chat: $e");
    }
  }

  void _handleNewMessage(List<Object?>? args) {
    if (args != null && args.length >= 2) {
      if (mounted) {
        setState(() {
          messages.add({
            "user": args[0].toString(),
            "message": args[1].toString(),
          });
        });
        // Cuộn xuống cuối
        Future.delayed(Duration(milliseconds: 100), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_msgController.text.trim().isEmpty) return;

    if (_hubConnection.state == HubConnectionState.Connected) {
      try {
        await _hubConnection.invoke("SendMessage", args: [widget.userName, _msgController.text]);
        _msgController.clear();
      } catch (e) {
        print("Lỗi gửi tin: $e");
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Mất kết nối Server!")));
    }
  }

  @override
  void dispose() {
    _hubConnection.stop();
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Phòng Chat: ${widget.userName}"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          // DANH SÁCH TIN NHẮN
          Expanded(
            child: messages.isEmpty
                ? Center(child: Text("Chưa có tin nhắn nào...", style: TextStyle(color: Colors.grey)))
                : ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(10),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];

                // --- LOGIC QUAN TRỌNG ĐÃ ĐƯỢC SỬA ---
                // Chuẩn hóa về chữ thường (toLowerCase) và xóa khoảng trắng thừa (trim) để so sánh chính xác
                String senderName = msg['user'].toString().trim().toLowerCase();
                String myName = widget.userName.trim().toLowerCase();

                final isMe = senderName == myName;
                // ------------------------------------

                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 5),
                    padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7), // Giới hạn chiều rộng tin nhắn
                    decoration: BoxDecoration(
                      color: isMe ? Colors.blue[100] : Colors.grey[300],
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(15),
                        topRight: Radius.circular(15),
                        bottomLeft: isMe ? Radius.circular(15) : Radius.circular(0),
                        bottomRight: isMe ? Radius.circular(0) : Radius.circular(15),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nếu không phải mình thì hiện tên người gửi
                        if (!isMe)
                          Text(
                            msg['user']!, // Hiển thị tên gốc (viết hoa đẹp)
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blue[800]),
                          ),
                        SizedBox(height: 4),
                        Text(
                          msg['message']!,
                          style: TextStyle(fontSize: 16, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Ô NHẬP TIN NHẮN
          Container(
            padding: EdgeInsets.all(10),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    decoration: InputDecoration(
                        hintText: isConnected ? "Nhập tin nhắn..." : "Đang kết nối...",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                        contentPadding: EdgeInsets.symmetric(horizontal: 20),
                        filled: true,
                        fillColor: Colors.grey[100]
                    ),
                    onSubmitted: (_) => _sendMessage(),
                    enabled: isConnected,
                  ),
                ),
                SizedBox(width: 10),
                FloatingActionButton(
                  onPressed: isConnected ? _sendMessage : null,
                  child: Icon(Icons.send, color: Colors.white),
                  backgroundColor: isConnected ? Colors.blueAccent : Colors.grey,
                  mini: true,
                  elevation: 0,
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}