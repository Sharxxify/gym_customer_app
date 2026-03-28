import '../models/models.dart';

class MockData {
  static List<GymModel> get gyms => [
    GymModel(
      id: '1',
      name: 'Zinga Fitness & Training',
      address: '14th Main Rd, 7th Sector, HSR Layout',
      locality: 'Koramangala',
      city: 'Bengaluru',
      pincode: '560102',
      latitude: 12.9352,
      longitude: 77.6245,
      distance: 1.5,
      rating: 4.8,
      reviewCount: 1200,
      pricePerDay: 1200,
      is24x7: true,
      hasTrainer: true,
      images: [],
      aboutUs: 'Zinga Fitness & Training is dedicated to transforming lives through personalized coaching and energizing group classes. We focus on building strength, improving endurance.',
      facilities: [
        FacilityModel(id: '1', name: 'Trainer', isAvailable: true),
        FacilityModel(id: '2', name: 'Group Classes', isAvailable: true),
        FacilityModel(id: '3', name: 'Changing Areas', isAvailable: true),
        FacilityModel(id: '4', name: 'Washroom', isAvailable: true),
      ],
      services: [
        ServiceModel(
          id: '1',
          name: 'Yoga',
          pricePerSlot: 299,
          schedule: 'Every day',
          timing: '7:00 AM - 8:00 AM',
        ),
        ServiceModel(
          id: '2',
          name: 'Zumba',
          pricePerSlot: 399,
          schedule: 'Mon-Fri',
          timing: '5:00 PM - 6:00 PM',
        ),
        ServiceModel(
          id: '3',
          name: 'CrossFit',
          pricePerSlot: 499,
          schedule: 'Mon, Tue, Fri',
          timing: '6:00 PM - 7:00 PM',
        ),
        ServiceModel(
          id: '4',
          name: 'Weight Training',
          pricePerSlot: 349,
          schedule: 'Fri',
          timing: '6:00 PM - 7:00 PM',
        ),
      ],
      equipments: [
        EquipmentModel(id: '1', name: 'Treadmill', quantity: 10),
        EquipmentModel(id: '2', name: 'Dumbbells', quantity: 20),
        EquipmentModel(id: '3', name: 'Bench Press', quantity: 5),
        EquipmentModel(id: '4', name: 'Leg Press', quantity: 3),
        EquipmentModel(id: '5', name: 'Cable Machine', quantity: 4),
      ],
      businessHours: [
        BusinessHours(day: 'Mon', isOpen: true, openTime: '9:00 AM', closeTime: '5:00 PM'),
        BusinessHours(day: 'Tue', isOpen: true, openTime: '9:00 AM', closeTime: '5:00 PM'),
        BusinessHours(day: 'Wed', isOpen: true, openTime: '9:00 AM', closeTime: '5:00 PM'),
        BusinessHours(day: 'Thu', isOpen: true, openTime: '9:00 AM', closeTime: '5:00 PM'),
        BusinessHours(day: 'Fri', isOpen: true, openTime: '9:00 AM', closeTime: '5:00 PM'),
        BusinessHours(day: 'Sat', isOpen: false, openTime: null, closeTime: null),
        BusinessHours(day: 'Sun', isOpen: false, openTime: null, closeTime: null),
      ],
      isOpen: true,
    ),
    GymModel(
      id: '2',
      name: 'Iron Pulse Fitness',
      address: '23rd Cross, 4th Block',
      locality: 'Koramangala',
      city: 'Bengaluru',
      pincode: '560034',
      latitude: 12.9412,
      longitude: 77.6301,
      distance: 2.2,
      rating: 4.4,
      reviewCount: 243,
      pricePerDay: 800,
      is24x7: false,
      hasTrainer: true,
      images: [],
      aboutUs: 'Iron Pulse Fitness provides top-notch facilities for strength training and cardio workouts.',
      facilities: [
        FacilityModel(id: '1', name: 'Trainer', isAvailable: true),
        FacilityModel(id: '3', name: 'Washroom', isAvailable: true),
      ],
      services: [
        ServiceModel(
          id: '1',
          name: 'Personal Training',
          pricePerSlot: 599,
          schedule: 'Mon-Sat',
          timing: '6:00 AM - 9:00 PM',
        ),
      ],
      equipments: [
        EquipmentModel(id: '1', name: 'Treadmill', quantity: 8),
        EquipmentModel(id: '2', name: 'Dumbbells', quantity: 15),
      ],
      businessHours: [
        BusinessHours(day: 'Mon', isOpen: true, openTime: '6:00 AM', closeTime: '9:00 PM'),
        BusinessHours(day: 'Tue', isOpen: true, openTime: '6:00 AM', closeTime: '9:00 PM'),
        BusinessHours(day: 'Wed', isOpen: true, openTime: '6:00 AM', closeTime: '9:00 PM'),
        BusinessHours(day: 'Thu', isOpen: true, openTime: '6:00 AM', closeTime: '9:00 PM'),
        BusinessHours(day: 'Fri', isOpen: true, openTime: '6:00 AM', closeTime: '9:00 PM'),
        BusinessHours(day: 'Sat', isOpen: true, openTime: '7:00 AM', closeTime: '6:00 PM'),
        BusinessHours(day: 'Sun', isOpen: false, openTime: null, closeTime: null),
      ],
      isOpen: true,
    ),
    GymModel(
      id: '3',
      name: 'Flex Zone Gym',
      address: '12th Main, Indiranagar',
      locality: 'Indiranagar',
      city: 'Bengaluru',
      pincode: '560038',
      latitude: 12.9716,
      longitude: 77.6412,
      distance: 3.5,
      rating: 4.6,
      reviewCount: 567,
      pricePerDay: 1500,
      is24x7: true,
      hasTrainer: true,
      images: [],
      facilities: [
        FacilityModel(id: '1', name: 'Trainer', isAvailable: true),
        FacilityModel(id: '2', name: 'Group Classes', isAvailable: true),
        FacilityModel(id: '3', name: 'Sauna', isAvailable: true),
        FacilityModel(id: '4', name: 'Locker Room', isAvailable: true),
      ],
      services: [],
      equipments: [],
      businessHours: [],
      isOpen: true,
    ),
  ];

  static List<ReviewModel> get reviews => [
    ReviewModel(
      id: '1',
      gymId: '1',
      userId: 'u1',
      userName: 'Sunil Bhadouriya',
      rating: 4.5,
      description: 'My therapist was absolutely incredible! They instinctively found and worked out every knot I had. I walked in with chronic pain and left feeling completely renewed and light.',
      createdAt: DateTime(2020, 8, 27, 8, 3),
    ),
    ReviewModel(
      id: '2',
      gymId: '1',
      userId: 'u2',
      userName: 'Vishwas Patel',
      rating: 4.0,
      description: 'The moment you step inside, the stress just melts away. The atmosphere is serene, the room was cozy, and the staff was so welcoming. A truly tranquil escape that I highly recommend!',
      createdAt: DateTime(2025, 9, 11, 14, 30),
    ),
    ReviewModel(
      id: '3',
      gymId: '1',
      userId: 'u3',
      userName: 'Vikas Tiwari',
      rating: 3.5,
      description: 'Excellent service from booking to finish—very professional and clean facilities. This was a deep-tissue massage that delivered real results. Worth every penny for the quality of care.',
      createdAt: DateTime(2025, 9, 11, 14, 30),
    ),
  ];

  static List<BookingModel> get bookings => [
    BookingModel(
      id: '1',
      gymId: '1',
      gymName: 'Zinga Fitness & Training',
      gymAddress: '14th Main Rd, 7th Sector, HSR Layout, Bengaluru, Karnataka 560102',
      type: BookingType.membership,
      status: BookingStatus.confirmed,
      bookingDate: DateTime(2025, 9, 11),
      membershipType: 'Single Gym',
      bookingFor: 'Karthik Aryan',
      amount: 12045,
      totalAmount: 12045,
      paymentMethod: 'HDFC Card | xx7354',
      createdAt: DateTime(2025, 9, 11, 14, 30),
    ),
    BookingModel(
      id: '2',
      gymId: '1',
      gymName: 'Zinga Fitness & Training',
      gymAddress: '14th Main Rd, 7th Sector, HSR Layout',
      type: BookingType.service,
      status: BookingStatus.completed,
      serviceId: '1',
      serviceName: 'Yoga Booking',
      bookingDate: DateTime(2020, 8, 27),
      timeSlot: '8:00 AM - 9:00 AM',
      bookingFor: 'Karthik Aryan',
      amount: 299,
      totalAmount: 299,
      createdAt: DateTime(2020, 8, 27, 8, 3),
    ),
    BookingModel(
      id: '3',
      gymId: '1',
      gymName: 'Zinga Fitness & Training',
      gymAddress: '14th Main Rd, 7th Sector, HSR Layout',
      type: BookingType.service,
      status: BookingStatus.completed,
      serviceId: '1',
      serviceName: 'Yoga Booking',
      bookingDate: DateTime(2020, 8, 27),
      timeSlot: '12:00 PM - 1:00 PM',
      bookingFor: 'Karthik Aryan',
      amount: 299,
      totalAmount: 299,
      createdAt: DateTime(2020, 8, 27, 12, 5),
    ),
    BookingModel(
      id: '4',
      gymId: '1',
      gymName: 'Zinga Fitness & Training',
      gymAddress: '14th Main Rd, 7th Sector, HSR Layout',
      type: BookingType.membership,
      status: BookingStatus.completed,
      bookingDate: DateTime(2020, 8, 27),
      membershipType: 'Monthly',
      bookingFor: 'Karthik Aryan',
      amount: 299,
      totalAmount: 299,
      createdAt: DateTime(2020, 8, 27, 13, 3),
    ),
  ];

  static List<TimeSlotModel> get timeSlots => [
    TimeSlotModel(id: '1', label: '9:00 AM - 11:00 AM', startTime: '9:00 AM', endTime: '11:00 AM', period: 'morning'),
    TimeSlotModel(id: '2', label: '11:00 AM - 1:00 PM', startTime: '11:00 AM', endTime: '1:00 PM', period: 'morning'),
    TimeSlotModel(id: '3', label: '2:00 PM - 4:00 PM', startTime: '2:00 PM', endTime: '4:00 PM', period: 'afternoon'),
    TimeSlotModel(id: '4', label: '5:00 PM - 7:00 PM', startTime: '5:00 PM', endTime: '7:00 PM', period: 'evening'),
  ];

  static List<SubscriptionModel> get subscriptionPlans => [
    SubscriptionModel(id: '1', type: 'single_gym', duration: '1_day', durationLabel: '1 Day', price: 100, originalPrice: 120),
    SubscriptionModel(id: '2', type: 'single_gym', duration: '1_week', durationLabel: '1 Week', price: 400, originalPrice: 480),
    SubscriptionModel(id: '3', type: 'single_gym', duration: '1_month', durationLabel: '1 Month', price: 1600, originalPrice: 1920),
    SubscriptionModel(id: '4', type: 'single_gym', duration: '3_months', durationLabel: '3 Months', price: 6400, originalPrice: 7680),
    SubscriptionModel(id: '5', type: 'single_gym', duration: '1_year', durationLabel: '1 Year', price: 19200, originalPrice: 23040),
    SubscriptionModel(id: '6', type: 'multi_gym', duration: '1_day', durationLabel: '1 Day', price: 150, originalPrice: 180),
    SubscriptionModel(id: '7', type: 'multi_gym', duration: '1_week', durationLabel: '1 Week', price: 600, originalPrice: 720),
    SubscriptionModel(id: '8', type: 'multi_gym', duration: '1_month', durationLabel: '1 Month', price: 899, originalPrice: 1080),
    SubscriptionModel(id: '9', type: 'multi_gym', duration: '3_months', durationLabel: '3 Months', price: 2400, originalPrice: 2880),
    SubscriptionModel(id: '10', type: 'multi_gym', duration: '1_year', durationLabel: '1 Year', price: 8400, originalPrice: 10080),
  ];

  static List<NotificationModel> get notifications => [
    NotificationModel(
      id: '1',
      title: 'Appointment confirmed',
      message: 'Your booking for Yoga at Zinga Fitness has been confirmed for Dec 20, 2025',
      type: 'booking',
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 4)),
      isRead: false,
      actionType: 'booking_detail',
      actionId: 'booking_1',
    ),
    NotificationModel(
      id: '2',
      title: 'Attendance Marked',
      message: 'You checked in at Zinga Fitness at 09:15 AM',
      type: 'attendance',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      isRead: false,
      actionType: 'attendance_detail',
      actionId: 'att_1',
    ),
  ];

  static Map<DateTime, bool> get attendanceData {
    final data = <DateTime, bool>{};
    final now = DateTime.now();

    // Generate attendance for current month
    for (int i = 1; i <= now.day; i++) {
      final date = DateTime(now.year, now.month, i);
      // Skip weekends (6 = Saturday, 7 = Sunday)
      if (date.weekday != 6 && date.weekday != 7) {
        // Random attendance pattern
        data[date] = i % 4 != 0; // Mark absent every 4th day
      }
    }

    return data;
  }

  static List<String> get filterFacilities => [
    'A/C',
    'Trainer Support',
    '24x7',
    'Washroom',
    'Locker Room',
    'Parking',
  ];

  static List<String> get sortOptions => [
    'Relevance',
    'Fee: High to low',
    'Fee: Low to high',
    'Rating: High to low',
    'Distance: Low to High',
  ];
}