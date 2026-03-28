class AttendanceRecord {
  final String date;
  final bool isPresent;
  final String? gymId;
  final String? gymName;
  final String? checkInTime;
  final String? checkOutTime;

  AttendanceRecord({
    required this.date,
    required this.isPresent,
    this.gymId,
    this.gymName,
    this.checkInTime,
    this.checkOutTime,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      date: json['date'] ?? '',
      isPresent: json['is_present'] ?? json['isPresent'] ?? false,
      gymId: json['gym_id'] ?? json['gymId'],
      gymName: json['gym_name'] ?? json['gymName'],
      checkInTime: json['check_in_time'] ?? json['checkInTime'],
      checkOutTime: json['check_out_time'] ?? json['checkOutTime'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'is_present': isPresent,
      'gym_id': gymId,
      'gym_name': gymName,
      'check_in_time': checkInTime,
      'check_out_time': checkOutTime,
    };
  }
}

class AttendanceStatistics {
  final int totalDays;
  final int presentDays;
  final int absentDays;
  final int weekendDays;
  final double attendancePercentage;

  AttendanceStatistics({
    required this.totalDays,
    required this.presentDays,
    required this.absentDays,
    required this.weekendDays,
    required this.attendancePercentage,
  });

  factory AttendanceStatistics.fromJson(Map<String, dynamic> json) {
    // Handle attendance_percentage as both String and number
    final attendancePercentageValue = json['attendance_percentage'] ?? json['attendancePercentage'] ?? 0;
    double percentage = 0.0;

    if (attendancePercentageValue is String) {
      percentage = double.tryParse(attendancePercentageValue) ?? 0.0;
    } else if (attendancePercentageValue is num) {
      percentage = attendancePercentageValue.toDouble();
    }

    return AttendanceStatistics(
      totalDays: json['total_days'] ?? json['totalDays'] ?? 0,
      presentDays: json['present_days'] ?? json['presentDays'] ?? 0,
      absentDays: json['absent_days'] ?? json['absentDays'] ?? 0,
      weekendDays: json['weekend_days'] ?? json['weekendDays'] ?? 0,
      attendancePercentage: percentage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_days': totalDays,
      'present_days': presentDays,
      'absent_days': absentDays,
      'weekend_days': weekendDays,
      'attendance_percentage': attendancePercentage,
    };
  }
}

class AttendanceCalendar {
  final int month;
  final int year;
  final List<AttendanceRecord> attendance;
  final AttendanceStatistics statistics;

  AttendanceCalendar({
    required this.month,
    required this.year,
    required this.attendance,
    required this.statistics,
  });

  factory AttendanceCalendar.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;

    return AttendanceCalendar(
      month: data['month'] ?? 0,
      year: data['year'] ?? 0,
      attendance: (data['attendance'] as List?)
          ?.map((a) => AttendanceRecord.fromJson(a))
          .toList() ?? [],
      statistics: AttendanceStatistics.fromJson(data['statistics'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'month': month,
      'year': year,
      'attendance': attendance.map((a) => a.toJson()).toList(),
      'statistics': statistics.toJson(),
    };
  }
}