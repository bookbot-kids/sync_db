import 'dart:math';

import 'package:jaguar_jwt/jaguar_jwt.dart';
import 'dart:convert';

class TokenHelper {
  /// generate client token from jwt (expired in 5 minutes) to prevent spamming server
  static String getClientToken(
      String secret, String subject, String iss, String audience) {
    var encodedKey = base64.encode(utf8.encode(secret));
    final claimSet = new JwtClaim(
        subject: subject,
        issuer: iss,
        audience: <String>[audience],
        notBefore: new DateTime.now(),
        jwtId: new Random().nextInt(10000).toString(),
        maxAge: const Duration(minutes: 5));

    String token = issueJwtHS256(claimSet, encodedKey);
    return token;
  }
}
