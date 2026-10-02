import 'customer.dart';
import 'movie.dart';
import 'seat.dart';

class Ticket {
  final String ticketId;
  final Customer customer;
  final Movie movie;
  final Seat seat;
  final double finalPrice;
  final DateTime bookingTime;

  // 3.2 Parameterized Constructor
  Ticket({
    required this.ticketId,
    required this.customer,
    required this.movie,
    required this.seat,
    required this.finalPrice,
    DateTime? bookingTime,
  }) : bookingTime = bookingTime ?? DateTime.now();

  // 3.3 Named Constructor (Free / Promotional Ticket)
  Ticket.complimentary({
    required this.ticketId,
    required this.customer,
    required this.movie,
    required this.seat,
  })  : finalPrice = 0.0,
        bookingTime = DateTime.now() {
    seat.reserve();
  }

  // 3.4 Factory Constructor
  factory Ticket.issue({
    required String ticketId,
    required Customer customer,
    required Movie movie,
    required Seat seat,
  }) {
    if (seat.isBooked) {
      throw Exception('Seat ${seat.id} is already booked!');
    }
    seat.reserve();
    final calculatedPrice = movie.ticketPrice * seat.priceMultiplier;
    return Ticket(
      ticketId: ticketId,
      customer: customer,
      movie: movie,
      seat: seat,
      finalPrice: calculatedPrice,
    );
  }

  // ---------- JSON Persistence ----------

  /// Serialize to JSON. Stores entity IDs as foreign keys
  /// rather than embedding full objects.
  Map<String, dynamic> toJson() => {
        'ticketId': ticketId,
        'customerId': customer.id,
        'movieId': movie.id,
        'seatId': seat.id,
        'finalPrice': finalPrice,
        'bookingTime': bookingTime.toIso8601String(),
      };

  /// Deserialize from JSON with pre-resolved object references.
  /// The caller (typically [BookingRepository]) is responsible for
  /// looking up the Customer, Movie, and Seat from their repositories.
  factory Ticket.fromJson(
    Map<String, dynamic> json, {
    required Customer customer,
    required Movie movie,
    required Seat seat,
  }) {
    return Ticket(
      ticketId: json['ticketId'] as String,
      customer: customer,
      movie: movie,
      seat: seat,
      finalPrice: (json['finalPrice'] as num).toDouble(),
      bookingTime: DateTime.parse(json['bookingTime'] as String),
    );
  }

  void printReceipt() {
    print('\n================ TICKET RECEIPT ================');
    print('Ticket ID: $ticketId');
    print('Customer : ${customer.name} (${customer.id})');
    print('Movie    : ${movie.title}');
    print('Showtime : ${movie.showtime}');
    print('Seat     : ${seat.id} (Row ${seat.seatRow})');
    print('Price    : \$${finalPrice.toStringAsFixed(2)}');
    print('Issued   : ${bookingTime.toLocal()}');
    print('================================================');
  }
}