import 'package:flutter/material.dart';

enum AssetCategory {
  laptop('Laptops', Icons.laptop_mac_rounded),
  desktop('Desktops', Icons.desktop_windows_rounded),
  server('Servers', Icons.dns_rounded),
  network('Network', Icons.router_rounded),
  printer('Printers', Icons.print_rounded),
  mobile('Mobile Devices', Icons.smartphone_rounded),
  peripheral('Peripherals', Icons.keyboard_rounded);

  final String label;
  final IconData icon;
  const AssetCategory(this.label, this.icon);
}

enum AssetStatus {
  inUse('In Use', Color(0xFF10B981)),
  inStock('In Stock', Color(0xFF3B82F6)),
  maintenance('Maintenance', Color(0xFFF59E0B)),
  retired('Retired', Color(0xFF6B7280));

  final String label;
  final Color color;
  const AssetStatus(this.label, this.color);
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
}
