/// The logged-in student's account details, as returned by the backend's
/// `GET /auth/me`. Mirrors that endpoint's `MeResponse` shape.
class UserProfile {
  final int id;
  final String email;
  final String fullName;
  final String? section;
  final String? enrollmentStatus;

  const UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    this.section,
    this.enrollmentStatus,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as int,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      section: json['section'] as String?,
      enrollmentStatus: json['enrollment_status'] as String?,
    );
  }
}
