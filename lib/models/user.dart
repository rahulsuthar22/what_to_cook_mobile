class UserModel {
  final String uid;
  final String displayName;
  final String email;
  final String mobileNumber;
  final String dietaryPreference;

  UserModel({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.mobileNumber,
    required this.dietaryPreference,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? json['user_id'] ?? json['id'] ?? '',
      displayName: json['displayName'] ?? json['full_name'] ?? json['fullName'] ?? '',
      email: json['email'] ?? '',
      mobileNumber: json['mobile_number'] ?? json['mobileNumber'] ?? '',
      dietaryPreference: json['dietary_preference'] ?? json['dietaryPreference'] ?? 'None',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'mobile_number': mobileNumber,
      'dietary_preference': dietaryPreference,
    };
  }
}
