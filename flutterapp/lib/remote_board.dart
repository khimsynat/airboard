import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class RemoteBoard extends StatefulWidget {
  const RemoteBoard({super.key, required this.hostName});
  final String hostName;

  @override
  State<RemoteBoard> createState() => _RemoteBoardState();
}

class _RemoteBoardState extends State<RemoteBoard> {
  // ---------------- WebSocket URLs ----------------
  String screenUrl = "ws://localhost:9001"; // mac IP
  String inputUrl = "ws://localhost:9002";

  WebSocketChannel? screenChannel;
  WebSocketChannel? inputChannel;
  late StreamController<Uint8List> _videoStream;

  Uint8List? latestImage;
  Size macScreen = Size.zero;
  Size renderedSize = Size.zero;
  bool drawing = false;

  bool _isConnecting = false;
  bool _connectionFailed = false;
  int _retryDelaySeconds = 2;

  @override
  void initState() {
    super.initState();

    screenUrl = "ws://${widget.hostName}:9001";
    inputUrl = "ws://${widget.hostName}:9002";
    _videoStream = StreamController<Uint8List>.broadcast();
    _connect();
  }

  void _connect() async {
    if (_isConnecting) return;
    _isConnecting = true;
    _connectionFailed = false;
    setState(() {});

    try {
      // Close any previous sockets before reconnecting
      await screenChannel?.sink.close();
      await inputChannel?.sink.close();

      debugPrint("🔌 Connecting to sockets...");
      screenChannel = WebSocketChannel.connect(Uri.parse(screenUrl));
      inputChannel = WebSocketChannel.connect(Uri.parse(inputUrl));

      // --- SCREEN STREAM ---
      screenChannel!.stream.listen(
        (event) {
          if (event is String && event.startsWith("{")) {
            final data = jsonDecode(event);
            if (data["type"] == "config") {
              macScreen = Size(
                (data["width"] as num).toDouble(),
                (data["height"] as num).toDouble(),
              );
              setState(() {});
            }
          } else if (event is List) {
            _videoStream.add(Uint8List.fromList(event.cast<int>()));
          }
        },
        onError: (error) {
          debugPrint("Screen socket error: $error");
          _scheduleReconnect();
        },
        onDone: () {
          debugPrint("Screen socket closed.");
          _scheduleReconnect();
        },
        cancelOnError: true,
      );

      // --- INPUT STREAM ---
      inputChannel!.stream.listen(
        (_) {},
        onError: (error) {
          debugPrint("Input socket error: $error");
          _scheduleReconnect();
        },
        onDone: () {
          debugPrint("Input socket closed.");
          _scheduleReconnect();
        },
        cancelOnError: true,
      );

      debugPrint("✅ Connected to both sockets");
      _isConnecting = false;
      _connectionFailed = false;
      _retryDelaySeconds = 2;
      setState(() {});
    } catch (e) {
      debugPrint("❌ Initial connection failed: $e");
      _isConnecting = false;
      _connectionFailed = true;
      setState(() {});
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() async {
    if (!_isConnecting) {
      _isConnecting = true;
      _connectionFailed = true;
      setState(() {});
      debugPrint("🔁 Reconnecting in $_retryDelaySeconds seconds...");

      await Future.delayed(Duration(seconds: _retryDelaySeconds));

      // Exponential backoff up to 10 seconds
      _retryDelaySeconds = min(_retryDelaySeconds * 2, 10);
      _isConnecting = false;
      setState(() {});

      if (mounted) {
        debugPrint("⏳ Attempting reconnection...");
        _connect();
      }
    }
  }

  void _handleDisconnect() {
    if (!_isConnecting) {
      _isConnecting = true;
      _connectionFailed = true;
      setState(() {});
      _retryConnection();
    }
  }

  void _retryConnection() async {
    await Future.delayed(Duration(seconds: _retryDelaySeconds));
    _retryDelaySeconds = min(_retryDelaySeconds * 2, 10);
    _connect();
  }

  void _sendEvent(String type, Offset pos, BoxConstraints constraints) {
    if (macScreen == Size.zero) return;

    final scaleX = renderedSize.width / macScreen.width;
    final scaleY = renderedSize.height / macScreen.height;

    final offsetX = (constraints.maxWidth - renderedSize.width) / 2;
    final offsetY = (constraints.maxHeight - renderedSize.height) / 2;

    double adjX = (pos.dx - offsetX).clamp(0.0, renderedSize.width);
    double adjY = (pos.dy - offsetY).clamp(0.0, renderedSize.height);

    final macX = (adjX / scaleX).round() + 25;
    final macY = (adjY / scaleY).round();

    inputChannel?.sink.add("$type:$macX,$macY");
  }

  @override
  void dispose() {
    screenChannel?.sink.close();
    inputChannel?.sink.close();
    _videoStream.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          // scale Mac screen to fit tablet
          final scale = min(
            constraints.maxWidth / macScreen.width,
            constraints.maxHeight / macScreen.height,
          );
          renderedSize = Size(
            macScreen.width * scale,
            macScreen.height * scale,
          );

          return Stack(
            children: [
              StreamBuilder<Uint8List>(
                stream: _videoStream.stream,
                builder: (context, snapshot) {
                  final imageWidget = snapshot.hasData
                      ? Image.memory(
                          snapshot.data!,
                          width: renderedSize.width,
                          height: renderedSize.height,
                          gaplessPlayback: true,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        )
                      : Container(color: Colors.black);

                  return Center(
                    child: GestureDetector(
                      onPanStart: (details) {
                        drawing = true;
                        _sendEvent("down", details.localPosition, constraints);
                      },
                      onPanUpdate: (details) {
                        if (!drawing) return;
                        _sendEvent("move", details.localPosition, constraints);
                      },
                      onPanEnd: (details) {
                        if (!drawing) return;
                        drawing = false;
                        inputChannel?.sink.add(
                          "up:0,0",
                        ); // release at current position
                      },
                      onTapDown: (details) {
                        _sendEvent("click", details.localPosition, constraints);
                      },
                      child: imageWidget,
                    ),
                  );
                },
              ),
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Center(child: _buildStatusIndicator()),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusIndicator() {
    String text = '';
    if (_isConnecting && !_connectionFailed) {
      text = 'Connecting...';
    } else if (_isConnecting && _connectionFailed) {
      text = 'Reconnecting...';
    } else if (!_isConnecting && _connectionFailed) {
      text = 'Connection failed. Retrying...';
    } else {
      return SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
    );
  }
}
