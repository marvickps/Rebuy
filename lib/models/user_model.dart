class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String profileImageUrl;
  final DateTime createdAt;
  final List<String> favorites;
  final bool isOnline;
  final DateTime? lastSeen;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    this.profileImageUrl = '',
    required this.createdAt,
    this.favorites = const [],
    this.isOnline = false,
    this.lastSeen,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt.toIso8601String(),
      'favorites': favorites,
      'isOnline': isOnline,
      'lastSeen': lastSeen?.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      profileImageUrl: map['profileImageUrl'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
      favorites: List<String>.from(map['favorites'] ?? []),
      isOnline: map['isOnline'] ?? false,
      lastSeen: map['lastSeen'] != null ? DateTime.parse(map['lastSeen']) : null,
    );
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? profileImageUrl,
    List<String>? favorites,
    bool? isOnline,
    DateTime? lastSeen,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt,
      favorites: favorites ?? this.favorites,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }
}