import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../api/models.dart';
import '../../widgets/city_map_preview.dart';

/// Shows a searchable country picker dialog
Future<CountryDto?> showCountryPickerDialog({
  required BuildContext context,
  required List<CountryDto> countries,
}) async {
  if (countries.isEmpty) return null;

  return await showDialog<CountryDto>(
    context: context,
    builder: (ctx) {
      String query = '';
      return StatefulBuilder(
        builder: (context, setStateDialog) {
          final filtered = countries
              .where((c) => c.name.toLowerCase().contains(query.toLowerCase()))
              .toList();
          return AlertDialog(
            title: const Text('Select Country'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search country...',
                    ),
                    onChanged: (v) => setStateDialog(() => query = v),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(child: Text('No results'))
                        : ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (context, i) {
                              final c = filtered[i];
                              return ListTile(
                                title: Text(c.name),
                                onTap: () => Navigator.pop(context, c),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      );
    },
  );
}

/// Shows a searchable city picker dialog with map preview
Future<CityDto?> showCityPickerDialog({
  required BuildContext context,
  required List<CityDto> cities,
  required CountryDto selectedCountry,
  required Map<String, LatLng> cityCoords,
  required Future<LatLng?> Function(CityDto) geocodeCity,
}) async {
  if (cities.isEmpty) return null;

  return await showDialog<CityDto>(
    context: context,
    builder: (ctx) {
      String query = '';
      CityDto? hoveredCity;
      LatLng? hoveredLatLng;
      bool geocoding = false;
      
      return StatefulBuilder(
        builder: (context, setStateDialog) {
          final filtered = cities
              .where((c) => c.name.toLowerCase().contains(query.toLowerCase()))
              .toList();
          
          return AlertDialog(
            title: Text('Select City (${selectedCountry.name})'),
            content: SizedBox(
              width: 720,
              height: 520,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final showSidePreview = constraints.maxWidth >= 560;
                  
                  final listPane = Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.search),
                            hintText: 'Search city...',
                          ),
                          onChanged: (v) => setStateDialog(() => query = v),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: filtered.isEmpty
                              ? const Center(child: Text('No results'))
                              : ListView.builder(
                                  itemCount: filtered.length,
                                  itemBuilder: (context, i) {
                                    final c = filtered[i];
                                    return MouseRegion(
                                      onEnter: (_) async {
                                        setStateDialog(() {
                                          hoveredCity = c;
                                          hoveredLatLng = cityCoords[c.id];
                                          geocoding = hoveredLatLng == null;
                                        });
                                        if (hoveredLatLng == null) {
                                          final ll = await geocodeCity(c);
                                          if (ll != null) {
                                            setStateDialog(() {
                                              hoveredLatLng = ll;
                                              geocoding = false;
                                            });
                                          } else {
                                            setStateDialog(() => geocoding = false);
                                          }
                                        }
                                      },
                                      child: ListTile(
                                        title: Text(c.name),
                                        trailing: hoveredCity == c && geocoding
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child: CircularProgressIndicator(strokeWidth: 2),
                                              )
                                            : null,
                                        onTap: () => Navigator.pop(context, c),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  );

                  if (!showSidePreview) {
                    // Mobile / narrow: show list first (full height), map preview below
                    return Column(
                      children: [
                        Expanded(
                          flex: 2,
                          child: listPane,
                        ),
                        const SizedBox(height: 8),
                        if (hoveredCity != null && hoveredLatLng != null)
                          Expanded(
                            flex: 1,
                            child: CityMapPreview(
                              cityName: hoveredCity!.name,
                              center: hoveredLatLng!,
                            ),
                          )
                        else
                          Expanded(
                            flex: 1,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  'Hover over a city to preview location',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  }

                  // Desktop / wide: side-by-side
                  return Row(
                    children: [
                      SizedBox(
                        width: 320,
                        child: listPane,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: hoveredCity != null && hoveredLatLng != null
                            ? CityMapPreview(
                                cityName: hoveredCity!.name,
                                center: hoveredLatLng!,
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    'Hover over a city to preview location',
                                    style: TextStyle(color: Colors.grey.shade600),
                                  ),
                                ),
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      );
    },
  );
}
