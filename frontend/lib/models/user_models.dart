
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


class UserPublic {
  final int id;
  final String joinDate;

  UserPublic({
    required this.id,
    required this.joinDate
  });

  factory UserPublic.fromJson(Map<String, dynamic> json) {
    return UserPublic(
      id: json['id'] is String ? int.parse(json['id']) : json['id'],
      joinDate: json['join_date'],
      );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'join_date': joinDate,
    };
  }
} // UserPublic
