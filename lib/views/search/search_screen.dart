import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/place.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/place_visuals.dart';
import '../../viewmodels/places_view_model.dart';
import '../place_detail/place_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  List<Place> _filter(List<Place> places) {
    if (_query.isEmpty) return [];
    final q = _query.toLowerCase();
    return places.where((p) {
      return p.name.toLowerCase().contains(q) ||
          p.address.toLowerCase().contains(q) ||
          p.type.label.toLowerCase().contains(q) ||
          p.ambianceTags.any((t) => t.toLowerCase().contains(q)) ||
          p.cuisineTags.any((t) => t.toLowerCase().contains(q)) ||
          p.styleTags.any((t) => t.toLowerCase().contains(q));
    }).take(30).toList();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.read<PlacesViewModel>();
    final results = _filter(vm.allPlaces);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Bar, restaurant, Marais...',
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 4),
          ),
          onChanged: (v) => setState(() => _query = v),
        ),
        actions: [
          if (_query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _ctrl.clear();
                setState(() => _query = '');
              },
            ),
        ],
      ),
      body: _query.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.search, size: 56, color: Colors.black26),
                  const SizedBox(height: 12),
                  Text('Tapez pour chercher un lieu',
                      style: AppTypography.caption),
                ],
              ),
            )
          : results.isEmpty
              ? Center(
                  child: Text('Aucun résultat pour "$_query"',
                      style: AppTypography.caption),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: results.length,
                  itemBuilder: (_, i) {
                    final p = results[i];
                    final color = PlaceVisuals.color(p.type);
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: color.withValues(alpha: 0.15),
                        child:
                            Icon(PlaceVisuals.icon(p.type), color: color, size: 20),
                      ),
                      title: Text(p.name,
                          style: AppTypography.body
                              .copyWith(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        '${p.type.label} · ${p.address}',
                        style: AppTypography.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star,
                              color: AppColors.rating, size: 14),
                          const SizedBox(width: 2),
                          Text('${p.rating}',
                              style: AppTypography.caption.copyWith(
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => PlaceDetailScreen(place: p)),
                      ),
                    );
                  },
                ),
    );
  }
}
