import 'dart:convert';

class PlaceAnnotation {
  final String placeId;
  final String note;
  final String category;

  const PlaceAnnotation({
    required this.placeId,
    this.note = '',
    this.category = '',
  });

  bool get hasContent => note.isNotEmpty || category.isNotEmpty;

  PlaceAnnotation copyWith({String? note, String? category}) => PlaceAnnotation(
        placeId: placeId,
        note: note ?? this.note,
        category: category ?? this.category,
      );

  Map<String, dynamic> toJson() => {
        'placeId': placeId,
        'note': note,
        'category': category,
      };

  factory PlaceAnnotation.fromJson(Map<String, dynamic> json) => PlaceAnnotation(
        placeId: json['placeId'] as String,
        note: json['note'] as String? ?? '',
        category: json['category'] as String? ?? '',
      );

  static Map<String, PlaceAnnotation> decodeMap(String raw) {
    final list = (jsonDecode(raw) as List<dynamic>)
        .map((e) => PlaceAnnotation.fromJson(e as Map<String, dynamic>))
        .toList();
    return {for (final a in list) a.placeId: a};
  }

  static String encodeMap(Map<String, PlaceAnnotation> map) =>
      jsonEncode(map.values.map((a) => a.toJson()).toList());
}
