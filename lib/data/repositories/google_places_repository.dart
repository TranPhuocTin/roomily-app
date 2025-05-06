import 'package:roomily/data/models/place_autocomplete_result.dart';
import 'package:roomily/data/models/place_details.dart';

abstract class GooglePlacesRepository {
  Future<List<PlaceAutocompleteResult>> getPlaceAutocomplete(String input);
  Future<PlaceDetails?> getPlaceDetails(String placeId);
  Future<PlaceDetails?> reverseGeocode(double latitude, double longitude);
} 