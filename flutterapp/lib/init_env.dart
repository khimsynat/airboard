import 'package:flutter/material.dart';
import 'package:flutterapp/main.dart';
import 'package:flutterapp/remote_board.dart';

class InitEnv extends StatefulWidget {
  const InitEnv({super.key});

  @override
  State<InitEnv> createState() => _InitEnvState();
}

class _InitEnvState extends State<InitEnv> {
  final textController = TextEditingController(text: "localhost");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Init ENV"), centerTitle: true),
      body: InkWell(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        onTap: () {
          FocusScope.of(context).requestFocus(FocusNode());
        },
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                TextField(
                  controller: textController,
                  maxLength: 20,
                  decoration: InputDecoration(
                    labelText: 'Input host URL', // Optional label text
                    hintText: 'localhost or 192.168.x.x', // Optional hint text
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        8.0,
                      ), // Optional: rounded corners
                      borderSide: BorderSide(
                        color: Colors.blue, // Optional: border color
                        width: 2.0, // Optional: border thickness
                      ),
                    ),
                    // You can also customize specific border states:
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.green, width: 2.0),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey, width: 1.0),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red, width: 2.0),
                    ),
                  ),
                ),

                Container(
                  padding: EdgeInsets.only(top: 12),
                  width: MediaQuery.of(context).size.width,
                  height: 58,
                  child: ElevatedButton(
                    onPressed: () {
                      if (textController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Host URL cannot be empty"),
                            duration: Duration(seconds: 2),
                          ),
                        );
                        return;
                      }
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              RemoteBoard(hostName: textController.text),
                        ),
                      );
                    },
                    child: Text("Connect"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
