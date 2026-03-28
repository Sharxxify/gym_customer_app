class ReviewModel {
  final String id;
  final String gymId;
  final String userId;
  final String userName;
  final String? userImage;
  final double rating;
  final String? description;
  final DateTime createdAt;
  final String? reply;
  final DateTime? replyAt;

  ReviewModel({
    required this.id,
    required this.gymId,
    required this.userId,
    required this.userName,
    this.userImage,
    required this.rating,
    this.description,
    required this.createdAt,
    this.reply,
    this.replyAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] ?? '',
      gymId: json['gym_id'] ?? json['gymId'] ?? '',
      userId: json['user_id'] ?? json['userId'] ?? '',
      userName: json['user_name'] ?? json['userName'] ?? '',
      userImage: json['user_image'] ?? json['userImage'],
      rating: (json['rating'] ?? 0).toDouble(),
      description: json['description'],
      createdAt: DateTime.parse(
        json['created_at'] ?? json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      reply: json['reply'],
      replyAt: json['reply_at'] != null
          ? DateTime.parse(json['reply_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'gym_id': gymId,
      'user_id': userId,
      'user_name': userName,
      'user_image': userImage,
      'rating': rating,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'reply': reply,
      'reply_at': replyAt?.toIso8601String(),
    };
  }
}

class AttendanceModel {
  final String id;
  final String gymId;
  final String gymName;
  final DateTime date;
  final String? checkInTime;
  final String? checkOutTime;
  final bool isPresent;

  AttendanceModel({
    required this.id,
    required this.gymId,
    required this.gymName,
    required this.date,
    this.checkInTime,
    this.checkOutTime,
    required this.isPresent,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'] ?? '',
      gymId: json['gym_id'] ?? json['gymId'] ?? '',
      gymName: json['gym_name'] ?? json['gymName'] ?? '',
      date: DateTime.parse(json['date']),
      checkInTime: json['check_in_time'] ?? json['checkInTime'],
      checkOutTime: json['check_out_time'] ?? json['checkOutTime'],
      isPresent: json['is_present'] ?? json['isPresent'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'gym_id': gymId,
      'gym_name': gymName,
      'date': date.toIso8601String(),
      'check_in_time': checkInTime,
      'check_out_time': checkOutTime,
      'is_present': isPresent,
    };
  }
}