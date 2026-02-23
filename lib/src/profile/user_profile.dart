class UserProfile {
  final String userId;
  String? name;
  String? phoneNumber;
  String? profileImageUrl;
  List<String>? usualMarkets;
  double? rating;

  UserProfile({
    required this.userId,
    this.name,
    this.phoneNumber,
    this.profileImageUrl,
    this.usualMarkets,
    this.rating,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'usualMarkets': usualMarkets,
      'rating': rating,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      userId: map['userId'] ?? '',
      name: map['name'],
      phoneNumber: map['phoneNumber'],
      profileImageUrl: map['profileImageUrl'],
      usualMarkets: List<String>.from(map['usualMarkets'] ?? []),
      rating: map['rating']?.toDouble() ?? 0.0,
    );
  }
}
