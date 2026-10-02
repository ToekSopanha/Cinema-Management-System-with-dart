import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Supported user roles in the cinema system.
enum Role { admin, staff }

/// Represents a user account with authentication credentials and a role.
///
/// Demonstrates multiple constructor types:
/// - Parameterized: `User(...)`
/// - Named: `User.admin(...)`, `User.staff(...)`
/// - Factory: `User.fromMap(...)`, `User.fromJson(...)`
class User {
  final String username;
  String _passwordHash;
  final Role role;
  final DateTime createdAt;

  // ---------- Constructors ----------

  // 3.2 Parameterized Constructor
  User({
    required this.username,
    required String passwordHash,
    required this.role,
    DateTime? createdAt,
  })  : _passwordHash = passwordHash,
        createdAt = createdAt ?? DateTime.now();

  // 3.3 Named Constructor — convenient Admin creation
  User.admin({
    required this.username,
    required String passwordHash,
  })  : role = Role.admin,
        _passwordHash = passwordHash,
        createdAt = DateTime.now();

  // 3.3 Named Constructor — convenient Staff creation
  User.staff({
    required this.username,
    required String passwordHash,
  })  : role = Role.staff,
        _passwordHash = passwordHash,
        createdAt = DateTime.now();

  // 3.4 Factory Constructor — build from key-value map
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      username: map['username'] as String,
      passwordHash: map['passwordHash'] as String,
      role: map['role'] == 'admin' ? Role.admin : Role.staff,
    );
  }

  // ---------- JSON Persistence ----------

  /// Serialize this user to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
        'username': username,
        'passwordHash': _passwordHash,
        'role': role.name,
        'createdAt': createdAt.toIso8601String(),
      };

  /// Deserialize a user from a JSON map (preserves createdAt timestamp).
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      username: json['username'] as String,
      passwordHash: json['passwordHash'] as String,
      role: json['role'] == 'admin' ? Role.admin : Role.staff,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  // ---------- Getters ----------

  String get passwordHash => _passwordHash;
  bool get isAdmin => role == Role.admin;
  bool get isStaff => role == Role.staff;
  String get roleName => role.name.toUpperCase();

  // ---------- Password Utilities ----------

  /// Hash a plaintext password using SHA-256.
  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  /// Verify a plaintext password against this user's stored hash.
  bool verifyPassword(String password) {
    return _passwordHash == hashPassword(password);
  }

  /// Update the stored password hash.
  void updatePassword(String newPasswordHash) {
    _passwordHash = newPasswordHash;
  }

  // ---------- Display ----------

  void displayInfo() {
    print(
      'Username: $username | Role: $roleName | '
      'Created: ${createdAt.toLocal()}',
    );
  }
}
