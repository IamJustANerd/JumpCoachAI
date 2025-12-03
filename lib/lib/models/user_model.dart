class UserModel {
  final String uid;
  final String email;
  final String username;
  final double? weight;
  final double? height;

  // --- NEW FIELDS ---
  final double? bestJumpHeight;
  final List<double>? history;

  UserModel({
    required this.uid,
    required this.email,
    required this.username,
    this.weight,
    this.height,
    this.bestJumpHeight,
    this.history,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'username': username,
      'weight': weight,
      'height': height,
      'bestJumpHeight': bestJumpHeight, // <--- NEW
      'history': history, // <--- NEW
      'createdAt': DateTime.now(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      username: map['username'] ?? '',
      weight: (map['weight'] as num?)?.toDouble(),
      height: (map['height'] as num?)?.toDouble(),

      // --- NEW: Safe parsing ---
      bestJumpHeight: (map['bestJumpHeight'] as num?)?.toDouble(),
      // Check if history exists, if so map every item to double
      history: (map['history'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList(),
    );
  }
}
