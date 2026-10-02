import '../models/customer.dart';
import '../models/movie.dart';
import '../models/seat.dart';
import '../models/ticket.dart';
import 'customer_repository.dart';
import 'json_repository.dart';
import 'movie_repository.dart';

/// Repository for persistent storage and retrieval of [Ticket] booking entities.
///
/// Stores booking records in `data/bookings.json` with relational foreign keys.
class BookingRepository extends JsonRepository<Ticket, String> {
  final CustomerRepository customerRepository;
  final MovieRepository movieRepository;

  BookingRepository({
    super.filePath = 'data/bookings.json',
    required this.customerRepository,
    required this.movieRepository,
  });

  @override
  String getId(Ticket item) => item.ticketId;

  @override
  Map<String, dynamic> toJson(Ticket item) => item.toJson();

  @override
  Ticket fromJson(Map<String, dynamic> json) {
    final customerId = json['customerId'] as String;
    final movieId = json['movieId'] as String;
    final seatId = json['seatId'] as String;

    // Resolve Customer reference or fallback to archived record
    final customer = customerRepository.getById(customerId) ??
        Customer.registered(
          id: customerId,
          name: 'Archived Customer ($customerId)',
          phone: 'N/A',
          email: 'archived@cinema.com',
        );

    // Resolve Movie reference or fallback to archived record
    final movie = movieRepository.getById(movieId) ??
        Movie(
          id: movieId,
          title: 'Archived Movie ($movieId)',
          genre: 'Archived',
          showtime: 'N/A',
          ticketPrice: (json['finalPrice'] as num).toDouble(),
          totalSeats: 1,
        );

    // Resolve Seat from the movie's seats
    final seatIndex = movie.seats.indexWhere((s) => s.id == seatId);
    final Seat seat;
    if (seatIndex != -1) {
      seat = movie.seats[seatIndex];
      seat.isBooked = true;
    } else {
      seat = Seat(
        id: seatId,
        seatRow: seatId.isNotEmpty ? seatId.substring(0, 1) : 'A',
        seatNumber: 1,
        isBooked: true,
      );
    }

    return Ticket.fromJson(
      json,
      customer: customer,
      movie: movie,
      seat: seat,
    );
  }

  @override
  List<Ticket> getInitialSeeds() => [];

  @override
  void create(Ticket item) {
    super.create(item);
    // Ensure movie seat booking state is persisted to movies.json
    movieRepository.update(item.movie);
  }

  /// Get all bookings for a given customer.
  List<Ticket> getBookingsByCustomer(String customerId) {
    return search((t) => t.customer.id == customerId);
  }

  /// Get all bookings for a given movie.
  List<Ticket> getBookingsByMovie(String movieId) {
    return search((t) => t.movie.id == movieId);
  }

  /// Calculate total revenue across all bookings.
  double calculateTotalRevenue() {
    double total = 0.0;
    for (final ticket in getAll()) {
      total += ticket.finalPrice;
    }
    return total;
  }
}
