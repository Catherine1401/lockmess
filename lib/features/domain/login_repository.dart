import 'package:lockmess/features/domain/user.dart';

abstract class LoginRepository {
  Future<User> signInWithGoogle();
  Future<void> signOut();
}
