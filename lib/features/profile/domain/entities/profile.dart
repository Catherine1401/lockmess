final class Profile {
  final String id;
  final String displayName;
  final String username;
  final String phone;
  final String gender;
  final String email;
  final String avatarUrl;
  final String birthday;
  final List<String> hobbies;

  Profile({
    required this.id,
    required this.displayName,
    required this.username,
    required this.phone,
    required this.gender,
    required this.email,
    required this.avatarUrl,
    required this.birthday,
    required this.hobbies,
  });
}
