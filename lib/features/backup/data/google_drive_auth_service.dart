import 'dart:io';

import 'package:google_sign_in/google_sign_in.dart';

class GoogleDriveAuthService {
  GoogleDriveAuthService._();

  static final GoogleDriveAuthService instance = GoogleDriveAuthService._();

  static const String driveAppDataScope =
      'https://www.googleapis.com/auth/drive.appdata';

  static const String _serverClientId =
      '417368509306-1e388pqrda73jfqavaqkvq4reglr0kcs.apps.googleusercontent.com';

  static const List<String> scopes = <String>[driveAppDataScope];

  final GoogleSignIn _signIn = GoogleSignIn.instance;

  Future<void>? _initialization;
  GoogleSignInAccount? _currentUser;

  Future<void> initialize() {
    return _initialization ??= _signIn.initialize(
      serverClientId: _serverClientId,
    );
  }

  Future<GoogleDriveSession?> connect() async {
    await initialize();

    var user = _currentUser;
    user ??= await _tryLightweightAuthentication();

    if (user == null) {
      if (!_signIn.supportsAuthenticate()) {
        throw const FileSystemException(
          'Die Google-Anmeldung wird auf diesem Gerät nicht unterstützt.',
        );
      }

      try {
        user = await _signIn.authenticate(scopeHint: scopes);
      } on GoogleSignInException catch (error) {
        if (error.code == GoogleSignInExceptionCode.canceled) {
          return null;
        }
        throw FileSystemException(_authenticationErrorMessage(error));
      }
    }

    _currentUser = user;

    try {
      final existingAuthorization = await user.authorizationClient
          .authorizationForScopes(scopes);
      if (existingAuthorization == null) {
        await user.authorizationClient.authorizeScopes(scopes);
      }
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        return null;
      }
      throw FileSystemException(_authenticationErrorMessage(error));
    }

    return GoogleDriveSession(user);
  }

  Future<GoogleDriveSession?> connectSilently() async {
    await initialize();

    var user = _currentUser;
    user ??= await _tryLightweightAuthentication();
    if (user == null) {
      return null;
    }

    try {
      final authorization = await user.authorizationClient
          .authorizationForScopes(scopes);
      if (authorization == null) {
        return null;
      }
    } on GoogleSignInException {
      return null;
    }

    _currentUser = user;
    return GoogleDriveSession(user, allowPrompt: false);
  }

  Future<GoogleSignInAccount?> _tryLightweightAuthentication() async {
    final lightweight = _signIn.attemptLightweightAuthentication();
    if (lightweight == null) {
      return null;
    }

    try {
      return await lightweight;
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.clientConfigurationError ||
          error.code == GoogleSignInExceptionCode.providerConfigurationError) {
        throw FileSystemException(_authenticationErrorMessage(error));
      }
      return null;
    }
  }

  static String _authenticationErrorMessage(GoogleSignInException error) {
    return switch (error.code) {
      GoogleSignInExceptionCode.clientConfigurationError =>
        'Google-Anmeldung ist nicht korrekt konfiguriert. '
            'Prüfe Paketname, SHA-1 und Web-Client-ID.',
      GoogleSignInExceptionCode.providerConfigurationError =>
        'Der Google-Anmeldedienst ist auf diesem Gerät nicht korrekt verfügbar.',
      GoogleSignInExceptionCode.uiUnavailable =>
        'Das Google-Anmeldefenster konnte nicht geöffnet werden.',
      GoogleSignInExceptionCode.interrupted =>
        'Die Google-Anmeldung wurde unterbrochen. Bitte erneut versuchen.',
      GoogleSignInExceptionCode.userMismatch =>
        'Das ausgewählte Google-Konto stimmt nicht mit der aktiven Sitzung überein.',
      GoogleSignInExceptionCode.canceled =>
        'Die Google-Anmeldung wurde abgebrochen.',
      _ =>
        error.description?.trim().isNotEmpty == true
            ? 'Google-Anmeldung: ${error.description}'
            : 'Die Google-Anmeldung ist fehlgeschlagen.',
    };
  }
}

class GoogleDriveSession {
  const GoogleDriveSession(this.user, {this.allowPrompt = true});

  final GoogleSignInAccount user;
  final bool allowPrompt;

  String get email => user.email;

  Future<Map<String, String>> authorizationHeaders() async {
    final headers = await user.authorizationClient.authorizationHeaders(
      GoogleDriveAuthService.scopes,
      promptIfNecessary: allowPrompt,
    );

    if (headers == null) {
      throw const FileSystemException(
        'Google Drive konnte keine gültige Zugriffsberechtigung erstellen.',
      );
    }

    return headers;
  }
}
