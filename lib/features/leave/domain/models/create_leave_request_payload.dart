class CreateLeaveRequestPayload {
  const CreateLeaveRequestPayload({
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.note,
  });

  final String leaveType;
  final DateTime startDate;
  final DateTime endDate;
  final String note;

  Map<String, dynamic> toJson() {
    return {
      'leave_type': leaveType,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'note': note,
    };
  }
}
