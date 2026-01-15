class CompanyModel {
  final int? id;
  final String name;
  final String? address;
  final String? gstin;
  final String? phone;
  final String? email;
  final String? bankDetails;
  final String? state;
  final String? stateCode;

  CompanyModel({
    this.id,
    required this.name,
    this.address,
    this.gstin,
    this.phone,
    this.email,
    this.bankDetails,
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
      'bank_details': bankDetails,
      'state': state,
      'state_code': stateCode,
    };
  }

  factory CompanyModel.fromMap(Map<String, dynamic> map) {
    return CompanyModel(
      id: map['id'],
      name: map['name'],
      address: map['address'],
      gstin: map['gstin'],
      phone: map['phone'],
      email: map['email'],
      bankDetails: map['bank_details'],
      state: map['state'],
      stateCode: map['state_code'],
    );
  }
}
