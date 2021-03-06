import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rxdart/rxdart.dart';

class DownloadManger {
  static DownloadManger _instance = DownloadManger._internal();
  DownloadManger._internal();
  factory DownloadManger.instance() => _instance;

  // Download task.
  Map<String, TaskInfo> _downloadTasks = {};

  StreamController<List<TaskInfo>> _tasksStreamController =
      BehaviorSubject<List<TaskInfo>>();

  Stream<List<TaskInfo>> get tasksStream => _tasksStreamController.stream;
  ReceivePort _port = ReceivePort();
  static String _sendPort = "SEND_PORT";
  static String _downloadDiectory;

  /// Initialize service.
  Future<void> init() async {
    await Permission.storage.request();
    if (await Permission.storage.isGranted) {
      // _downloadDiectory = await FilePicker.platform.getDirectoryPath();
      var storagDir = await getExternalStorageDirectory();
      _downloadDiectory = storagDir.path;
      IsolateNameServer.registerPortWithName(_port.sendPort, _sendPort);
      _port.listen((dynamic data) {
        TaskInfo downloadTaskProgress = TaskInfo.fromList(data);
        if (_downloadTasks.containsKey(downloadTaskProgress.id)) {
          _downloadTasks[downloadTaskProgress.id].update(
              downloadTaskProgress.status, downloadTaskProgress.progress);
        } else {
          _downloadTasks[downloadTaskProgress.id] = downloadTaskProgress;
        }
        _tasksStreamController.sink.add(_downloadTasks.values.toList());
      });
      await FlutterDownloader.initialize(
        debug: true,
      );
      FlutterDownloader.registerCallback(_downloadCallback);
      await loadFiles();
    } else {
      print("Storage permissions are not granted!");
    }
  }

  /// Load previous tasks.
  Future<void> loadFiles() async {
    List<DownloadTask> tasks = await FlutterDownloader.loadTasks();
    for (var task in tasks) {
      _downloadTasks[task.taskId] = TaskInfo(
        id: task.taskId,
        progress: task.progress,
        status: task.status,
      );
      _downloadTasks[task.taskId]?.task = task;
    }
    List<TaskInfo> tasksInfo = _downloadTasks.values.toList();
    _tasksStreamController.sink.add(tasksInfo);
  }

  /// Download a file using the given [url] with the given [key].
  Future<void> download({String url, String key}) async {
    if (key == null) {
      await _newTask(url);
    } else {
      if (_downloadTasks.containsKey(key)) {
        await _existingTask(_downloadTasks[key]);
      }
    }
  }

  /// High-level method to connect Main isolate with worker isolate that
  /// downloads files.
  /// Helps to
  static void _downloadCallback(
      String id, DownloadTaskStatus status, int progress) {
    final SendPort send = IsolateNameServer.lookupPortByName(_sendPort);
    send.send([id, status, progress]);
  }

  /// Handle task due to its current status.
  Future<void> _existingTask(TaskInfo task) async {
    switch (task.status.value) {
      // running
      case 2:
        {
          FlutterDownloader.pause(taskId: task.id);
          break;
        }
      // Completed
      case 3:
        {
          FlutterDownloader.open(taskId: task.id);
          break;
        }
      // Paused
      case 6:
        {
          FlutterDownloader.resume(taskId: task.id);
          break;
        }
      // Retry tasks by default.
      default:
        {
          retrytask(task.id);
        }
    }
  }

  /// Create a new task.
  Future<void> _newTask(String url) async {
    if (_downloadDiectory != null && _downloadDiectory != "") {
      String fileName = await _extractFileName(url);
      String id = await FlutterDownloader.enqueue(
          headers: {"auth": "test_for_sql_encoding"},
          url: url,
          fileName: fileName,
          savedDir: _downloadDiectory,
          openFileFromNotification: true);
      if (id != "" && id != null) {
        DownloadTask task = await getTask(id);
        if (task != null) {
          if (_downloadTasks.containsKey(task.taskId)) {
            _downloadTasks[id].update(task.status, task.progress);
          } else {
            _downloadTasks[id] = TaskInfo(
                id: task.taskId, status: task.status, progress: task.progress);
          }
          _downloadTasks[id]?.task = task;
          _tasksStreamController.sink.add(_downloadTasks.values.toList());
        }
      }
    }
  }

  /// Get the task with [id]
  Future<DownloadTask> getTask(String id) async {
    assert(id != null);
    var tasks = await FlutterDownloader.loadTasksWithRawQuery(
        query: "SELECT * FROM task WHERE task_id='$id'");
    if (tasks != null && tasks.isNotEmpty) {
      return tasks[0];
    }
    return null;
  }

  static Future<String> _extractFileName(String url) async {
    int start = url.lastIndexOf('/') + 1;
    int end = url.length;
    return url.substring(start, end);
  }

  /// Closes streams.
  void dispose() {
    _tasksStreamController.close();
    IsolateNameServer.removePortNameMapping(_sendPort);
  }

  /// This method retry a faild task.
  ///
  /// It deletes the faild task and creates a new one for the same file.
  ///
  /// **Paremeters**:
  /// * [id] : The `id` of the faild task.
  void retrytask(String id) async {
    String newTaskId = await FlutterDownloader.retry(taskId: id);
    DownloadTask newTask = await getTask(newTaskId);
    _downloadTasks.remove(id);
    _downloadTasks[newTaskId] = TaskInfo(
        id: newTaskId,
        progress: newTask.progress,
        status: newTask.status,
        task: newTask);
    _tasksStreamController.sink.add(_downloadTasks.values.toList());
  }
}

/// Basic info needed for the UI to be shred over isolates.
class TaskInfo with ChangeNotifier {
  int progress;
  DownloadTaskStatus status;
  String id;
  DownloadTask task;

  void update(DownloadTaskStatus status, int progress) {
    this.status = status;
    this.progress = progress;
    notifyListeners();
  }

  TaskInfo.fromList(List<dynamic> data)
      : id = data[0],
        status = data[1],
        progress = data[2];

  TaskInfo({this.id, this.progress, this.status, this.task});
}
