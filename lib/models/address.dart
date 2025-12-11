class Address {
  final String id;
  final String userId;
  final String fullName;
  final String phone;
  final String province;
  final String district;
  final String ward;
  final String street;
  final bool isDefault;
  final String? note;

  Address({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.phone,
    required this.province,
    required this.district,
    required this.ward,
    required this.street,
    required this.isDefault,
    this.note,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      fullName: json['full_name'] ?? '',
      phone: json['phone'] ?? '',
      province: json['province'] ?? '',
      district: json['district'] ?? '',
      ward: json['ward'] ?? '',
      street: json['street'] ?? '',
      isDefault: json['is_default'] ?? false,
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'phone': phone,
      'province': province,
      'district': district,
      'ward': ward,
      'street': street,
      'is_default': isDefault,
      if (note != null) 'note': note,
    };
  }

  String get fullAddress {
    return '$street, $ward, $district, $province';
  }
}

