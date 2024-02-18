import 'dart:async';
import 'dart:isolate';

import 'package:drift/isolate.dart';

import 'main.dart';

class IsolateManager {
  IsolateManager();

  late final DriftIsolate isolate;

  Future<DriftPostgresDatabase> init() async {
    isolate = await createIsolate();
    final connection = await isolate.connect(
      singleClientMode: true,
      isolateDebugLog: true,
    );

    return DriftPostgresDatabase.withConnection(connection);
  }

  Future<DriftIsolate> createIsolate() async {
    final receiveIsolate = ReceivePort();

    await Isolate.spawn<SendPort>(
      (message) async {
        final server = DriftIsolate.inCurrent(() => queryExecutor);

        // Now, inform the original isolate about the created server:
        message.send(server);
      },
      receiveIsolate.sendPort,
      errorsAreFatal: true,
    );

    final server = await receiveIsolate.first as DriftIsolate;
    receiveIsolate.close();

    return server;
  }

  Future<void> close() async {
    await isolate.shutdownAll();
  }
}
