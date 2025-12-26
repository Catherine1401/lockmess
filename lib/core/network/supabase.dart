import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Provider<Supabase>((ref) {
  return Supabase.instance;
});


final authProvider = StreamProvider<AuthState>((ref) {
  return ref.read(supabase).client.auth.onAuthStateChange;
});
