import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

bool isGoogleMapsReady() {
  try {
    final google = globalContext.getProperty('google'.toJS);
    if (google == null) return false;
    final maps = (google as JSObject).getProperty('maps'.toJS);
    if (maps == null) return false;
    final mapTypeId = (maps as JSObject).getProperty('MapTypeId'.toJS);
    return mapTypeId != null;
  } catch (_) {
    return false;
  }
}

Future<bool> waitForGoogleMapsReady({Duration timeout = const Duration(seconds: 15)}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    if (isGoogleMapsReady()) return true;
    await Future.delayed(const Duration(milliseconds: 100));
  }
  return false;
}
