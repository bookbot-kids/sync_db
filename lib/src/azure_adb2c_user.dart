// import 'package:basic_utils/basic_utils.dart';
// import 'package:robust_http/exceptions.dart';
// import 'package:robust_http/robust_http.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:sync_db/sync_db.dart';

// // set token(String token);
// // Future<void> forceRefresh();
// // Future<List<ServicePoint>> servicePoints();
// // Future<List<ServicePoint>> servicePointsForTable(String table);
// // Future<bool> hasSignedIn();
// // String get role;
// // Future<void> signout();

// class AzureADB2CUserSession extends UserSession {
//   /// Config will need:
//   /// `azureBaseUrl` for Azure authentication functions
//   /// `azureKey` the secure code to request azure function
//   AzureADB2CUserSession(Map<String, dynamic> config) {
//     _http = HTTP(config['azureBaseUrl']);
//     _azureKey = config['azureKey'];
//     // Start the process of getting tokens
//     _refreshed = refresh();
//   }

//   HTTP _http;
//   String _azureKey;
//   DateTime _tokenExpiry;
//   Future<void> _refreshed;

//   @override
//   set token(String token) {
//     SharedPreferences.getInstance().then((preference) {
//       preference.setString('refreshToken', token);
//       _refreshed = refresh();
//     });
//   }

//   /// Get resource tokens from Cosmos
//   /// If there is no refresh token, guest resource token is returned
//   @override
//   Future<void> refresh() async {
//     //Get shared preference and network time at same time
//     final preference = SharedPreferences.getInstance();
//     final futureTime = NetworkTime.shared.now;

//     final refreshToken = (await preference).getString('refreshToken');

//     // Put at end
//     _tokenExpiry = (await futureTime).add(Duration(hours: 4, minutes: 59));

//     // Refresh token is an authorisation token to get different permissions for resource tokens
//     // Azure functions also need a key
//     try {
//       final response = await _http.get('/GetResourceTokens', parameters: {
//         'refresh_token': refreshToken ?? '',
//         'code': _config['azureCode']
//       });

//       _resourceTokens.clear();
//       for (final permission in response['permissions']) {
//         var resourceToken = CosmosResourceToken(
//             permission['id'],
//             permission['_token'],
//             permission['resourcePartitionKey'].first,
//             permission['']);
//         _resourceTokens.add(resourceToken);
//       }

//       _tokenExpiry = expired;

//       // set role along with the resource tokens
//       if (response['group'] != null) {
//         role = response['group'];
//       }

//       // Update new refresh token from server
//       if (response['refreshToken'] is String &&
//           StringUtils.isNotNullOrEmpty(response['refreshToken'])) {
//         refreshToken = response['refreshToken'];
//       }
//     } catch (e, stackTrace) {
//       if (e is UnexpectedResponseException) {
//         try {
//           if (e.response.statusCode == 401) {
//             // token is expired, need to sign out user
//             _resourceTokens.clear();
//             await prefs.remove('refresh_token');
//           } else {
//             Sync.shared.logger?.e('get resource tokens error', e, stackTrace);
//           }
//         } catch (e) {
//           // ignore
//         }
//       } else {
//         Sync.shared.logger?.e('get resource tokens error', e, stackTrace);
//       }
//     }

//     return List<CosmosResourceToken>.from(_resourceTokens);
//   }

//   @override
//   Future<bool> hasSignedIn() async {
//     prefs ??= await SharedPreferences.getInstance();
//     return refreshToken != null && refreshToken.isNotEmpty;
//   }

//   @override
//   String get role => prefs.getString('role');

//   @override
//   Future<void> servicePoints() async {
//     await _refreshed;
//   }

//   Future<void> servicePointsForable(String table) async {
//     await _refreshed;
//   }

//   @override
//   set role(String role) {
//     prefs.setString('role', role);
//   }

//   /// Sign out user, remove the refresh token from shared preferences and clear all resource tokens and database
//   @override
//   Future<void> signout() async {
//     _resourceTokens?.clear();
//     _tokenExpiry = null;
//     await prefs.remove('refresh_token');
//     await Sync.shared.local.cleanDatabase();
//   }

//   String get _refreshToken => prefs.getString('refresh_token');

//   /// Fetch refresh token & resource tokens from id token
//   /// Return a list of resource tokens or guest resource tokens if id token is invalid
//   Future<List<CosmosResourceToken>> fetchTokens(String idToken) async {
//     try {
//       if (idToken != null && idToken.isNotEmpty) {
//         var response = await _http.get('/GetRefreshAndAccessToken',
//             parameters: {'code': _config['azureCode'], 'id_token': idToken});
//         if (response['success'] == true && response['token'] != null) {
//           var token = response['token'];
//           refreshToken = token['refresh_token'];
//         }
//       }

//       await reset();
//       return await resourceTokens();
//     } catch (error, stackTrace) {
//       Sync.shared.logger?.e('fetch token error', error, stackTrace);
//     }

//     return null;
//   }
// }
