class AddressModel {
  final String id;
  final String houseFlat;
  final String roadArea;
  final String streetCity;
  final String label;
  final double latitude;
  final double longitude;
  final bool isDefault;
  final DateTime? createdAt;

  AddressModel({
    required this.id,
    required this.houseFlat,
    required this.roadArea,
    required this.streetCity,
    required this.label,
    required this.latitude,
    required this.longitude,
    required this.isDefault,
    this.createdAt,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'] ?? '',
      houseFlat: json['house_flat'] ?? '',
      roadArea: json['road_area'] ?? '',
      streetCity: json['street_city'] ?? '',
      label: json['label'] ?? '',
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      isDefault: json['is_default'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'house_flat': houseFlat,
      'road_area': roadArea,
      'street_city': streetCity,
      'label': label,
      'latitude': latitude,
      'longitude': longitude,
      'is_default': isDefault,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  String get fullAddress {
    return '$houseFlat, $roadArea, $streetCity';
  }

  String get shortAddress {
    return '$roadArea, $streetCity';
  }
}

class AddressListResponse {
  final bool success;
  final String message;
  final List<AddressModel> addresses;
  final int total;

  AddressListResponse({
    required this.success,
    required this.message,
    required this.addresses,
    required this.total,
  });

  factory AddressListResponse.fromJson(Map<String, dynamic> json) {
    final addressesData = json['data']?['addresses'] as List? ?? [];

    return AddressListResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      addresses: addressesData
          .map((address) => AddressModel.fromJson(address))
          .toList(),
      total: json['data']?['total'] ?? 0,
    );
  }
}

class AddAddressResponse {
  final bool success;
  final String message;
  final AddressModel? address;

  AddAddressResponse({
    required this.success,
    required this.message,
    this.address,
  });

  factory AddAddressResponse.fromJson(Map<String, dynamic> json) {
    return AddAddressResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      address: json['data']?['address'] != null
          ? AddressModel.fromJson(json['data']['address'])
          : null,
    );
  }
}