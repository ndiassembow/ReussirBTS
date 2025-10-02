// 📁 lib/models/user_model.dart
class AppUser {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String school;
  final String speciality;
  final String role;
  final String? photoUrl;
  final String? niveau;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    this.phone = '',
    this.school = '',
    this.speciality = '',
    this.role = 'etudiant',
    this.photoUrl,
    this.niveau,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'school': school,
      'speciality': speciality,
      'role': role,
      'photoUrl': photoUrl,
      'niveau': niveau,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      school: map['school'] ?? '',
      speciality: map['speciality'] ?? '',
      role: map['role'] ?? 'etudiant',
      photoUrl: map['photoUrl'],
      niveau: map['niveau'],
    );
  }

  // ======= copyWith (sans password) =======
  AppUser copyWith({
    String? uid,
    String? name,
    String? email,
    String? phone,
    String? school,
    String? speciality,
    String? role,
    String? photoUrl,
    String? niveau,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      school: school ?? this.school,
      speciality: speciality ?? this.speciality,
      role: role ?? this.role,
      photoUrl: photoUrl ?? this.photoUrl,
      niveau: niveau ?? this.niveau,
    );
  }
}
