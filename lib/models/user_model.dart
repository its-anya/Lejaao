class UserModel {
  final String uid;
  final String displayName;
  final String email;
  final String phoneNumber;
  String address;
  final DateTime? createdAt;

  UserModel({
    required this.uid,
    required this.displayName,
    required this.email,
    this.phoneNumber = '',
    this.address = '',
    this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      displayName: map['name'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      address: map['address'] ?? '',
      createdAt: map['createdAt'] != null 
          ? (map['createdAt'] as dynamic).toDate() 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': displayName,
      'email': email,
      'phoneNumber': phoneNumber,
      'address': address,
      'createdAt': createdAt,
    };
  }

  UserModel copyWith({
    String? uid,
    String? displayName,
    String? email,
    String? phoneNumber,
    String? address,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
    );
  }
} 