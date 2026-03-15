import 'dart:js_interop';

@JS('ELK')
extension type ELK._(JSObject _) implements JSObject {
  external ELK();

  /// Returns a JSPromise that resolves to the positioned graph.
  external JSPromise layout(JSObject graph);
}

/// Helper to parse JSON strings into native JS Objects
@JS('JSON.parse')
external JSObject jsonParse(String json);
