import 'dart:io';

import 'package:cinema_system/cinema_system.dart';

void main() {
  print('================================================================');
  print('     CINEMA BOOKING SYSTEM — REPOSITORY PERSISTENCE & RBAC      ');
  print('================================================================\n');

  // Check if data directory already exists
  final dataDir = Directory('data');
  final isFirstRun = !dataDir.existsSync();

  if (isFirstRun) {
    print('📁 [SETUP] "data/" folder not found (first run on this machine).');
    print('   Auto-creating "data/" directory and generating default seed data...\n');
  } else {
    print('📁 [STORAGE] Existing "data/" folder detected.');
    print('   Loading existing records from disk (no overwrite).\n');
  }

  // Initialize Repositories (creates 'data/' and seeds JSON files if absent)
  final userRepo = UserRepository(filePath: 'data/users.json');
  final customerRepo = CustomerRepository(filePath: 'data/customers.json');
  final movieRepo = MovieRepository(filePath: 'data/movies.json');
  final bookingRepo = BookingRepository(
    filePath: 'data/bookings.json',
    customerRepository: customerRepo,
    movieRepository: movieRepo,
  );

  // Initialize AuthService and Cinema with repositories
  final auth = AuthService(userRepository: userRepo);
  final cinema = Cinema(
    name: 'Major Cineplex (Phnom Penh)',
    auth: auth,
    movieRepository: movieRepo,
    customerRepository: customerRepo,
    bookingRepository: bookingRepo,
  );

  print('Database Status: Ready in ./data/');
  print('Default Admin Credentials:  username: admin  |  password: admin123\n');

  // ---------- LOGIN → MENU LOOP ----------
  while (true) {
    // Prompt for login when no session is active
    if (!auth.isLoggedIn) {
      final loggedIn = _loginFlow(auth);
      if (!loggedIn) {
        _exitApp();
        return;
      }
    }

    // Show the appropriate menu based on the user's role
    final shouldExit = auth.isAdmin
        ? _showAdminMenu(cinema, auth)
        : _showStaffMenu(cinema, auth);

    if (shouldExit) {
      _exitApp();
      return;
    }
  }
}

/// Print goodbye message.
void _exitApp() {
  print('\nThank you for using Cinema Booking System! Goodbye.');
}

// =====================================================================
// HELPER: Read input with exit support
// =====================================================================

/// Reads a line from stdin. Returns `null` if user types "0" or "exit"
/// (signalling they want to go back / cancel the current action).
String? _readInput(String prompt) {
  stdout.write(prompt);
  final input = stdin.readLineSync()?.trim() ?? '';
  if (input == '0' || input.toLowerCase() == 'exit') return null;
  return input;
}

// =====================================================================
// LOGIN FLOW
// =====================================================================

/// Prompts for username/password with up to 5 attempts.
/// Returns `true` on successful login, `false` to exit the app.
bool _loginFlow(AuthService auth) {
  print('================ LOGIN ================');
  print('(Type "exit" to quit the system)\n');

  int attempts = 0;
  const maxAttempts = 5;

  while (attempts < maxAttempts) {
    stdout.write('Username: ');
    final username = stdin.readLineSync()?.trim() ?? '';

    // Allow graceful exit from the login screen
    if (username.toLowerCase() == 'exit') return false;

    stdout.write('Password: ');
    final password = _readPassword();

    if (username.isEmpty || password.isEmpty) {
      print('Username and password are required.\n');
      continue;
    }

    final user = auth.login(username, password);
    if (user != null) {
      print('\n✓ Welcome, ${user.username}! Role: ${user.roleName}\n');
      return true;
    }

    attempts++;
    final remaining = maxAttempts - attempts;
    if (remaining > 0) {
      print('✗ Invalid credentials. $remaining attempt(s) remaining.\n');
    }
  }

  print('✗ Maximum login attempts exceeded.');
  return false;
}

/// Reads a password from stdin with echo disabled (masked input).
/// Falls back to normal input if echo control is not supported.
String _readPassword() {
  try {
    stdin.echoMode = false;
    final password = stdin.readLineSync() ?? '';
    stdin.echoMode = true;
    print(''); // newline after hidden input
    return password;
  } catch (_) {
    // echoMode not supported (e.g., IDE debug console)
    return stdin.readLineSync() ?? '';
  }
}

// =====================================================================
// STAFF MENU  (options 0–7)
// =====================================================================

/// Displays the Staff menu. Returns `true` if the user chose to exit.
bool _showStaffMenu(Cinema cinema, AuthService auth) {
  print('\n================ MAIN MENU (STAFF) ================');
  print('1. View Movies');
  print('2. View Customers');
  print('3. Register New Customer');
  print('4. Book a Ticket');
  print('5. View All Bookings');
  print('6. Cinema Summary');
  print('7. Log Out');
  print('0. Exit');
  print('====================================================');
  stdout.write('Choose an option (0-7): ');

  final choice = stdin.readLineSync()?.trim();

  switch (choice) {
    case '1':
      cinema.showMovies();
    case '2':
      cinema.showCustomers();
    case '3':
      _registerNewCustomer(cinema);
    case '4':
      _bookTicketInteractive(cinema);
    case '5':
      cinema.viewAllBookings();
    case '6':
      cinema.displayCinemaSummary();
    case '7':
      print('\nLogging out ${auth.currentUser?.username}...');
      auth.logout();
    case '0':
      return true; // signal exit
    default:
      print('Invalid choice. Please select 0-7.');
  }
  return false;
}

// =====================================================================
// ADMIN MENU  (options 0–12)
// =====================================================================

/// Displays the Admin menu. Returns `true` if the user chose to exit.
bool _showAdminMenu(Cinema cinema, AuthService auth) {
  print('\n================ MAIN MENU (ADMIN) ================');
  print('---- Operations ----');
  print(' 1. View Movies');
  print(' 2. View Customers');
  print(' 3. Register New Customer');
  print(' 4. Book a Ticket');
  print(' 5. View All Bookings');
  print(' 6. Cinema Summary');
  print('---- Admin Actions ----');
  print(' 7. Add New Movie');
  print(' 8. Remove Movie');
  print(' 9. Create Staff Account');
  print('10. Delete User Account');
  print('11. View All Users');
  print('12. Log Out');
  print(' 0. Exit');
  print('====================================================');
  stdout.write('Choose an option (0-12): ');

  final choice = stdin.readLineSync()?.trim();

  switch (choice) {
    // --- Standard operations (shared with Staff) ---
    case '1':
      cinema.showMovies();
    case '2':
      cinema.showCustomers();
    case '3':
      _registerNewCustomer(cinema);
    case '4':
      _bookTicketInteractive(cinema);
    case '5':
      cinema.viewAllBookings();
    case '6':
      cinema.displayCinemaSummary();
    // --- Admin-only actions ---
    case '7':
      _addMovieInteractive(cinema);
    case '8':
      _removeMovieInteractive(cinema);
    case '9':
      _createStaffInteractive(auth);
    case '10':
      _deleteUserInteractive(auth);
    case '11':
      auth.showAllUsers();
    case '12':
      print('\nLogging out ${auth.currentUser?.username}...');
      auth.logout();
    case '0':
      return true; // signal exit
    default:
      print('Invalid choice. Please select 0-12.');
  }
  return false;
}

// =====================================================================
// SHARED OPERATIONS  (Staff + Admin)
// =====================================================================

/// Interactive prompt to register a new customer.
/// Type "0" or "exit" at any prompt to cancel.
void _registerNewCustomer(Cinema cinema) {
  print('\n--- Register New Customer --- (type 0 to cancel)');

  final id = _readInput('Enter Customer ID (e.g. C103): ');
  if (id == null) return;

  final name = _readInput('Enter Name: ');
  if (name == null) return;

  final phone = _readInput('Enter Phone: ');
  if (phone == null) return;

  final email = _readInput('Enter Email: ');
  if (email == null) return;

  if (id.isEmpty || name.isEmpty) {
    print('Registration failed: ID and Name are required.');
    return;
  }

  // Using Factory Constructor (fromMap)
  final newCustomer = Customer.fromMap({
    'id': id,
    'name': name,
    'phone': phone,
    'email': email,
  });

  cinema.registerCustomer(newCustomer);
  print('\n✓ Customer registered successfully!');
  newCustomer.displayInfo();
}

/// Interactive prompt to book a ticket.
/// Type "0" or "exit" at any prompt to cancel.
void _bookTicketInteractive(Cinema cinema) {
  if (cinema.movies.isEmpty) {
    print('\nNo movies available.');
    return;
  }

  // Show movies
  cinema.showMovies();
  print('(Enter 0 to cancel)');
  final movieInput = _readInput('\nSelect movie number: ');
  if (movieInput == null) return;

  final movieIndex = int.tryParse(movieInput) ?? 0;
  if (movieIndex < 1 || movieIndex > cinema.movies.length) {
    print('Invalid movie selection.');
    return;
  }

  final selectedMovie = cinema.movies[movieIndex - 1];

  if (selectedMovie.availableSeatCount == 0) {
    print('Sorry, "${selectedMovie.title}" is completely sold out!');
    return;
  }

  // Show available seats
  print('\nAvailable seats for "${selectedMovie.title}":');
  final availableSeats =
      selectedMovie.seats.where((s) => !s.isBooked).toList();
  for (int i = 0; i < availableSeats.length; i++) {
    final s = availableSeats[i];
    final type = s.priceMultiplier > 1.0 ? 'VIP' : 'Standard';
    print('  ${i + 1}. Seat ${s.id} ($type)');
  }
  print('(Enter 0 to cancel)');
  final seatInput = _readInput('Select seat number: ');
  if (seatInput == null) return;

  final seatIndex = int.tryParse(seatInput) ?? 0;
  if (seatIndex < 1 || seatIndex > availableSeats.length) {
    print('Invalid seat selection.');
    return;
  }

  final selectedSeat = availableSeats[seatIndex - 1];

  // Enter customer details
  print('\n--- Enter Customer Information --- (type 0 to cancel)');
  final name = _readInput('Enter Customer Name: ');
  if (name == null) return;

  final phone = _readInput('Enter Phone: ');
  if (phone == null) return;

  final email = _readInput('Enter Email: ');
  if (email == null) return;

  if (name.isEmpty) {
    print('Booking failed: Customer name is required.');
    return;
  }

  // Create and register customer using Parameterized Constructor
  final customerId = 'C${cinema.customers.length + 100}';
  final newCustomer = Customer.registered(
    id: customerId,
    name: name,
    phone: phone.isEmpty ? 'N/A' : phone,
    email: email.isEmpty ? 'N/A' : email,
  );
  cinema.registerCustomer(newCustomer);
  print('\n✓ Customer registered successfully!');
  newCustomer.displayInfo();

  // Book ticket (uses Factory Constructor internally via Ticket.issue)
  final ticket = cinema.bookTicket(
    customer: newCustomer,
    movie: selectedMovie,
    specificSeat: selectedSeat,
  );

  if (ticket != null) {
    print('\n✓ Booking successful!');
    ticket.printReceipt();
  }
}

// =====================================================================
// ADMIN-ONLY OPERATIONS
// =====================================================================

/// Interactive prompt to add a new movie to the catalog.
/// Type "0" or "exit" at any prompt to cancel.
void _addMovieInteractive(Cinema cinema) {
  print('\n--- Add New Movie --- (type 0 to cancel)');

  final title = _readInput('Enter Movie Title: ');
  if (title == null) return;

  final genre = _readInput('Enter Genre: ');
  if (genre == null) return;

  final showtime = _readInput('Enter Showtime (e.g. 14:00 PM): ');
  if (showtime == null) return;

  final priceInput = _readInput('Enter Base Ticket Price: ');
  if (priceInput == null) return;
  final price = double.tryParse(priceInput) ?? 0;

  final seatsInput = _readInput('Enter Total Seats: ');
  if (seatsInput == null) return;
  final seats = int.tryParse(seatsInput) ?? 0;

  if (title.isEmpty || genre.isEmpty || showtime.isEmpty) {
    print('Failed: Title, Genre, and Showtime are required.');
    return;
  }
  if (price <= 0 || seats <= 0) {
    print('Failed: Price and Seats must be positive numbers.');
    return;
  }

  final movie = Movie(
    title: title,
    genre: genre,
    showtime: showtime,
    ticketPrice: price,
    totalSeats: seats,
  );

  // Auth guard is enforced inside cinema.addMovie()
  cinema.addMovie(movie);
}

/// Interactive prompt to remove a movie from the catalog.
/// Type "0" or "exit" at any prompt to cancel.
void _removeMovieInteractive(Cinema cinema) {
  if (cinema.movies.isEmpty) {
    print('\nNo movies to remove.');
    return;
  }

  cinema.showMovies();
  print('(Enter 0 to cancel)');
  final indexInput = _readInput('\nSelect movie number to remove: ');
  if (indexInput == null) return;

  final index = int.tryParse(indexInput) ?? 0;
  if (index < 1 || index > cinema.movies.length) {
    print('Invalid selection.');
    return;
  }

  final confirm = _readInput(
    'Are you sure you want to remove '
    '"${cinema.movies[index - 1].title}"? (y/n): ',
  );
  if (confirm == null || confirm.toLowerCase() != 'y') {
    print('Removal cancelled.');
    return;
  }

  // Auth guard is enforced inside cinema.removeMovie()
  cinema.removeMovie(index - 1);
}

/// Interactive prompt to create a new Staff user account.
/// Type "0" or "exit" at any prompt to cancel.
void _createStaffInteractive(AuthService auth) {
  print('\n--- Create Staff Account --- (type 0 to cancel)');

  final username = _readInput('Enter Username: ');
  if (username == null) return;

  if (username.isEmpty) {
    print('Failed: Username is required.');
    return;
  }

  stdout.write('Enter Password (min 4 chars): ');
  final password = _readPassword();

  if (password.isEmpty) {
    print('Failed: Password is required.');
    return;
  }

  // Auth guard is enforced inside auth.createStaffAccount()
  if (auth.createStaffAccount(username, password)) {
    print('✓ Staff account "$username" created successfully!');
  }
}

/// Interactive prompt to delete a user account.
/// Type "0" or "exit" at any prompt to cancel.
void _deleteUserInteractive(AuthService auth) {
  auth.showAllUsers();
  print('(Enter 0 to cancel)');

  final username = _readInput('\nEnter username to delete: ');
  if (username == null) return;

  if (username.isEmpty) {
    print('No username provided.');
    return;
  }

  final confirm = _readInput(
    'Are you sure you want to delete "$username"? (y/n): ',
  );
  if (confirm == null || confirm.toLowerCase() != 'y') {
    print('Deletion cancelled.');
    return;
  }

  // Auth guard is enforced inside auth.deleteUser()
  if (auth.deleteUser(username)) {
    print('✓ User "$username" deleted successfully.');
  }
}