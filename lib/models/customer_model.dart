// lib/models/customer_model.dart
//
// Mirrors AuthController::profile() — the shape returned by login, verify-code,
// GET /auth/me and PATCH /auth/me.

import 'package:flutter/foundation.dart';

@immutable
class CustomerModel {
  final int id;

  /// Server-side `full_name`. Use this for display rather than joining the
  /// parts yourself.
  final String name;

  final String firstName;
  final String? lastName;
  final String? email;
  final String? phone;
  final String? companyName;

  /// Accounts start unapproved and cannot sign in until an admin approves
  /// them. Prices are hidden while this is false.
  final bool isApproved;

  const CustomerModel({
    required this.id,
    required this.name,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.companyName,
    required this.isApproved,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) => CustomerModel(
    id: (json['id'] as num?)?.toInt() ?? 0,
    name: json['name']?.toString() ?? '',
    firstName: json['first_name']?.toString() ?? '',
    lastName: _nullable(json['last_name']),
    email: _nullable(json['email']),
    phone: _nullable(json['phone']),
    companyName: _nullable(json['company_name']),
    isApproved: json['is_approved'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'first_name': firstName,
    'last_name': lastName,
    'email': email,
    'phone': phone,
    'company_name': companyName,
    'is_approved': isApproved,
  };

  static String? _nullable(dynamic value) {
    final str = value?.toString().trim();
    return (str == null || str.isEmpty) ? null : str;
  }
}

/// A successful authentication: the bearer token plus the customer it belongs
/// to. Returned by both the email and the phone sign-in paths.
@immutable
class AuthSession {
  final String token;
  final CustomerModel customer;

  const AuthSession({required this.token, required this.customer});

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
    token: json['token']?.toString() ?? '',
    customer: CustomerModel.fromJson(
      (json['customer'] as Map<String, dynamic>?) ?? const {},
    ),
  );
}