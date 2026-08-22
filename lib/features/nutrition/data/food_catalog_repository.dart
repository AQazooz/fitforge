import 'package:supabase_flutter/supabase_flutter.dart';

class FoodCatalogRepository {
  FoodCatalogRepository(this._client);

  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> search(String query) async {
    final clean = query.trim();
    final request = _client
        .from('food_catalog')
        .select('id, name, category, serving_size, calories, protein_g, carbs_g, fat_g, fiber_g')
        .eq('is_active', true);

    final data = clean.isEmpty
        ? await request.order('name').limit(50)
        : await request.ilike('name', '%$clean%').order('name').limit(50);
    return List<Map<String, dynamic>>.from(data);
  }
}
