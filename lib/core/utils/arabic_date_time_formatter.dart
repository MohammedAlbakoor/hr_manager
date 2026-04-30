class ArabicDateTimeFormatter {
  ArabicDateTimeFormatter._();

  static String date(dynamic value) {
    final date = _parse(value);
    if (date == null) {
      return '--';
    }

    const months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  static String time(dynamic value) {
    final date = _parse(value);
    if (date == null) {
      return '--';
    }

    final hour = date.hour > 12
        ? date.hour - 12
        : date.hour == 0
        ? 12
        : date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final suffix = date.hour >= 12 ? 'م' : 'ص';
    return '${hour.toString().padLeft(2, '0')}:$minute $suffix';
  }

  static String dateTime(dynamic value) {
    final date = _parse(value);
    if (date == null) {
      return '--';
    }

    return '${ArabicDateTimeFormatter.date(date)} - ${ArabicDateTimeFormatter.time(date)}';
  }

  static String weekday(dynamic value) {
    final date = _parse(value);
    if (date == null) {
      return '--';
    }

    const weekdays = [
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد',
    ];
    return weekdays[date.weekday - 1];
  }

  static DateTime? _parse(dynamic value) {
    if (value is DateTime) {
      return value.toLocal();
    }
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value)?.toLocal();
    }
    return null;
  }
}
