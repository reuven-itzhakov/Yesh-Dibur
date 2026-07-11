import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

final socketServiceProvider = Provider<SocketService>((ref) {
  return SocketService();
});

class SocketService {
  io.Socket? _socket;
  bool get isConnected => _socket?.connected ?? false;

  // אתחול החיבור
  Future<void> connect() async {
    if (_socket != null && _socket!.connected) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final token = await user.getIdToken();
    
    // שליפת כתובת השרת מה-.env והסרת הנתיב /api/v1 אם קיים, כי הסוקט יושב בשורש השרת
    String rawUrl = dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:3000';
    final baseUrl = rawUrl.replaceAll('/api/v1', '');

    _socket = io.io(baseUrl, io.OptionBuilder()
      .setTransports(['websocket']) // כפיית WebSockets לביצועים אופטימליים
      .disableAutoConnect()
      .setAuth({'token': token}) // הזרקת הטוקן לאימות מול ה-socketManager.js בשרת
      .build()
    );

    _socket!.connect();

    _socket!.onConnect((_) {
      print('Socket.io Connected successfully!');
    });

    _socket!.onDisconnect((_) {
      print('Socket.io Disconnected');
    });

    _socket!.onConnectError((err) {
      print('Socket.io Connection Error: $err');
    });
  }

  // הצטרפות לחדר שיחה ספציפי (לפי הלוגיקה בקובץ chatSocket.js שלך)
  void joinChat(String chatId) {
    _socket?.emit('joinChat', chatId);
  }

  // עזיבת חדר שיחה
  void leaveChat(String chatId) {
    _socket?.emit('leaveChat', chatId);
  }

  // שליחת הודעה דרך הסוקט עם Callback שממתין לאישור השרת (ACK)
  Future<Map<String, dynamic>> sendMessage(Map<String, dynamic> data) {
    final completer = Completer<Map<String, dynamic>>();
    
    _socket?.emitWithAck('sendMessage', data, ack: (response) {
      completer.complete(response as Map<String, dynamic>);
    });
    
    return completer.future;
  }

  // האזנה לאירועים חיצוניים (כמו 'newMessage' או 'userTyping')
  void on(String event, Function(dynamic) callback) {
    _socket?.on(event, callback);
  }

  void off(String event) {
    _socket?.off(event);
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}