class SavedAccount {
  final String id;
  final String email;
  final String fullName;
  final String username;
  final int grade;
  final String? avatarUrl;
  final String sessionJson;
  final DateTime savedAt;

  const SavedAccount({
    required this.id,
    required this.email,
    required this.fullName,
    required this.username,
    required this.grade,
    this.avatarUrl,
    required this.sessionJson,
    required this.savedAt,
  });

  SavedAccount copyWith({
    String? id,
    String? email,
    String? fullName,
    String? username,
    int? grade,
    String? avatarUrl,
    String? sessionJson,
    DateTime? savedAt,
  }) {
    return SavedAccount(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      grade: grade ?? this.grade,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      sessionJson: sessionJson ?? this.sessionJson,
      savedAt: savedAt ?? this.savedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'fullName': fullName,
    'username': username,
    'grade': grade,
    'avatarUrl': avatarUrl,
    'sessionJson': sessionJson,
    'savedAt': savedAt.toIso8601String(),
  };

  factory SavedAccount.fromJson(Map<String, dynamic> json) => SavedAccount(
    id: json['id'] as String,
    email: json['email'] as String? ?? '',
    fullName: json['fullName'] as String? ?? '',
    username: json['username'] as String? ?? '',
    grade: json['grade'] as int? ?? 0,
    avatarUrl: json['avatarUrl'] as String?,
    sessionJson: json['sessionJson'] as String? ?? '',
    savedAt: json['savedAt'] != null
        ? DateTime.parse(json['savedAt'] as String)
        : DateTime.now(),
  );
}
