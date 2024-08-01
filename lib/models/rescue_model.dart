class Rescue {
  final String rescue_id;
  final String title;
  final String email;
  final String desc;
  final String date;
  final String image;
  final String location;
  final String phone;

  Rescue({
    required this.rescue_id,
    required this.title,
    required this.email,
    required this.desc,
    required this.date,
    required this.image,
    required this.location,
    required this.phone,
  });

  // Factory constructor for instantiating a new Event from a map structure
  factory Rescue.fromJson(Map<String, dynamic> json) {
    return Rescue(
      rescue_id: json['rescue_id'] as String,
      title: json['title'] as String,
      email: json['email'] as String,
      desc: json['desc'] as String,
      date: json['date'] as String,
      image: json['image'] as String,
      location: json['location'] as String,
      phone: json['phone'] as String,
    );
  }

  // Converts a Event instance into a map
  Map<String, dynamic> toJson() {
    return {
      'rescue_id': rescue_id,
      'title': title,
      'email': email,
      'desc': desc,
      'date': date,
      'image': image,
      'location': location,
      'phone': phone,
    };
  }

  // Creates a copy of the current event with updated fields
  Rescue copyWith({
    String? rescue_id,
    String? title,
    String? email,
    String? desc,
    String? date,
    String? image,
    String? location,
    String? phone,
  }) {
    return Rescue(
      rescue_id: rescue_id ?? this.rescue_id,
      title: title ?? this.title,
      email: email ?? this.email,
      desc: desc ?? this.desc,
      date: date ?? this.date,
      image: image ?? this.image,
      location: location ?? this.location,
      phone: phone ?? this.phone,
    );
  }
}
