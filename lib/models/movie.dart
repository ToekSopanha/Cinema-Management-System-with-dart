import 'seat.dart';

class Movie {
  final String title;
  final String genre;
  final String showtime;
  final double ticketPrice;
  final List<Seat> seats;

  // 3.2 Parameterized Constructor
  Movie({
    required this.title,
    required this.genre,
    required this.showtime,
    required this.ticketPrice,
    required int totalSeats,
  }) : seats = List.generate(
          totalSeats,
          (index) => Seat.fromCode('A${index + 1}'),
        );

  // 3.3 Named Constructor
  Movie.blockbuster({
    required String title,
    required this.showtime,
  })  : title = '$title (3D IMAX)',
        genre = 'Action / Sci-Fi',
        ticketPrice = 12.50,
        seats = List.generate(
          10,
          (index) => Seat.vip(
            id: 'V${index + 1}',
            seatRow: 'V',
            seatNumber: index + 1,
          ),
        );

  // 3.4 Factory Constructor
  factory Movie.standard({
    required String title,
    required String showtime,
  }) {
    return Movie(
      title: title,
      genre: 'General',
      showtime: showtime,
      ticketPrice: 8.00,
      totalSeats: 6,
    );
  }

  int get availableSeatCount =>
      seats.where((seat) => !seat.isBooked).length;

  Seat? findAvailableSeat() {
    for (final seat in seats) {
      if (!seat.isBooked) return seat;
    }
    return null;
  }

  void displayInfo() {
    print(
      'Movie: $title | Genre: $genre | Showtime: $showtime | '
      'Price: \$${ticketPrice.toStringAsFixed(2)} | '
      'Available Seats: $availableSeatCount/${seats.length}',
    );
  }
}