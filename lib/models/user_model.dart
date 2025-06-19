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
  final String upiId;
  final String address;
  final String city;
  final String state;
  final String pincode;
  final String bio;

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
    this.upiId = '',
    this.address = '',
    this.city = '',
    this.state = '',
    this.pincode = '',
    this.bio = '',
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
      'upiId': upiId,
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
      'bio': bio,
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
      upiId: map['upiId'] ?? '',
      address: map['address'] ?? '',
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      pincode: map['pincode'] ?? '',
      bio: map['bio'] ?? '',
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
    String? upiId,
    String? address,
    String? city,
    String? state,
    String? pincode,
    String? bio,
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
      upiId: upiId ?? this.upiId,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      bio: bio ?? this.bio,
    );
  }

  String get fullAddress {
    if (address.isEmpty && city.isEmpty && state.isEmpty) return '';

    List<String> addressParts = [];
    if (address.isNotEmpty) addressParts.add(address);
    if (city.isNotEmpty) addressParts.add(city);
    if (state.isNotEmpty) addressParts.add(state);
    if (pincode.isNotEmpty) addressParts.add(pincode);

    return addressParts.join(', ');
  }
}