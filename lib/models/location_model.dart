class LocationModel {
  final String? id;
  final double latitude;
  final double longitude;
  final String? address;
  final String? locality;
  final String? city;
  final String? state;
  final String? pincode;
  final String? label;

  LocationModel({
    this.id,
    required this.latitude,
    required this.longitude,
    this.address,
    this.locality,
    this.city,
    this.state,
    this.pincode,
    this.label,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: json['id'],
      latitude: (json['latitude'] ?? json['lat'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? json['lng'] ?? 0.0).toDouble(),
      address: json['address'],
      locality: json['locality'],
      city: json['city'],
      state: json['state'],
      pincode: json['pincode'],
      label: json['label'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'locality': locality,
      'city': city,
      'state': state,
      'pincode': pincode,
      'label': label,
    };
  }

  LocationModel copyWith({
    String? id,
    double? latitude,
    double? longitude,
    String? address,
    String? locality,
    String? city,
    String? state,
    String? pincode,
    String? label,
  }) {
    return LocationModel(
      id: id ?? this.id,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      locality: locality ?? this.locality,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      label: label ?? this.label,
    );
  }

  String get displayAddress {
    final parts = <String>[];
    if (locality != null && locality!.isNotEmpty) parts.add(locality!);
    if (city != null && city!.isNotEmpty) parts.add(city!);
    return parts.join(', ');
  }

  String get fullAddress {
    final parts = <String>[];
    if (address != null && address!.isNotEmpty) parts.add(address!);
    if (locality != null && locality!.isNotEmpty) parts.add(locality!);
    if (city != null && city!.isNotEmpty) parts.add(city!);
    if (state != null && state!.isNotEmpty) parts.add(state!);
    if (pincode != null && pincode!.isNotEmpty) parts.add(pincode!);
    return parts.join(', ');
  }
}

class AddressLocationModel {
  final String? id;
  final String houseFlat;
  final String roadArea;
  final String streetCity;
  final String? label;
  final double? latitude;
  final double? longitude;

  AddressLocationModel({
    this.id,
    required this.houseFlat,
    required this.roadArea,
    required this.streetCity,
    this.label,
    this.latitude,
    this.longitude,
  });

  factory AddressLocationModel.fromJson(Map<String, dynamic> json) {
    return AddressLocationModel(
      id: json['id'],
      houseFlat: json['house_flat'] ?? json['houseFlat'] ?? '',
      roadArea: json['road_area'] ?? json['roadArea'] ?? '',
      streetCity: json['street_city'] ?? json['streetCity'] ?? '',
      label: json['label'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
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
    };
  }

  String get fullAddress {
    return '$houseFlat, $roadArea, $streetCity';
  }
}
