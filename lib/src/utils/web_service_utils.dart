import 'dart:convert';
import 'package:jaguar_jwt/jaguar_jwt.dart';

class WebServiceUtils {
  /// Client Token is used to secure the anonymous web services.
  /// The token is made up of:
  /// Subject: Stores the user ID of the user to which the token is issued.
  /// Issuer: Authority issuing the token, like the business name, e.g. Bookbot
  /// Audience: The audience that uses this authentication e.g. com.bookbot.bookbotapp
  /// The secret is the key used for encoding
  static String generateClientToken(String azureSecret, String? azureSubject,
      String? azureIssuer, String azureAudience, DateTime notBefore,
      {String? jwtId, Duration maxAge = const Duration(minutes: 10)}) {
    var encodedKey = base64.encode(utf8.encode(azureSecret));
    final claimSet = JwtClaim(
        subject: azureSubject,
        issuer: azureIssuer,
        audience: <String>[azureAudience],
        notBefore: notBefore,
        jwtId: jwtId,
        maxAge: maxAge);
    return issueJwtHS256(claimSet, encodedKey);
  }
}
