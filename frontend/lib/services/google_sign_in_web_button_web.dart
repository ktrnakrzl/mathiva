import 'package:flutter/material.dart';
import 'package:google_sign_in_web/web_only.dart' as web;

Widget googleSignInWebButton() {
  return web.renderButton(
    configuration: web.GSIButtonConfiguration(
      text: web.GSIButtonText.continueWith,
      size: web.GSIButtonSize.large,
      shape: web.GSIButtonShape.rectangular,
      theme: web.GSIButtonTheme.outline,
      minimumWidth: 320,
    ),
  );
}
