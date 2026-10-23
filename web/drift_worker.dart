import 'package:drift/wasm.dart';

/// Compiled to web/drift_worker.js for the optional web preview.
void main() => WasmDatabase.workerMainForOpen();
