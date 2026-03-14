@JS()
library elkjs;

import 'package:js/js.dart';

@JS('ELK')
class ELK {
  external ELK();
  external dynamic layout(dynamic graph);
}

@JS('JSON.parse')
external dynamic jsonParse(String text);
