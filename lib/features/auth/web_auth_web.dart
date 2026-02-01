import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/material.dart';
import 'package:google_sign_in_web/web_only.dart' as gsi_web;
import 'package:http/http.dart' as http;
import 'package:web/web.dart' as web_dom;

Widget renderButton() {
  return gsi_web.renderButton(
    configuration: gsi_web.GSIButtonConfiguration(
      type: gsi_web.GSIButtonType.standard,
      size: gsi_web.GSIButtonSize.large,
      theme: gsi_web.GSIButtonTheme.outline,
      shape: gsi_web.GSIButtonShape.pill,
      minimumWidth: 240, 
    ),
  );
}

String getDebugInfo() {
  return '';
}

// Apple Sign In implementation
Future<Map<String, String>?> signInWithApple({
  required String clientId,
  required String redirectUri,
}) async {
  try {
     // Ensure script is loaded
     if (!globalContext.hasProperty('AppleID'.toJS).toDart) {
        final script = web_dom.HTMLScriptElement()
          ..src = 'https://appleid.cdn-apple.com/appleauth/static/jsapi/appleid/1/en_US/appleid.auth.js'
          ..type = 'text/javascript'
          ..async = true;
        web_dom.document.head!.append(script);
        
        // Wait for it
        for (int i=0; i<20; i++) {
           await Future.delayed(const Duration(milliseconds: 200));
           if (globalContext.hasProperty('AppleID'.toJS).toDart) break;
        }
     }

     if (!globalContext.hasProperty('AppleID'.toJS).toDart) {
        print('Apple Script failed to load');
        return null;
     }

     // Access AppleID correctly
     final appleID = globalContext.getProperty('AppleID'.toJS)! as JSObject;
     
     // Access auth object
     final auth = appleID.getProperty('auth'.toJS)! as JSObject;

     // Init options
     final options = JSObject();
     options.setProperty('clientId'.toJS, clientId.toJS);
     options.setProperty('scope'.toJS, 'name email'.toJS);
     options.setProperty('redirectURI'.toJS, redirectUri.toJS);
     options.setProperty('usePopup'.toJS, true.toJS);

     // Init
     auth.callMethod('init'.toJS, options);

     // SignIn
     final promise = auth.callMethod('signIn'.toJS)! as JSPromise;
     final result = await promise.toDart;
     
     final data = result! as JSObject;
     
     String? email;
     String? name;

     if (data.hasProperty('user'.toJS).toDart) {
        final user = data.getProperty('user'.toJS) as JSObject?;
        if (user != null) {
           if (user.hasProperty('email'.toJS).toDart) {
             email = (user.getProperty('email'.toJS)! as JSString).toDart;
           }
           if (user.hasProperty('name'.toJS).toDart) {
              final nameObj = user.getProperty('name'.toJS)! as JSObject;
              String first = '';
              String last = '';
              if (nameObj.hasProperty('firstName'.toJS).toDart) {
                  first = (nameObj.getProperty('firstName'.toJS)! as JSString).toDart;
              }
              if (nameObj.hasProperty('lastName'.toJS).toDart) {
                  last = (nameObj.getProperty('lastName'.toJS)! as JSString).toDart;
              }
              name = '$first $last'.trim();
           }
        }
     } else if (data.hasProperty('authorization'.toJS).toDart) {
        name = 'Apple User'; 
     }

     return {
       'email': ?email,
       if (name != null && name.isNotEmpty) 'name': name,
     };

  } catch (e) {
    print('Apple Sign In Error: $e');
    return null;
  }
}

// Google Sign In implementation (Manual Token Flow)
Future<Map<String, String>?> signInWithGoogle({
  required String clientId,
}) async {
  try {
     // Ensure Google Script is loaded
     if (!globalContext.hasProperty('google'.toJS).toDart) {
         final script = web_dom.HTMLScriptElement()
          ..src = 'https://accounts.google.com/gsi/client'
          ..type = 'text/javascript'
          ..async = true;
        web_dom.document.head!.append(script);
        
        for (int i=0; i<20; i++) {
           await Future.delayed(const Duration(milliseconds: 200));
           if (globalContext.hasProperty('google'.toJS).toDart) break;
        }
     }
     
     if (!globalContext.hasProperty('google'.toJS).toDart) {
       print('Google Script failed to load');
       return null;
     }

     final google = globalContext.getProperty('google'.toJS)! as JSObject;
     if (!google.hasProperty('accounts'.toJS).toDart) return null;
     
     final accounts = google.getProperty('accounts'.toJS)! as JSObject;
     final oauth2 = accounts.getProperty('oauth2'.toJS)! as JSObject;

     // We need to wait for the user to complete the popup, so we use a Completer
     final completer = Completer<Map<String, String>?>();

     // Define callback function logic
     final callback = (JSObject response) {
        if (response.hasProperty('access_token'.toJS).toDart) {
           final token = (response.getProperty('access_token'.toJS)! as JSString).toDart;
           // Fetch user info
           _fetchGoogleUserInfo(token).then(completer.complete).catchError((e) {
              print('UserInfo fetch error: $e');
              completer.complete(null);
           });
        } else {
           completer.complete(null);
        }
     }.toJS;

     // initTokenClient
     final config = JSObject();
     config.setProperty('client_id'.toJS, clientId.toJS);
     config.setProperty('scope'.toJS, 'https://www.googleapis.com/auth/userinfo.profile https://www.googleapis.com/auth/userinfo.email'.toJS);
     config.setProperty('callback'.toJS, callback);

     final tokenClient = oauth2.callMethod('initTokenClient'.toJS, config)! as JSObject;
     
     // requestAccessToken
     tokenClient.callMethod('requestAccessToken'.toJS);

     return completer.future;
  } catch (e) {
    print('Google Sign In Error: $e');
    return null;
  }
}

Future<Map<String, String>?> _fetchGoogleUserInfo(String accessToken) async {
  try {
    final response = await http.get(
      Uri.parse('https://www.googleapis.com/oauth2/v3/userinfo'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    
    if (response.statusCode == 200) {
       final data = jsonDecode(response.body);
       return {
         'name': (data['name'] as String?) ?? '',
         'email': (data['email'] as String?) ?? '',
         'picture': (data['picture'] as String?) ?? '', 
       };
    }
  } catch (e) {
    print('Http Error: $e');
  }
  return null;
}
