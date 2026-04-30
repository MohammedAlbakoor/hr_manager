class ManagerBroadcastRecipient {
  const ManagerBroadcastRecipient({
    required this.id,
    required this.name,
    required this.code,
    required this.department,
    required this.jobTitle,
    required this.role,
  });

  final int id;
  final String name;
  final String code;
  final String department;
  final String jobTitle;
  final String role;

  bool get isHr => role == 'hr';

  String get roleLabel => isHr ? 'HR' : 'موظف';

  String get subtitle =>
      '$code - $department - ${jobTitle.isEmpty ? roleLabel : jobTitle}';
}
