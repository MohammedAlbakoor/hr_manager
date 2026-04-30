class ManagerBroadcastMessage {
  const ManagerBroadcastMessage({
    required this.id,
    required this.title,
    required this.message,
    required this.audienceType,
    required this.recipientIds,
    required this.recipientNames,
    required this.createdAtLabel,
    required this.updatedAtLabel,
    required this.recipientCount,
  });

  final String id;
  final String title;
  final String message;
  final String audienceType;
  final List<int> recipientIds;
  final List<String> recipientNames;
  final String createdAtLabel;
  final String updatedAtLabel;
  final int recipientCount;

  bool get isAllAudience => audienceType == 'all';
}
