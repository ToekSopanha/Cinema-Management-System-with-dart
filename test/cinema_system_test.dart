import 'dart:io';

import 'package:cinema_system/cinema_system.dart';
import 'package:test/test.dart';

void main() {
  group('Model & Constructor Tests', () {
    test('Default Constructor initializes guest customer', () {
      final customer = Customer();
      expect(customer.id, 'C000');
      expect(customer.name, 'Default Guest');
    });

    test('Parameterized Constructor creates registered customer', () {
      final customer = Customer.registered(
        id: 'C101',
        name: 'Sophea',
        phone: '012345',
        email: 'sophea@test.com',
      );
      expect(customer.id, 'C101');
      expect(customer.name, 'Sophea');
    });

    test('Named Constructor creates VIP customer and VIP seat', () {
      final vipCustomer = Customer.vip(
        id: 'VIP001',
        name: 'Vannak',
        phone: '099888',
      );
      expect(vipCustomer.email, 'VIP001.vip@cinema.com');

      final vipSeat = Seat.vip(id: 'V1', seatRow: 'V', seatNumber: 1);
      expect(vipSeat.priceMultiplier, 1.5);
    });

    test('Factory Constructor creates seat from code and movie standard', () {
      final seat = Seat.fromCode('B5');
      expect(seat.seatRow, 'B');
      expect(seat.seatNumber, 5);

      final movie = Movie.standard(title: 'Panda', showtime: '10:00');
      expect(movie.ticketPrice, 8.00);
    });

    test('User model constructors and password verification', () {
      final admin = User.admin(
        username: 'admin_test',
        passwordHash: User.hashPassword('pass1'),
      );
      expect(admin.isAdmin, isTrue);
      expect(admin.isStaff, isFalse);
      expect(admin.verifyPassword('pass1'), isTrue);
      expect(admin.verifyPassword('wrong'), isFalse);

      final staff = User.staff(
        username: 'staff_test',
        passwordHash: User.hashPassword('pass2'),
      );
      expect(staff.isStaff, isTrue);
      expect(staff.isAdmin, isFalse);
    });

    test('JSON serialization round-trip for models', () {
      final customer = Customer.registered(
        id: 'C999',
        name: 'Json Test',
        phone: '123',
        email: 'json@test.com',
      );
      final customerJson = customer.toJson();
      final customerRestored = Customer.fromJson(customerJson);
      expect(customerRestored.id, customer.id);
      expect(customerRestored.name, customer.name);

      final seat = Seat(id: 'A1', seatRow: 'A', seatNumber: 1, isBooked: true);
      final seatJson = seat.toJson();
      final seatRestored = Seat.fromJson(seatJson);
      expect(seatRestored.id, 'A1');
      expect(seatRestored.isBooked, isTrue);

      final movie = Movie.standard(id: 'M99', title: 'Test Mov', showtime: '12:00');
      final movieJson = movie.toJson();
      final movieRestored = Movie.fromJson(movieJson);
      expect(movieRestored.id, 'M99');
      expect(movieRestored.title, 'Test Mov');
      expect(movieRestored.seats.length, movie.seats.length);
    });
  });

  group('Repository Pattern & JSON Persistence Tests', () {
    late Directory tempDir;
    late String userPath;
    late String customerPath;
    late String moviePath;
    late String bookingPath;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('cinema_test_');
      userPath = '${tempDir.path}/users.json';
      customerPath = '${tempDir.path}/customers.json';
      moviePath = '${tempDir.path}/movies.json';
      bookingPath = '${tempDir.path}/bookings.json';
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('Repositories auto-seed files when missing', () {
      final userRepo = UserRepository(filePath: userPath);
      final customerRepo = CustomerRepository(filePath: customerPath);
      final movieRepo = MovieRepository(filePath: moviePath);

      expect(File(userPath).existsSync(), isTrue);
      expect(File(customerPath).existsSync(), isTrue);
      expect(File(moviePath).existsSync(), isTrue);

      expect(userRepo.getAll().length, greaterThanOrEqualTo(2)); // admin & staff
      expect(customerRepo.getAll().length, greaterThanOrEqualTo(4));
      expect(movieRepo.getAll().length, greaterThanOrEqualTo(3));
    });

    test('UserRepository CRUD and search', () {
      final userRepo = UserRepository(filePath: userPath);
      final initialCount = userRepo.getAll().length;

      // Create
      final newUser = User.staff(
        username: 'cashier',
        passwordHash: User.hashPassword('pass'),
      );
      userRepo.create(newUser);
      expect(userRepo.getAll().length, initialCount + 1);

      // Read
      expect(userRepo.getByUsername('cashier'), isNotNull);

      // Search
      final searchResults = userRepo.searchByUsername('cash');
      expect(searchResults.length, 1);
      expect(searchResults.first.username, 'cashier');

      // Update
      newUser.updatePassword(User.hashPassword('newpass'));
      final updated = userRepo.update(newUser);
      expect(updated, isTrue);

      // Reload fresh from disk to verify persistence
      final reloadedRepo = UserRepository(filePath: userPath);
      final retrieved = reloadedRepo.getByUsername('cashier');
      expect(retrieved?.verifyPassword('newpass'), isTrue);

      // Delete
      final deleted = userRepo.delete('cashier');
      expect(deleted, isTrue);
      expect(userRepo.getByUsername('cashier'), isNull);
    });

    test('Movie and Booking Repositories sync seat status to disk', () {
      final customerRepo = CustomerRepository(filePath: customerPath);
      final movieRepo = MovieRepository(filePath: moviePath);
      final bookingRepo = BookingRepository(
        filePath: bookingPath,
        customerRepository: customerRepo,
        movieRepository: movieRepo,
      );

      final movie = movieRepo.getAll().first;
      final seat = movie.findAvailableSeat()!;
      expect(seat.isBooked, isFalse);

      final ticket = Ticket.issue(
        ticketId: 'TKT-TEST-01',
        customer: customerRepo.getAll().first,
        movie: movie,
        seat: seat,
      );

      bookingRepo.create(ticket);

      // Verify ticket saved
      expect(bookingRepo.getAll().length, 1);
      expect(File(bookingPath).existsSync(), isTrue);

      // Reload movie from disk to verify seat status persisted
      final reloadedMovieRepo = MovieRepository(filePath: moviePath);
      final reloadedMovie = reloadedMovieRepo.getById(movie.id)!;
      final reloadedSeat = reloadedMovie.seats.firstWhere((s) => s.id == seat.id);
      expect(reloadedSeat.isBooked, isTrue);
    });
  });

  group('Service Layer RBAC & Guards', () {
    late Directory tempDir;
    late AuthService auth;
    late Cinema cinema;
    late UserRepository userRepo;
    late CustomerRepository customerRepo;
    late MovieRepository movieRepo;
    late BookingRepository bookingRepo;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('cinema_service_test_');
      userRepo = UserRepository(filePath: '${tempDir.path}/users.json');
      customerRepo = CustomerRepository(filePath: '${tempDir.path}/customers.json');
      movieRepo = MovieRepository(filePath: '${tempDir.path}/movies.json');
      bookingRepo = BookingRepository(
        filePath: '${tempDir.path}/bookings.json',
        customerRepository: customerRepo,
        movieRepository: movieRepo,
      );

      auth = AuthService(userRepository: userRepo);
      cinema = Cinema(
        name: 'Test Cinema',
        auth: auth,
        movieRepository: movieRepo,
        customerRepository: customerRepo,
        bookingRepository: bookingRepo,
      );
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('Staff login and access limitations', () {
      auth.login('staff', 'staff123');
      expect(auth.isStaff, isTrue);
      expect(auth.isAdmin, isFalse);

      // Admin actions denied for staff
      final addResult = cinema.addMovie(Movie.standard(title: 'Forbidden', showtime: '12:00'));
      expect(addResult, isFalse);

      final removeResult = cinema.removeMovie(0);
      expect(removeResult, isFalse);

      final createUserResult = auth.createStaffAccount('newbie', 'pass123');
      expect(createUserResult, isFalse);

      // Staff actions allowed
      final ticket = cinema.bookTicket(
        customer: cinema.customers.first,
        movie: cinema.movies.first,
      );
      expect(ticket, isNotNull);
    });

    test('Admin full access to all operations', () {
      auth.login('admin', 'admin123');
      expect(auth.isAdmin, isTrue);

      final movieCountBefore = cinema.movies.length;
      final addResult = cinema.addMovie(
        Movie.standard(title: 'Admin Movie', showtime: '20:00'),
      );
      expect(addResult, isTrue);
      expect(cinema.movies.length, movieCountBefore + 1);

      // Create staff account
      final createStaffResult = auth.createStaffAccount('operator1', 'pass1234');
      expect(createStaffResult, isTrue);

      // Delete staff account
      final deleteResult = auth.deleteUser('operator1');
      expect(deleteResult, isTrue);
    });

    test('Admin cannot delete own account or last admin', () {
      auth.login('admin', 'admin123');

      final deleteSelf = auth.deleteUser('admin');
      expect(deleteSelf, isFalse);
    });
  });
}
