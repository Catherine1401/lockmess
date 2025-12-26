import 'package:lockmess/features/login/domain/entities/user.dart';

abstract interface class LoginRepository {
  Future<User> signInWithGoogle();
}
