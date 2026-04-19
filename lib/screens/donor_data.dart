/// Data model for a donor
class DonorData {
  final String name;
  final String location;
  final String distance;
  final String bloodType;
  final String avatarUrl; // asset path or network URL

  const DonorData({
    required this.name,
    required this.location,
    this.distance = '5km',
    this.bloodType = '',
    this.avatarUrl = '',
  });
}
