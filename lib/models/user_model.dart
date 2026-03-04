class UserModel {
  final String uid;
  String name;
  String email;
  String? phone;
  int? age;
  String? bloodType;
  String? emergencyContactName;
  String? emergencyContactPhone;
  String? observations;
  String? profileImageUrl;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.phone,
    this.age,
    this.bloodType,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.observations,
    this.profileImageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'age': age,
      'bloodType': bloodType,
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
      'observations': observations,
      'profileImageUrl': profileImageUrl,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'],
      age: map['age'],
      bloodType: map['bloodType'],
      emergencyContactName: map['emergencyContactName'],
      emergencyContactPhone: map['emergencyContactPhone'],
      observations: map['observations'],
      profileImageUrl: map['profileImageUrl'],
    );
  }

  // Método para atualizar dados
  UserModel copyWith({
    String? name,
    String? phone,
    int? age,
    String? bloodType,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? observations,
    String? profileImageUrl,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      age: age ?? this.age,
      bloodType: bloodType ?? this.bloodType,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      observations: observations ?? this.observations,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }
}