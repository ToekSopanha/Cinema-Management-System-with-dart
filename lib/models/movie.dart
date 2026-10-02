import 'seat.dart';

class Movie {
  final String id;
  final String title;
  final String genre;
  final String showtime;
  final double ticketPrice;
  final List<Seat> seats;

  /// Generates a unique movie ID using a microsecond timestamp.
  static String _generateId() =>
      'MOV-${DateTime.now().microsecondsSinceEpoch}';

  // 3.2 Parameterized Constructor
  Movie({
    String? id,
    required this.title,
    required this.genre,
    required this.showtime,
    required this.ticketPrice,
    required int totalSeats,
  })  : id = id ?? _generateId(),
        seats = List.generate(
          totalSeats,
          (index) => Seat.fromCode('A${index + 1}'),
        );

  // 3.3 Named Constructor
  Movie.blockbuster({
    String? id,
    required String title,
    required this.showtime,
  })  : id = id ?? _generateId(),
        title = '$title (3D IMAX)',
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
    String? id,
    required String title,
    required String showtime,
  }) {
    return Movie(
      id: id,
      title: title,
      genre: 'General',
      showtime: showtime,
      ticketPrice: 8.00,
      totalSeats: 6,
    );
  }

  /// Private constructor used by [fromJson] (accepts a pre-built seat list).
  Movie._fromData({
    required this.id,
    required this.title,
    required this.genre,
    required this.showtime,
    required this.ticketPrice,
    required this.seats,
  });

  // ---------- JSON Persistence ----------

  /// Serialize this movie (including all seats) to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'genre': genre,
        'showtime': showtime,
        'ticketPrice': ticketPrice,
        'seats': seats.map((s) => s.toJson()).toList(),
      };

  /// Deserialize a movie from a JSON map.
  factory Movie.fromJson(Map<String, dynamic> json) {
    final seatsList = (json['seats'] as List)
        .map((s) => Seat.fromJson(s as Map<String, dynamic>))
        .toList();
    return Movie._fromData(
      id: json['id'] as String,
      title: json['title'] as String,
      genre: json['genre'] as String,
      showtime: json['showtime'] as String,
      ticketPrice: (json['ticketPrice'] as num).toDouble(),
      seats: seatsList,
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