class Customer {
  String id;
  String name;
  String phone;
  String email;

  // 3.1 Default Constructor
  Customer()
      : id = 'C000',
        name = 'Default Guest',
        phone = '000-000-0000',
        email = 'guest@cinema.com';

  // 3.2 Parameterized Constructor
  Customer.registered({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
  });

  // 3.3 Named Constructor
  Customer.vip({
    required this.id,
    required this.name,
    required this.phone,
  }) : email = '$id.vip@cinema.com';

  // 3.4 Factory Constructor
  factory Customer.fromMap(Map<String, String> map) {
    return Customer.registered(
      id: map['id'] ?? 'C999',
      name: map['name'] ?? 'Unknown Customer',
      phone: map['phone'] ?? 'N/A',
      email: map['email'] ?? 'unknown@cinema.com',
    );
  }

  void displayInfo() {
    print('Customer ID: $id | Name: $name | Phone: $phone | Email: $email');
  }
}
