class GKMasterCategory {
  final int id;
  final String title;
  final String image;

  const GKMasterCategory({
    required this.id,
    required this.title,
    required this.image,
  });

  factory GKMasterCategory.fromJson(Map<String, dynamic> json) {
    return GKMasterCategory(
      id: int.tryParse(json['id'].toString()) ?? 0,
      title: json['title']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
    );
  }
}
