import '../models/customer.dart';
import '../models/movie.dart';
import '../models/seat.dart';
import '../models/ticket.dart';
import '../repositories/booking_repository.dart';
import '../repositories/customer_repository.dart';
import '../repositories/movie_repository.dart';
import 'auth_service.dart';

/// The main cinema system coordinating business logic across repositories:
/// - [MovieRepository] for movie schedules and seat statuses
/// - [CustomerRepository] for patron profiles
/// - [BookingRepository] for ticket issuance and revenue
/// - [AuthService] for authentication and role-based guards
class Cinema {
  final String name;
  final AuthService auth;
  final MovieRepository movieRepository;
  final CustomerRepository customerRepository;
  final BookingRepository bookingRepository;

  Cinema({
    required this.name,
    required this.auth,
    MovieRepository? movieRepository,
    CustomerRepository? customerRepository,
    BookingRepository? bookingRepository,
  })  : movieRepository = movieRepository ?? MovieRepository(),
        customerRepository = customerRepository ?? CustomerRepository(),
        bookingRepository = bookingRepository ??
            BookingRepository(
              customerRepository: customerRepository ?? CustomerRepository(),
              movieRepository: movieRepository ?? MovieRepository(),
            );

  // ======================== Entity Accessors ========================

  List<Movie> get movies => movieRepository.getAll();
  List<Customer> get customers => customerRepository.getAll();
  List<Ticket> get issuedTickets => bookingRepository.getAll();

  // ======================== Seed Methods (No Auth) ========================
  // Used for pre-population or migration if needed.

  void seedMovie(Movie movie) => movieRepository.create(movie);
  void seedCustomer(Customer customer) => customerRepository.create(customer);

  // ======================== Admin-Guarded Operations ========================

  /// Add a movie to the catalog and persist to storage.
  /// **Guarded:** requires Admin role.
  bool addMovie(Movie movie) {
    if (!auth.requireAdmin()) return false;
    movieRepository.create(movie);
    print('Movie "${movie.title}" added successfully.');
    return true;
  }

  /// Remove a movie by list index and persist to storage.
  /// **Guarded:** requires Admin role.
  bool removeMovie(int index) {
    if (!auth.requireAdmin()) return false;

    final all = movieRepository.getAll();
    if (index < 0 || index >= all.length) {
      print('Invalid movie selection.');
      return false;
    }

    final movie = all[index];
    final activeBookings = bookingRepository.getBookingsByMovie(movie.id);
    if (activeBookings.isNotEmpty) {
      print(
        'Note: "${movie.title}" has ${activeBookings.length} booking(s). '
        'Removing movie from catalog.',
      );
    }

    final success = movieRepository.delete(movie.id);
    if (success) {
      print('Movie "${movie.title}" removed successfully.');
    }
    return success;
  }

  // ======================== Staff-Level Operations ========================

  /// Register a new customer and persist to storage.
  /// **Guarded:** requires authentication.
  void registerCustomer(Customer customer) {
    if (!auth.requireAuth()) return;
    customerRepository.create(customer);
  }

  /// Book a ticket for a customer on a specific movie/seat.
  /// Persists ticket to bookings.json and updates seat status in movies.json.
  /// **Guarded:** requires authentication.
  Ticket? bookTicket({
    required Customer customer,
    required Movie movie,
    Seat? specificSeat,
    bool isComplimentary = false,
  }) {
    if (!auth.requireAuth()) return null;

    final seatToBook = specificSeat ?? movie.findAvailableSeat();
    if (seatToBook == null) {
      print('Booking Failed: No available seats for "${movie.title}".');
      return null;
    }

    if (seatToBook.isBooked) {
      print('Booking Failed: Seat ${seatToBook.id} is already booked.');
      return null;
    }

    final ticketId = 'TKT-${bookingRepository.getAll().length + 101}';
    late final Ticket ticket;

    if (isComplimentary) {
      ticket = Ticket.complimentary(
        ticketId: ticketId,
        customer: customer,
        movie: movie,
        seat: seatToBook,
      );
    } else {
      ticket = Ticket.issue(
        ticketId: ticketId,
        customer: customer,
        movie: movie,
        seat: seatToBook,
      );
    }

    // Persist ticket; BookingRepository also triggers movieRepository.update()
    bookingRepository.create(ticket);
    return ticket;
  }

  // ======================== Read Operations ========================

  /// Display all movies currently in the repository.
  /// **Guarded:** requires authentication.
  void showMovies() {
    if (!auth.requireAuth()) return;

    final currentMovies = movieRepository.getAll();
    print('\n================ $name: NOW SHOWING ================');
    if (currentMovies.isEmpty) {
      print('  No movies currently showing.');
    } else {
      for (int i = 0; i < currentMovies.length; i++) {
        final m = currentMovies[i];
        print(
          '${i + 1}. ${m.title} [${m.genre}] | ${m.showtime} | '
          'Base Price: \$${m.ticketPrice.toStringAsFixed(2)} | '
          'Available Seats: ${m.availableSeatCount}/${m.seats.length}',
        );
      }
    }
  }

  /// Display all registered customers.
  /// **Guarded:** requires authentication.
  void showCustomers() {
    if (!auth.requireAuth()) return;

    final currentCustomers = customerRepository.getAll();
    print('\n================ REGISTERED CUSTOMERS ================');
    if (currentCustomers.isEmpty) {
      print('  No customers registered.');
    } else {
      for (int i = 0; i < currentCustomers.length; i++) {
        final c = currentCustomers[i];
        print('${i + 1}. ${c.id} | ${c.name} | ${c.phone} | ${c.email}');
      }
    }
  }

  /// Display receipts for all issued tickets.
  /// **Guarded:** requires authentication.
  void viewAllBookings() {
    if (!auth.requireAuth()) return;

    final tickets = bookingRepository.getAll();
    if (tickets.isEmpty) {
      print('\nNo tickets booked yet.');
      return;
    }

    print('\n================ ALL ISSUED TICKETS (${tickets.length}) ================');
    for (final ticket in tickets) {
      ticket.printReceipt();
    }
  }

  /// Display cinema-wide statistics and total revenue.
  /// **Guarded:** requires authentication.
  void displayCinemaSummary() {
    if (!auth.requireAuth()) return;

    final totalMovies = movieRepository.getAll().length;
    final totalCustomers = customerRepository.getAll().length;
    final totalBookings = bookingRepository.getAll().length;
    final totalRevenue = bookingRepository.calculateTotalRevenue();

    print('\n================ $name STATS ================');
    print('Total Movies    : $totalMovies');
    print('Total Customers : $totalCustomers');
    print('Total Bookings  : $totalBookings');
    print('Total Revenue   : \$${totalRevenue.toStringAsFixed(2)}');
    print('==================================================');
  }
}