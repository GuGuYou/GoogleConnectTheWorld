import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

/// Prevents pointer events from reaching underlying platform views such as
/// [GoogleMap] on web (HtmlElementView).
///
/// Wrap dialogs, bottom sheets, and other overlays shown above the map.
class MapPointerBlocker extends StatelessWidget {
  final Widget child;

  const MapPointerBlocker({super.key, required this.child});

  @override
  Widget build(BuildContext context) => PointerInterceptor(child: child);
}
