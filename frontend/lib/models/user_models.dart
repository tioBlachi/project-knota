
class UserCreate {
  final String firstName;
  final String lastName;
  final String? companyName;
  final String address;
  final String email;
  final String password;

  UserCreate({
    required this.firstName,
    required this.lastName,
    this.companyName,
    required this.address,
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'company_name': companyName,
      'address': address,
      'email': email,
      'password': password,
    };
  }
} // User Create


class UserLogin {
  final String email;
  final String password;

  UserLogin({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }
}// UserLogin