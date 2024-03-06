import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';

@pragma('vm:entry-point')
void callback(String id, int status, int progress) {
  if (status == DownloadTaskStatus.complete.index) {
    final SendPort? send =
        IsolateNameServer.lookupPortByName('downloader_send_port');
    send?.send([id, status, progress]);
  }
}

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await FlutterDownloader.initialize(debug: true);
  await FlutterDownloader.registerCallback(callback);

  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  final ReceivePort _port = ReceivePort();

  @override
  void initState() {
    super.initState();

    IsolateNameServer.registerPortWithName(
        _port.sendPort, 'downloader_send_port');

    _port.listen((message) {
      String id = message[0];

      Future.delayed(const Duration(seconds: 1), () {
        FlutterDownloader.loadTasksWithRawQuery(
                query: "SELECT * FROM task WHERE task_id='$id'")
            .then((tasks) {
          if (tasks == null || tasks.isEmpty) return;

          final task = tasks.first;
          final taskId = task.taskId;
          final filename = task.filename;
          final path = task.savedDir;

          // TODO: check here the file path and filename of the task
          // these aren't the correct ones, when saveInPublicStorage is true
          // furthermore the file is renamed, when existing to 'filename.pdf (1)', filename.pdf (2), and so on
          // perhaps a renaming before the file extension would be better: 'filename (1).pdf' instead of 'filename.pdf (1)'
          debugPrint('Task: $taskId, status: $path, progress: $filename');

          FlutterDownloader.open(taskId: id)
              .then((value) => {debugPrint('Open file: $value')});
        });
      });
    });
  }

  @override
  void dispose() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
    super.dispose();
  }

  Future _tryDeleteExistingFile(String? path, String filename) async {
    try {
      File file = File('$path/$filename');
      if (await file.exists()) {
        await file.delete();
      }
    } catch (err, stack) {
      debugPrint("Cannot delete existing file");
    }
  }

  _downloadFile() async {
    debugPrint('Download file');
    const urlString =
        'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf';
    final path = (await getExternalStorageDirectory())!.path;

    // this one is needed for duplicate downloads into the externalStorageDirectory
    // await _tryDeleteExistingFile(path, 'dummy.pdf');

    final taskId = await FlutterDownloader.enqueue(
      url: urlString,
      savedDir:
          path, // here we could also use the 'await getDownloadsDirectory().path' instead
      headers: {},
      showNotification: true,
      openFileFromNotification: true,
      saveInPublicStorage: true,
    );
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
