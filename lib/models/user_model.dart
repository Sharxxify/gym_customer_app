class UserModel {
  final String? id;
  final String phoneNumber;
  final String? name;
  final String? email;
  final String? gender;
  final String? dateOfBirth;
  final String? profileImage;
  final DateTime? createdAt;
  final int? totalBookings;
  final int? totalAttendanceDays;
  final int? activeSubscriptions;

  UserModel({
    this.id,
    required this.phoneNumber,
    this.name,
    this.email,
    this.gender,
    this.dateOfBirth,
    this.profileImage,
    this.createdAt,
    this.totalBookings,
    this.totalAttendanceDays,
    this.activeSubscriptions,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      phoneNumber: json['phone_number'] ?? json['phoneNumber'] ?? '',
      name: json['name'],
      email: json['email'],
      gender: json['gender'],
      dateOfBirth: json['date_of_birth'] ?? json['dateOfBirth'],
      profileImage: json['profile_image'] ?? json['profileImage'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      totalBookings: json['total_bookings'],
      totalAttendanceDays: json['total_attendance_days'],
      activeSubscriptions: json['active_subscriptions'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone_number': phoneNumber,
      'name': name,
      'email': email,
      'gender': gender,
      'date_of_birth': dateOfBirth,
      'profile_image': profileImage,
      'created_at': createdAt?.toIso8601String(),
      'total_bookings': totalBookings,
      'total_attendance_days': totalAttendanceDays,
      'active_subscriptions': activeSubscriptions,
    };
  }

  UserModel copyWith({
    String? id,
    String? phoneNumber,
    String? name,
    String? email,
    String? gender,
    String? dateOfBirth,
    String? profileImage,
    DateTime? createdAt,
    int? totalBookings,
    int? totalAttendanceDays,
    int? activeSubscriptions,
  }) {
    return UserModel(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      name: name ?? this.name,
      email: email ?? this.email,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      profileImage: profileImage ?? this.profileImage,
      createdAt: createdAt ?? this.createdAt,
      totalBookings: totalBookings ?? this.totalBookings,
      totalAttendanceDays: totalAttendanceDays ?? this.totalAttendanceDays,
      activeSubscriptions: activeSubscriptions ?? this.activeSubscriptions,
    );
  }

  bool get isProfileComplete => name != null && name!.isNotEmpty;
}

class AuthResponse {
  final bool success;
  final String? message;
  final String? token;
  final UserModel? user;
  final bool isNewUser;

  AuthResponse({
    required this.success,
    this.message,
    this.token,
    this.user,
    this.isNewUser = false,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      success: json['success'] ?? false,
      message: json['message'],
      token: json['token'],
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
      isNewUser: json['is_new_user'] ?? json['isNewUser'] ?? false,
    );
  }
}

class OtpResponse {
  final bool success;
  final String? message;
  final String? otp; // Only for development/testing

  OtpResponse({
    required this.success,
    this.message,
    this.otp,
  });

  factory OtpResponse.fromJson(Map<String, dynamic> json) {
    return OtpResponse(
      success: json['success'] ?? false,
      message: json['message'],
      otp: json['otp'],
    );
  }
}