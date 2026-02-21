import 'package:flutter/widgets.dart';

/// True when running under flutter widget/integration tests.
bool get isRunningWidgetTest {
  final bindingType = WidgetsBinding.instance.runtimeType.toString();
  return bindingType.contains('TestWidgetsFlutterBinding');
}

