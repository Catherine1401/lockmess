import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lockmess/features/domain/login_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lockmess/features/domain/user.dart' as User;

final supabase = Provider<Supabase>((ref) {
  return Supabase.instance;
});

final loginRepositoryProvider = Provider<LoginRepositoryImp>((ref) {
  return LoginRepositoryImp(ref.read(supabase));
});

class LoginRepositoryImp implements LoginRepository {
  final Supabase _supabase;

  LoginRepositoryImp(this._supabase);

  @override
  Future<User.User> signInWithGoogle() async {
    const webClientId = String.fromEnvironment('WEB_CLIENT_ID');
    const iosClientId = String.fromEnvironment('IOS_CLIENT_ID');
    print(webClientId);
    print(iosClientId);

    final scopes = ['email', 'profile'];
    final googleSignIn = GoogleSignIn.instance;

    await googleSignIn.initialize(
      clientId: iosClientId,
      serverClientId: webClientId,
    );

    final googleAccout = await googleSignIn.authenticate();
    final googleAuthorization = await googleAccout.authorizationClient
        .authorizationForScopes(scopes);
    final googleAuthentication = googleAccout.authentication;
    final idToken = googleAuthentication.idToken;
    final accessToken = googleAuthorization!.accessToken;

    if (idToken == null) {
      print('no id token found!');
      throw 'no id token found!';
    }

    final authResponse = await _supabase.client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );

    final user = authResponse.user;

    if (user == null) {
      print('user null');
      throw 'user null';
    }

    return User.User(email: user.email!);
  }

  @override
  Future<void> signOut() {
    // TODO: implement signOut
    throw UnimplementedError();
  }
}
