class UserModel {
  final String uid;
  final String email;
  final String username;
  final double? weight; // <--- NEW
  final double? height; // <--- NEW

  UserModel({
    required this.uid,
    required this.email,
    required this.username,
    this.weight,
    this.height,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'username': username,
      'weight': weight, // <--- NEW
      'height': height, // <--- NEW
      'createdAt': DateTime.now(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      username: map['username'] ?? '',
      // We parse as double/num to be safe
      weight: (map['weight'] as num?)?.toDouble(),
      height: (map['height'] as num?)?.toDouble(),
    );
  }
}
