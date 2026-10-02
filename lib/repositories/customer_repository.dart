import '../models/customer.dart';
import 'json_repository.dart';

/// Repository for persistent storage and retrieval of [Customer] entities.
///
/// Stores customer records in `data/customers.json`.
class CustomerRepository extends JsonRepository<Customer, String> {
  CustomerRepository({super.filePath = 'data/customers.json'});

  @override
  String getId(Customer item) => item.id;

  @override
  Customer fromJson(Map<String, dynamic> json) => Customer.fromJson(json);

  @override
  Map<String, dynamic> toJson(Customer item) => item.toJson();

  @override
  List<Customer> getInitialSeeds() {
    return [
      Customer(),
      Customer.registered(
        id: 'C101',
        name: 'Sophea Chan',
        phone: '012-345-678',
        email: 'sophea@gmail.com',
      ),
      Customer.vip(
        id: 'VIP001',
        name: 'Vannak Heng',
        phone: '099-888-777',
      ),
      Customer.fromMap({
        'id': 'C102',
        'name': 'Dara Sok',
        'phone': '077-111-222',
        'email': 'dara@gmail.com',
      }),
    ];
  }

  /// Search customers whose name contains [query] (case-insensitive).
  List<Customer> searchByName(String query) {
    final lower = query.toLowerCase();
    return search((c) => c.name.toLowerCase().contains(lower));
  }

  /// Find customer by phone number.
  Customer? findByPhone(String phone) {
    final results = search((c) => c.phone == phone);
    return results.isNotEmpty ? results.first : null;
  }
}
