import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  _downloadFile() {
    debugPrint('Download file');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: true,
        color: Colors.blue,
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Download File Example'),
            centerTitle: true,
            backgroundColor: Colors.blue,
          ),
          body: Column(
            children: <Widget>[
              const SizedBox(height: 20),
              Center(
                child: MaterialButton(
                  color: Colors.orange,
                  onPressed: _downloadFile,
                  child: const Text('Download File'),
                ),
              ),
            ],
          ),
        ));
  }
}
