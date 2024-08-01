class User {
  final String name;
  final String email;
  final String phone;
  final String image;
  // final String dob;

  User({
    required this.name,
    required this.email,
    required this.phone,
    required this.image,
    // required this.dob
  });

  // Factory constructor for instantiating a new User from a map structure
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      image: json['image'] as String,
      // dob: json['dob'] as String
    );
  }

  // Converts a User instance into a map
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'image': image,
      // 'dob': dob
    };
  }

  // Creates a copy of the current user with updated fields
  User copyWith(
      {String? name,
      String? email,
      String? phone,
      String? image,
      String? dob}) {
    return User(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      image: image ?? this.image,
      // dob: dob ?? this.dob
    );
  }
}
