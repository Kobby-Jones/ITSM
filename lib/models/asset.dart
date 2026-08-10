import 'package:flutter/material.dart';

enum AssetCategory {
  laptop('LAPTOP', 'Laptops', Icons.laptop_mac_rounded),
  desktop('DESKTOP', 'Desktops', Icons.desktop_windows_rounded),
  server('SERVER', 'Servers', Icons.dns_rounded),
  network('NETWORK_DEVICE', 'Network', Icons.router_rounded),
  printer('PRINTER', 'Printers', Icons.print_rounded),
  mobile('MOBILE_DEVICE', 'Mobile Devices', Icons.smartphone_rounded),
  peripheral('PERIPHERAL', 'Peripherals', Icons.keyboard_rounded),
  softwareLicense('SOFTWARE_LICENSE', 'Software Licenses', Icons.key_rounded),
  other('OTHER', 'Other', Icons.category_rounded);

  final String apiValue;
  final String label;
  final IconData icon;
  const AssetCategory(this.apiValue, this.label, this.icon);

  static AssetCategory fromApi(String? value) => AssetCategory.values.firstWhere(
        (c) => c.apiValue == value,
        orElse: () => AssetCategory.other,
      );
}

enum AssetStatus {
  inUse('ACTIVE', 'In Use', Color(0xFF10B981)),
  inStock('INACTIVE', 'In Stock', Color(0xFF3B82F6)),
  maintenance('UNDER_MAINTENANCE', 'Maintenance', Color(0xFFF59E0B)),
  retired('DISPOSED', 'Retired', Color(0xFF6B7280)),
  lost('LOST', 'Lost', Color(0xFFDC2626));

  final String apiValue;
  final String label;
  final Color color;
  const AssetStatus(this.apiValue, this.label, this.color);

  static AssetStatus fromApi(String? value) => AssetStatus.values.firstWhere(
        (s) => s.apiValue == value,
        orElse: () => AssetStatus.inStock,
      );
}

class AssetAssignment {
  final String userName;
  final String department;
  final DateTime assignedOn;
  final DateTime? returnedOn;

  const AssetAssignment({
    required this.userName,
    required this.department,
    required this.assignedOn,
    this.returnedOn,
  });

  factory AssetAssignment.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    return AssetAssignment(
      userName: user != null ? '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim() : '',
      department: (user?['department'] as Map?)?['name'] as String? ?? '',
      assignedOn: DateTime.parse(json['assignedAt'] as String),
      returnedOn: json['returnedAt'] != null ? DateTime.parse(json['returnedAt'] as String) : null,
    );
  }
}

class Asset {
  final String id;
  final String tag;
  final String name;
  final String model;
  final String manufacturer;
  final String serialNumber;
  final AssetCategory category;
  final AssetStatus status;
  final String currentUser;
  final String department;
  final String location;
  final DateTime purchasedOn;
  final DateTime warrantyUntil;
  final double cost;
  final List<AssetAssignment> assignmentHistory;

  const Asset({
    required this.id,
    required this.tag,
    required this.name,
    required this.model,
    required this.manufacturer,
    required this.serialNumber,
    required this.category,
    required this.status,
    required this.currentUser,
    required this.department,
    required this.location,
    required this.purchasedOn,
    required this.warrantyUntil,
    required this.cost,
    required this.assignmentHistory,
  });

  factory Asset.fromJson(Map<String, dynamic> json) {
    final department = json['department'] as Map<String, dynamic>?;
    final assignments = (json['assignments'] as List?) ?? const [];
    final active = assignments.cast<Map<String, dynamic>>().where((a) => a['isActive'] == true);
    final activeUser = active.isNotEmpty ? active.first['user'] as Map<String, dynamic>? : null;

    return Asset(
      id: json['id'] as String,
      tag: json['assetTag'] as String? ?? '',
      name: json['name'] as String? ?? '',
      model: json['model'] as String? ?? '',
      manufacturer: json['make'] as String? ?? '',
      serialNumber: json['serialNumber'] as String? ?? '',
      category: AssetCategory.fromApi(json['category'] as String?),
      status: AssetStatus.fromApi(json['status'] as String?),
      currentUser: activeUser != null
          ? '${activeUser['firstName'] ?? ''} ${activeUser['lastName'] ?? ''}'.trim()
          : 'Unassigned',
      department: department?['name'] as String? ?? '',
      location: json['location'] as String? ?? '',
      purchasedOn: json['purchaseDate'] != null
          ? DateTime.parse(json['purchaseDate'] as String)
          : DateTime.now(),
      warrantyUntil: json['warrantyExpiry'] != null
          ? DateTime.parse(json['warrantyExpiry'] as String)
          : DateTime.now(),
      cost: double.tryParse(json['purchasePrice']?.toString() ?? '') ?? 0,
      assignmentHistory: assignments
          .cast<Map<String, dynamic>>()
          .map(AssetAssignment.fromJson)
          .toList(),
    );
  }

  Map<String, dynamic> toPayload() => {
        'name': name,
        'category': category.apiValue,
        'status': status.apiValue,
        'make': manufacturer,
        'model': model,
        'serialNumber': serialNumber,
        'assetTag': tag,
        'location': location,
      };
}
