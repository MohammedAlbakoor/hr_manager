class MockCredentialsStore {
  MockCredentialsStore._();

  static final Map<String, String> _passwordsByEmail = <String, String>{
    'ahmad.khaled@company.com': 'password',
    'm.alotaibi@company.com': 'password',
    'n.alsubaei@company.com': 'password',
    'admin@company.com': 'admin123456',
  };

  static String? passwordForEmail(String email) {
    return _passwordsByEmail[email.trim().toLowerCase()];
  }

  static void setPasswordForEmail(String email, String password) {
    _passwordsByEmail[email.trim().toLowerCase()] = password;
  }
}
