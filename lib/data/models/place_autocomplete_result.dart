class PlaceAutocompleteResult {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;
  
  PlaceAutocompleteResult({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
  });
  
  factory PlaceAutocompleteResult.fromJson(Map<String, dynamic> json) {
    final structuredFormatting = json['structured_formatting'] as Map<String, dynamic>? ?? {};
    
    return PlaceAutocompleteResult(
      placeId: json['place_id'] as String? ?? '',
      description: json['description'] as String? ?? '',
      mainText: structuredFormatting['main_text'] as String? ?? '',
      secondaryText: structuredFormatting['secondary_text'] as String? ?? '',
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'place_id': placeId,
      'description': description,
      'structured_formatting': {
        'main_text': mainText,
        'secondary_text': secondaryText,
      },
    };
  }
} 