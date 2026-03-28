import 'booking_model.dart';

class GymModel {
  final String id;
  final String name;
  final String address;
  final String locality;
  final String city;
  final String pincode;
  final double latitude;
  final double longitude;
  final double distance;
  final double rating;
  final int reviewCount;
  final int pricePerDay;
  final bool is24x7;
  final bool hasTrainer;
  final List<String> images;
  final List<String> videos;
  final String? aboutUs;
  final List<FacilityModel> facilities;
  final List<ServiceModel> services;
  final List<EquipmentModel> equipments;
  final List<BusinessHours> businessHours;
  final bool isOpen;
  final List<MembershipFee> membershipFees;

  GymModel({
    required this.id,
    required this.name,
    required this.address,
    required this.locality,
    required this.city,
    required this.pincode,
    required this.latitude,
    required this.longitude,
    required this.distance,
    required this.rating,
    required this.reviewCount,
    required this.pricePerDay,
    this.is24x7 = false,
    this.hasTrainer = false,
    this.images = const [],
    this.videos = const [],
    this.aboutUs,
    this.facilities = const [],
    this.services = const [],
    this.equipments = const [],
    this.businessHours = const [],
    this.isOpen = true,
    this.membershipFees = const [],
  });

  factory GymModel.fromJson(Map<String, dynamic> json) {
    // Helper to safely parse lat/lng which might be Map or number
    double _parseLatLng(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is Map) {
        // Handle cases like {lat: x} or {latitude: x}
        return (value['lat'] ?? value['latitude'] ?? value['lng'] ?? value['longitude'] ?? 0.0).toDouble();
      }
      return 0.0;
    }

    double _parseNumber(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return GymModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      locality: json['locality'] ?? '',
      city: json['city'] ?? '',
      pincode: json['pincode'] ?? '',
      latitude: _parseLatLng(json['latitude']),
      longitude: _parseLatLng(json['longitude']),
      distance: _parseNumber(json['distance']),
      rating: _parseNumber(json['rating']),
      reviewCount: json['review_count'] ?? json['reviewCount'] ?? 0,
      pricePerDay: json['price_per_day'] ?? json['pricePerDay'] ?? 0,
      is24x7: json['is_24x7'] ?? json['is24x7'] ?? false,
      hasTrainer: json['has_trainer'] ?? json['hasTrainer'] ?? false,
      images: List<String>.from(json['images'] ?? []),
      videos: List<String>.from(json['videos'] ?? []),
      aboutUs: json['about_us'] ?? json['aboutUs'],
      facilities: (json['facilities'] as List<dynamic>?)
          ?.map((f) => FacilityModel.fromJson(f))
          .toList() ??
          [],
      services: (json['services'] as List<dynamic>?)
          ?.map((s) => ServiceModel.fromJson(s))
          .toList() ??
          [],
      equipments: (json['equipments'] as List<dynamic>?)
          ?.map((e) => EquipmentModel.fromJson(e))
          .toList() ??
          [],
      businessHours: (json['business_hours'] as List<dynamic>?)
          ?.map((b) => BusinessHours.fromJson(b))
          .toList() ??
          [],
      isOpen: json['is_open'] ?? json['isOpen'] ?? true,
      membershipFees: (json['membership_fees'] as List<dynamic>?)
          ?.map((m) => MembershipFee.fromJson(m))
          .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'locality': locality,
      'city': city,
      'pincode': pincode,
      'latitude': latitude,
      'longitude': longitude,
      'distance': distance,
      'rating': rating,
      'review_count': reviewCount,
      'price_per_day': pricePerDay,
      'is_24x7': is24x7,
      'has_trainer': hasTrainer,
      'images': images,
      'videos': videos,
      'about_us': aboutUs,
      'facilities': facilities.map((f) => f.toJson()).toList(),
      'services': services.map((s) => s.toJson()).toList(),
      'equipments': equipments.map((e) => e.toJson()).toList(),
      'business_hours': businessHours.map((b) => b.toJson()).toList(),
      'is_open': isOpen,
      'membership_fees': membershipFees.map((m) => m.toJson()).toList(),
    };
  }

  String get fullAddress => '$address, $locality, $city - $pincode';
}

class FacilityModel {
  final String id;
  final String name;
  final String? icon;
  final bool isAvailable;

  FacilityModel({
    required this.id,
    required this.name,
    this.icon,
    this.isAvailable = true,
  });

  factory FacilityModel.fromJson(Map<String, dynamic> json) {
    return FacilityModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      icon: json['icon'],
      isAvailable: json['is_available'] ?? json['isAvailable'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'is_available': isAvailable,
    };
  }
}

class ServiceModel {
  final String id;
  final String name;
  final String? image;
  final int pricePerSlot;
  final String? schedule;
  final String? timing;
  final List<String>? availableDays;

  ServiceModel({
    required this.id,
    required this.name,
    this.image,
    required this.pricePerSlot,
    this.schedule,
    this.timing,
    this.availableDays,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      image: json['image'],
      pricePerSlot: json['price_per_slot'] ?? json['pricePerSlot'] ?? 0,
      schedule: json['schedule'],
      timing: json['timing'],
      availableDays: json['available_days'] != null
          ? List<String>.from(json['available_days'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image': image,
      'price_per_slot': pricePerSlot,
      'schedule': schedule,
      'timing': timing,
      'available_days': availableDays,
    };
  }
}

class EquipmentModel {
  final String id;
  final String name;
  final String? image;
  final int? quantity;

  EquipmentModel({
    required this.id,
    required this.name,
    this.image,
    this.quantity,
  });

  factory EquipmentModel.fromJson(Map<String, dynamic> json) {
    return EquipmentModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      image: json['image'],
      quantity: json['quantity'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image': image,
      'quantity': quantity,
    };
  }
}

class BusinessHours {
  final String day;
  final bool isOpen;
  final String? openTime;
  final String? closeTime;

  BusinessHours({
    required this.day,
    required this.isOpen,
    this.openTime,
    this.closeTime,
  });

  factory BusinessHours.fromJson(Map<String, dynamic> json) {
    return BusinessHours(
      day: json['day'] ?? '',
      isOpen: json['is_open'] ?? json['isOpen'] ?? false,
      openTime: json['open_time'] ?? json['openTime'],
      closeTime: json['close_time'] ?? json['closeTime'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'is_open': isOpen,
      'open_time': openTime,
      'close_time': closeTime,
    };
  }
}

class MembershipFee {
  final String id;
  final String type;
  final int durationMonths;
  final int price;
  final String currency;
  final List<String> features;

  MembershipFee({
    required this.id,
    required this.type,
    required this.durationMonths,
    required this.price,
    this.currency = 'INR',
    this.features = const [],
  });

  factory MembershipFee.fromJson(Map<String, dynamic> json) {
    return MembershipFee(
      id: json['_id'] ?? json['id'] ?? '',
      type: json['type'] ?? '',
      durationMonths: json['duration_months'] ?? json['durationMonths'] ?? 1,
      price: json['price'] ?? 0,
      currency: json['currency'] ?? 'INR',
      features: json['features'] != null
          ? List<String>.from(json['features'])
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'duration_months': durationMonths,
      'price': price,
      'currency': currency,
      'features': features,
    };
  }

  // Convert to SubscriptionModel for UI
  SubscriptionModel toSubscriptionModel({String? gymId, String? gymName}) {
    // Map duration_months to proper duration string
    String duration = type;
    // switch (durationMonths) {
    //   case 1:
    //     duration = 'monthly';
    //     break;
    //   case 3:
    //     duration = 'quarterly';
    //     break;
    //   case 6:
    //     duration = 'half_yearly';
    //     break;
    //   case 12:
    //     duration = 'yearly';
    //     break;
    //   default:
    //     duration = '${durationMonths}_months';
    // }

    String durationLabel = type;

    return SubscriptionModel(
      id: id,
      type: 'single_gym',
      duration: duration,
      durationLabel: durationLabel,
      price: price,
      gymId: gymId,
      gymName: gymName,
    );
  }
}