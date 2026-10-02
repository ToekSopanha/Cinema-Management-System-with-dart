import '../models/user.dart';
import 'json_repository.dart';

/// Repository for persistent storage and retrieval of [User] entities.
///
/// Stores credentials with SHA-256 password hashes in `data/users.json`.
class UserRepository extends JsonRepository<User, String> {
  UserRepository({super.filePath = 'data/users.json'});

  @override
  String getId(User item) => item.username;

  @override
  User fromJson(Map<String, dynamic> json) => User.fromJson(json);

  @override
  Map<String, dynamic> toJson(User item) => item.toJson();

  @override
  List<User> getInitialSeeds() {
    return [
      User.admin(
        username: 'admin',
        passwordHash: User.hashPassword('admin123'),
      ),
      User.staff(
        username: 'staff',
        passwordHash: User.hashPassword('staff123'),
      ),
    ];
  }

  /// Convenience lookup by username.
  User? getByUsername(String username) => getById(username);

  /// Find all users matching a role.
  List<User> getByRole(Role role) => search((u) => u.role == role);

  /// Search users whose username contains [query] (case-insensitive).
  List<User> searchByUsername(String query) {
    final lower = query.toLowerCase();
    return search((u) => u.username.toLowerCase().contains(lower));
  }
}
