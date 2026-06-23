// ignore_for_file: non_constant_identifier_names

class LoginRequest {
  final String email;
  final String password;
  LoginRequest({required this.email, required this.password});
  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}

class LoginResponse {
  final String student_id;
  final String name;
  final String grade_level;
  final String token;
  LoginResponse(
      {required this.student_id,
      required this.name,
      required this.grade_level,
      required this.token});
  factory LoginResponse.fromJson(Map<String, dynamic> json) => LoginResponse(
        student_id: json['student_id'],
        name: json['name'],
        grade_level: json['grade_level'],
        token: json['token'],
      );
}

class RegisterRequest {
  final String name;
  final String email;
  final String password;
  final String grade_level;
  RegisterRequest(
      {required this.name,
      required this.email,
      required this.password,
      required this.grade_level});
  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'password': password,
        'grade_level': grade_level
      };
}

class RegisterResponse {
  final String student_id;
  final String token;
  RegisterResponse({required this.student_id, required this.token});
  factory RegisterResponse.fromJson(Map<String, dynamic> json) =>
      RegisterResponse(
        student_id: json['student_id'],
        token: json['token'],
      );
}
