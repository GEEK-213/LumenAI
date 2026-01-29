class Profile {
  final String id;
  final String? fullName;
  final String? avatarUrl;
  final String? role;
  final List<String> interests;
  final Map<String, dynamic> stats;

  Profile({
    required this.id,
    this.fullName,
    this.avatarUrl,
    this.role,
    this.interests = const [],
    this.stats = const {},
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      role: json['role'] as String?,
      interests:
          (json['interests'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      stats: json['stats'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'role': role,
      'interests': interests,
      'stats': stats,
    };
  }
}
