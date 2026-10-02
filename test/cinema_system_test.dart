import 'package:cinema_system/cinema_system.dart';
import 'package:test/test.dart';

void main() {
  group('Cinema System Tests', () {
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

    test('Cinema books ticket and reserves seat correctly', () {
      final cinema = Cinema(name: 'Major Cineplex');
      final movie = Movie.standard(title: 'Batman', showtime: '18:00');
      final customer = Customer();

      cinema.addMovie(movie);
      final ticket = cinema.bookTicket(customer: customer, movie: movie);

      expect(ticket, isNotNull);
      expect(ticket?.movie.title, 'Batman');
      expect(ticket?.seat.isBooked, isTrue);
      expect(cinema.issuedTickets.length, 1);
    });
  });
}
