class BannerModel {
  final String fileKey;
  final String fileName;
  final int size;
  final DateTime lastModified;
  final String viewUrl;

  BannerModel({
    required this.fileKey,
    required this.fileName,
    required this.size,
    required this.lastModified,
    required this.viewUrl,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      fileKey: json['file_key'] ?? '',
      fileName: json['file_name'] ?? '',
      size: json['size'] ?? 0,
      lastModified: json['last_modified'] != null
          ? DateTime.parse(json['last_modified'])
          : DateTime.now(),
      viewUrl: json['url'] ?? json['view_url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'file_key': fileKey,
      'file_name': fileName,
      'size': size,
      'last_modified': lastModified.toIso8601String(),
      'view_url': viewUrl,
    };
  }

  // Check if the banner is an image based on file extension
  bool get isImage {
    final extension = fileName.toLowerCase().split('.').last;
    return ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(extension);
  }
}

class BannerResponse {
  final bool success;
  final String message;
  final List<BannerModel> banners;
  final int totalCount;

  BannerResponse({
    required this.success,
    required this.message,
    required this.banners,
    required this.totalCount,
  });

  factory BannerResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final documents = data?['banners'] as List<dynamic>? ?? [];

    return BannerResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      banners: documents
          .map((doc) => BannerModel.fromJson(doc))
          .where((banner) => banner.isImage) // Filter only images
          .toList(),
      totalCount: data?['total_count'] ?? 0,
    );
  }
}