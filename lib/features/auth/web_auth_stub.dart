import 'package:flutter/material.dart';

Widget renderButton({VoidCallback? onPressed}) {
  return const SizedBox.shrink();
}

String getDebugInfo() {
  return 'Not Web Platform';
}

Future<Map<String, String>?> signInWithApple({
  required String clientId,
  required String redirectUri,
}) async {
  return null;
}

Future<Map<String, String>?> signInWithGoogle({
  required String clientId,
}) async {
  return null;
}
