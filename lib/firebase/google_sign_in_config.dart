/// OAuth 2.0 **Web client** ID used by [GoogleSignIn.serverClientId] on Android so
/// Firebase Auth receives a non-null `idToken`.
///
/// Get it from **Firebase Console → Authentication → Sign-in method → Google**
/// (field **Web client ID**), or re-download `android/app/google-services.json`
/// after enabling Google and copy the `client_id` from `oauth_client` where
/// `client_type` is `3`.
///
/// Leave empty only if you are not using Google Sign-In on Android.
const String kGoogleSignInWebClientId = '';
