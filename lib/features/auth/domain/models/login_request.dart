class LoginRequest {
  const LoginRequest({
    required this.email,
    required this.password,
    required this.rememberMe,
  });

  final String email;
  final String password;
  final bool rememberMe;

  Map<String, dynamic> toJson() {
    return {'email': email, 'password': password, 'remember_me': rememberMe};
  }
}
