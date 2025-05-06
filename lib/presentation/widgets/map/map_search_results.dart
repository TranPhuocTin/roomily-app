import 'package:flutter/material.dart';
import 'package:roomily/data/models/place_autocomplete_result.dart';

class MapSearchResults extends StatelessWidget {
  final List<PlaceAutocompleteResult> results;
  final Function(PlaceAutocompleteResult) onResultTap;
  
  const MapSearchResults({
    super.key,
    required this.results,
    required this.onResultTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.4,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: results.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final result = results[index];
          return ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            title: Text(result.mainText),
            subtitle: Text(
              result.secondaryText, 
              maxLines: 1, 
              overflow: TextOverflow.ellipsis
            ),
            leading: const Icon(Icons.location_on, size: 20),
            onTap: () => onResultTap(result),
          );
        },
      ),
    );
  }
}

