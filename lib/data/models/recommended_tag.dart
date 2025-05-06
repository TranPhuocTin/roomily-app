class RecommendedTag {
  final String tagName;
  final double distance;
  final String name;

  RecommendedTag({
    required this.tagName,
    required this.distance,
    required this.name,
  });

  factory RecommendedTag.fromJson(Map<String, dynamic> json) {
    return RecommendedTag(
      tagName: json['tagName'] ?? '',
      distance: (json['distance'] ?? 0.0).toDouble(),
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tagName': tagName,
      'distance': distance,
      'name': name,
    };
  }

  @override
  String toString() {
    return 'RecommendedTag(tagName: $tagName, distance: $distance, name: $name)';
  }
} 