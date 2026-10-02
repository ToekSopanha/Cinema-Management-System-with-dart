import '../models/user.dart';
import '../repositories/user_repository.dart';

/// Manages user accounts, authentication sessions, and authorization guards
/// backed by persistent [UserRepository].
class AuthService {
  final UserRepository userRepository;
  User? _currentUser;

  AuthService({UserRepository? userRepository})
      : userRepository = userRepository ?? UserRepository();

  // ======================== Session ========================

  /// Currently authenticated user (null if not logged in).
  User? get currentUser => _currentUser;

  /// Whether any user is currently logged in.
  bool get isLoggedIn => _currentUser != null;

  /// Whether the logged-in user has Admin role.
  bool get isAdmin => _currentUser?.isAdmin ?? false;

  /// Whether the logged-in user has Staff role.
  bool get isStaff => _currentUser?.isStaff ?? false;

  /// Read-only view of all registered user accounts.
  List<User> get allUsers => userRepository.getAll();

  /// Authenticate a user by username and password.
  /// Returns the [User] on success, `null` on failure.
  User? login(String username, String password) {
    final user = userRepository.getByUsername(username);
    if (user != null && user.verifyPassword(password)) {
      _currentUser = user;
      return user;
    }
    return null;
  }

  /// End the current user session.
  void logout() {
    _currentUser = null;
  }

  // ======================== Authorization Guards ========================

  /// Returns `true` if a user is currently authenticated.
  /// Prints an access-denied message and returns `false` otherwise.
  bool requireAuth() {
    if (!isLoggedIn) {
      print('[ACCESS DENIED] You must be logged in.');
      return false;
    }
    return true;
  }

  /// Returns `true` if the logged-in user holds the Admin role.
  /// Prints an access-denied message and returns `false` otherwise.
  bool requireAdmin() {
    if (!requireAuth()) return false;
    if (!isAdmin) {
      print('[ACCESS DENIED] Admin privileges required.');
      return false;
    }
    return true;
  }

  // ======================== User Management (Admin Only) ========================

  /// Create a new Staff user account.
  /// **Guarded:** requires the caller to hold Admin role.
  bool createStaffAccount(String username, String password) {
    if (!requireAdmin()) return false;

    // Prevent duplicate usernames
    if (userRepository.getByUsername(username) != null) {
      print('Error: Username "$username" already exists.');
      return false;
    }

    if (password.length < 4) {
      print('Error: Password must be at least 4 characters.');
      return false;
    }

    final newStaff = User.staff(
      username: username,
      passwordHash: User.hashPassword(password),
    );
    userRepository.create(newStaff);
    return true;
  }

  /// Delete a user account by username.
  /// **Guarded:** requires Admin role. Cannot delete self or last Admin.
  bool deleteUser(String username) {
    if (!requireAdmin()) return false;

    // Safety: cannot delete your own account
    if (username == _currentUser?.username) {
      print('Error: You cannot delete your own account.');
      return false;
    }

    final target = userRepository.getByUsername(username);
    if (target == null) {
      print('Error: User "$username" not found.');
      return false;
    }

    // Safety: prevent deleting the last Admin
    if (target.isAdmin) {
      final adminCount = userRepository.getByRole(Role.admin).length;
      if (adminCount <= 1) {
        print('Error: Cannot delete the last Admin account.');
        return false;
      }
    }

    return userRepository.delete(username);
  }

  /// Display all registered user accounts.
  /// **Guarded:** requires Admin role.
  void showAllUsers() {
    if (!requireAdmin()) return;

    final users = userRepository.getAll();
    print('\n================ USER ACCOUNTS (${users.length}) ================');
    for (int i = 0; i < users.length; i++) {
      final u = users[i];
      print(
        '  ${i + 1}. ${u.username} | Role: ${u.roleName} | '
        'Created: ${u.createdAt.toLocal()}',
      );
    }
    print('==================================================');
  }
}
