class EmployeeManagerOption {
  const EmployeeManagerOption({
    required this.id,
    required this.name,
    required this.code,
    required this.department,
    required this.jobTitle,
  });

  final int id;
  final String name;
  final String code;
  final String department;
  final String jobTitle;

  String get displayLabel => '$name - $code';
}
