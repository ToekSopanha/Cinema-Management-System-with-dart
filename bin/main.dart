import 'dart:io';
import 'package:cinema_system/cinema_system.dart';

void main() {
  print('================================================================');
  print('          CINEMA BOOKING SYSTEM - OOP DEMONSTRATION             ');
  print('================================================================\n');

  // ------------------------------------------------------------------
  // SECTION 1: DEMONSTRATING ALL 4 CONSTRUCTOR TYPES
  // ------------------------------------------------------------------
  print('>>> SECTION 1: DEMONSTRATING CONSTRUCTOR TYPES\n');

  // 3.1 Default Constructor
  print('[1] Default Constructor:');
  final guestCustomer = Customer();
  guestCustomer.displayInfo();

  // 3.2 Parameterized Constructor
  print('\n[2] Parameterized Constructor:');
  final customer2 = Customer.registered(
    id: 'C101',
    name: 'Sophea Chan',
    phone: '012-345-678',
    email: 'sophea@gmail.com',
  );
  customer2.displayInfo();

  // 3.3 Named Constructor
  print('\n[3] Named Constructor:');
  final vipCustomer = Customer.vip(
    id: 'VIP001',
    name: 'Vannak Heng',
    phone: '099-888-777',
  );
  vipCustomer.displayInfo();

  final blockbusterMovie = Movie.blockbuster(
    title: 'Avengers: Secret Wars',
    showtime: '19:30 PM',
  );
  blockbusterMovie.displayInfo();

  // 3.4 Factory Constructor
  print('\n[4] Factory Constructor:');
  final customer4 = Customer.fromMap({
    'id': 'C102',
    'name': 'Dara Sok',
    'phone': '077-111-222',
    'email': 'dara@gmail.com',
  });
  customer4.displayInfo();

  final standardMovie = Movie.standard(
    title: 'Kung Fu Panda 4',
    showtime: '11:00 AM',
  );
  standardMovie.displayInfo();

  final seatFromCode = Seat.fromCode('B5');
  seatFromCode.displayInfo();

  // ------------------------------------------------------------------
  // SECTION 2: INTERACTIVE CINEMA SYSTEM WITH USER INPUT
  // ------------------------------------------------------------------
  print('\n\n>>> SECTION 2: INTERACTIVE CINEMA SYSTEM\n');

  // Initialize Cinema
  final cinema = Cinema(name: 'Major Cineplex (Phnom Penh)');

  // Seed sample movies
  cinema.addMovie(Movie(
    title: 'Avatar: The Way of Water',
    genre: 'Sci-Fi / Adventure',
    showtime: '14:00 PM',
    ticketPrice: 9.50,
    totalSeats: 5,
  ));
  cinema.addMovie(blockbusterMovie);
  cinema.addMovie(standardMovie);

  // Seed sample customers
  cinema.registerCustomer(guestCustomer);
  cinema.registerCustomer(customer2);
  cinema.registerCustomer(vipCustomer);
  cinema.registerCustomer(customer4);

  // ---------- MENU LOOP ----------
  while (true) {
    print('\n================ MAIN MENU ================');
    print('1. View Movies');
    print('2. View Customers');
    print('3. Register New Customer');
    print('4. Book a Ticket');
    print('5. View All Bookings');
    print('6. Cinema Summary');
    print('7. Exit');
    print('=============================================');
    stdout.write('Choose an option (1-7): ');

    final choice = stdin.readLineSync()?.trim();

    switch (choice) {
      case '1':
        cinema.showMovies();
        break;

      case '2':
        cinema.showCustomers();
        break;

      case '3':
        _registerNewCustomer(cinema);
        break;

      case '4':
        _bookTicketInteractive(cinema);
        break;

      case '5':
        cinema.viewAllBookings();
        break;

      case '6':
        cinema.displayCinemaSummary();
        break;

      case '7':
        print('\nThank you for using Cinema Booking System! Goodbye.');
        return;

      default:
        print('Invalid choice. Please select 1-7.');
    }
  }
}

// ---------- REGISTER NEW CUSTOMER ----------
void _registerNewCustomer(Cinema cinema) {
  print('\n--- Register New Customer ---');
  stdout.write('Enter Customer ID (e.g. C103): ');
  final id = stdin.readLineSync()?.trim() ?? '';

  stdout.write('Enter Name: ');
  final name = stdin.readLineSync()?.trim() ?? '';

  stdout.write('Enter Phone: ');
  final phone = stdin.readLineSync()?.trim() ?? '';

  stdout.write('Enter Email: ');
  final email = stdin.readLineSync()?.trim() ?? '';

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
  print('\nCustomer registered successfully!');
  newCustomer.displayInfo();
}

// ---------- BOOK TICKET INTERACTIVE ----------
void _bookTicketInteractive(Cinema cinema) {
  if (cinema.movies.isEmpty) {
    print('\nNo movies available.');
    return;
  }

  // Show movies
  cinema.showMovies();
  stdout.write('\nSelect movie number: ');
  final movieIndex = int.tryParse(stdin.readLineSync() ?? '') ?? 0;

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
  stdout.write('Select seat number: ');
  final seatIndex = int.tryParse(stdin.readLineSync() ?? '') ?? 0;

  if (seatIndex < 1 || seatIndex > availableSeats.length) {
    print('Invalid seat selection.');
    return;
  }

  final selectedSeat = availableSeats[seatIndex - 1];

  // Enter customer details
  print('\n--- Enter Customer Information ---');
  stdout.write('Enter Customer Name: ');
  final name = stdin.readLineSync()?.trim() ?? '';

  stdout.write('Enter Phone: ');
  final phone = stdin.readLineSync()?.trim() ?? '';

  stdout.write('Enter Email: ');
  final email = stdin.readLineSync()?.trim() ?? '';

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
  print('\nCustomer registered successfully!');
  newCustomer.displayInfo();

  // Book ticket using Cinema's bookTicket method (uses Factory Constructor internally)
  final ticket = cinema.bookTicket(
    customer: newCustomer,
    movie: selectedMovie,
    specificSeat: selectedSeat,
  );

  if (ticket != null) {
    print('\nBooking successful!');
    ticket.printReceipt();
  }
}