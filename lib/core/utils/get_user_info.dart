base mixin GetUserInfo {
  String getNameFromMetadata(Map<String, dynamic>? metadata) {
    return switch (metadata) {
      {'name': String name} => name,
      {'full_name': String name} => name,
      _ => 'no name',
    };
  }

  String getAvatarFromMetadata(Map<String, dynamic>? metadata) {
    return switch (metadata) {
      {'avatar_url': String avatarUrl} => avatarUrl,
      _ =>
        'https://gravatar.com/avatar/a1e5c3b4679d3634cfdaa1d19e51f3b7?s=400&d=robohash&r=x',
    };
  }

  List<String> getHobbies(List<Map<String, dynamic>> hobbies) {
    try {
      if (hobbies.isEmpty) return [];
      final hobbyData = hobbies.first['hobbies'];
      if (hobbyData == null || hobbyData is! List || hobbyData.isEmpty) {
        return [];
      }
      return hobbyData
          .map<String>((e) {
            return switch (e) {
              {'name': String name} => name,
              _ => '',
            };
          })
          .where((s) => s.isNotEmpty)
          .toList();
    } catch (e) {
      print('Error parsing hobbies: $e');
      return [];
    }
  }

  ({
    String id,
    String displayName,
    String username,
    String phone,
    String gender,
    String email,
    String avatarUrl,
    String birthday,
  })
  parseUser(Map<String, dynamic> rawUser) {
    rawUser.forEach((key, value) {
      print(
        'Trường $key: giá trị = $value, kiểu dữ liệu = ${value.runtimeType}',
      );
    });

    // Handle nullable fields with proper defaults
    return (
      id: rawUser['id'] as String? ?? '',
      displayName: rawUser['display_name'] as String? ?? '',
      username: rawUser['username'] as String? ?? '',
      phone: rawUser['phone'] as String? ?? '',
      gender: rawUser['gender'] as String? ?? '',
      email: rawUser['email'] as String? ?? '',
      avatarUrl: rawUser['avatar_url'] as String? ?? '',
      birthday: (rawUser['birthday'] as String? ?? '1800-01-01') == '1800-01-01'
          ? ''
          : parseBirthday(rawUser['birthday'] as String),
    );
  }

  String parseBirthday(String birthday) {
    return birthday.split('-').reversed.join('/');
  }
}
