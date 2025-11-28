class AppUser {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String profileImage;
  final bool isBanned;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.profileImage,
    required this.isBanned,
  });

  factory AppUser.fromFirestore(Map<String, dynamic> data, String id) {
    return AppUser(
      id: id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      profileImage: data['profileImage'] ?? '',
      isBanned: data['isBanned'] ?? false,
    );
  }
}
