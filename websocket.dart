import 'package:flutter_visual_builder/widgets/blup_designer/utils/key_resolver.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'launch_chrome.dart';

class UserConnect {
  final String productionUrl = "your websocket prod url";
  final String devUrl = "your websocket dev url";
  late String url;
  IOWebSocketChannel? channel;
  Function()? onOpen;
  Function(dynamic msg)? onMessage;
  Function(int code, String reaso)? onClose;

  UserConnect({
    this.onOpen,
    this.onMessage,
    this.onClose,
  }) {
    // url = productionUrl;
    url = productionUrl;
  }

  void connect({required String projectId}) async {
    try {
      channel = IOWebSocketChannel.connect(
        productionUrl,
        headers: {"projectId": projectId},
        connectTimeout: const Duration(minutes: 10),
        // pingInterval: const Duration(milliseconds: 200),
      );

      onOpen?.call();
      channel?.stream.listen(onMessage, onDone: () {
        print("webhook is closed with project id >> $projectId");
        // ChromePup.instance.close();
        // connect();
        // onClose?.call(channel.closeCode, channel.closeReason);
      });
    } catch (ex) {
      print("Exception occurs in [connect](UserConnect) $url");
      // onClose?.call(500, ex.toString());
    }
  }

  void send(data) {
    channel?.sink.add(data);
    // print('data Send To Blup DB: $data');
  }

  void close() {
    try {
      channel!.sink.close();
    } catch (ex) {
      print("Exception occurs in [close](UserConnect) $url");
    }
  }
}
