class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String? fcmToken;
  final String createdAt;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.fcmToken,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String? ?? json['fullName'] as String? ?? '',
      fcmToken: json['fcm_token'] as String?,
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'fcm_token': fcmToken,
      'created_at': createdAt,
    };
  }
}
