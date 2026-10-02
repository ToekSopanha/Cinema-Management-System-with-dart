import '../models/customer.dart';
import '../models/movie.dart';
import '../models/seat.dart';
import '../models/ticket.dart';

class Cinema {
  final String name;
  final List<Movie> movies = [];
  final List<Customer> customers = [];
  final List<Ticket> issuedTickets = [];

  // Parameterized Constructor
  Cinema({required this.name});

  void addMovie(Movie movie) {
    movies.add(movie);
  }

  void registerCustomer(Customer customer) {
    customers.add(customer);
  }

  Ticket? bookTicket({
    required Customer customer,
    required Movie movie,
    Seat? specificSeat,
    bool isComplimentary = false,
  }) {
    final seatToBook = specificSeat ?? movie.findAvailableSeat();
    if (seatToBook == null) {
      print('Booking Failed: No available seats for "${movie.title}".');
      return null;
    }

    if (seatToBook.isBooked) {
      print('Booking Failed: Seat ${seatToBook.id} is already booked.');
      return null;
    }

    final ticketId = 'TKT-${issuedTickets.length + 101}';
    late final Ticket ticket;

    if (isComplimentary) {
      // Named Constructor usage
      ticket = Ticket.complimentary(
        ticketId: ticketId,
        customer: customer,
        movie: movie,
        seat: seatToBook,
      );
    } else {
      // Factory Constructor usage
      ticket = Ticket.issue(
        ticketId: ticketId,
        customer: customer,
        movie: movie,
        seat: seatToBook,
      );
    }

    issuedTickets.add(ticket);
    return ticket;
  }

  void showMovies() {
    print('\n================ $name: NOW SHOWING ================');
    for (int i = 0; i < movies.length; i++) {
      final m = movies[i];
      print('${i + 1}. ${m.title} [${m.genre}] | ${m.showtime} | Base Price: \$${m.ticketPrice.toStringAsFixed(2)} | Available Seats: ${m.availableSeatCount}/${m.seats.length}');
    }
  }

  void showCustomers() {
    print('\n================ REGISTERED CUSTOMERS ================');
    for (int i = 0; i < customers.length; i++) {
      final c = customers[i];
      print('${i + 1}. ${c.id} | ${c.name} | ${c.phone} | ${c.email}');
    }
  }

  void viewAllBookings() {
    if (issuedTickets.isEmpty) {
      print('\nNo tickets booked yet.');
      return;
    }

    print('\n================ ALL ISSUED TICKETS (${issuedTickets.length}) ================');
    for (final ticket in issuedTickets) {
      ticket.printReceipt();
    }
  }

  void displayCinemaSummary() {
    print('\n================ $name STATS ================');
    print('Total Movies    : ${movies.length}');
    print('Total Customers : ${customers.length}');
    print('Total Bookings  : ${issuedTickets.length}');
    double totalRevenue = 0;
    for (final t in issuedTickets) {
      totalRevenue += t.finalPrice;
    }
    print('Total Revenue   : \$${totalRevenue.toStringAsFixed(2)}');
    print('==================================================');
  }
}