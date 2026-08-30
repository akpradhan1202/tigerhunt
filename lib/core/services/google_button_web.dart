import 'package:flutter/widgets.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:google_sign_in_web/google_sign_in_web.dart' as gsi;

/// Returns the official "Sign in with Google" button widget.
/// Uses Google Identity Services which works reliably on web.
Widget? buildGoogleSignInButton() {
  final plugin = GoogleSignInPlatform.instance;
  if (plugin is gsi.GoogleSignInPlugin) {
    return plugin.renderButton();
  }
  return null;
}
