class CustomerModel {
  final int? id;
  final String name;
  final String? address;
  final String? gstin;
  final String? phone;
  final String? email;
  final String? state;
  final String? stateCode;

  CustomerModel({
    this.id,
    required this.name,
    this.address,
    this.gstin,
    this.phone,
    this.email,
    this.state,
    this.stateCode,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'gstin': gstin,
      'phone': phone,
      'email': email,
      'state': state,
      'state_code': stateCode,
    };
  }

  factory CustomerModel.fromMap(Map<String, dynamic> map) {
    return CustomerModel(
      id: map['id'],
      name: map['name'],
      address: map['address'],
      gstin: map['gstin'],
      phone: map['phone'],
      email: map['email'],
      state: map['state'],
      stateCode: map['state_code'],
    );
  }
}
