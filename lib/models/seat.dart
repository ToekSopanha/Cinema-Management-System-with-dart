class Seat {
  final String id;
  final String seatRow;
  final int seatNumber;
  bool isBooked;
  double priceMultiplier;

  // 3.2 Parameterized Constructor
  Seat({
    required this.id,
    required this.seatRow,
    required this.seatNumber,
    this.isBooked = false,
    this.priceMultiplier = 1.0,
  });

  // 3.3 Named Constructor
  Seat.vip({
    required this.id,
    required this.seatRow,
    required this.seatNumber,
  })  : isBooked = false,
        priceMultiplier = 1.5;

  // 3.4 Factory Constructor
  factory Seat.fromCode(String code) {
    // Example: "A1" -> row: 'A', number: 1
    final row = code.substring(0, 1).toUpperCase();
    final number = int.tryParse(code.substring(1)) ?? 1;
    return Seat(
      id: code,
      seatRow: row,
      seatNumber: number,
    );
  }

  void reserve() {
    isBooked = true;
  }

  void cancelReservation() {
    isBooked = false;
  }

  void displayInfo() {
    final status = isBooked ? 'Booked' : 'Available';
    final type = priceMultiplier > 1.0 ? 'VIP' : 'Standard';
    print('Seat $id ($seatRow-$seatNumber) | Type: $type | Status: $status');
  }
}