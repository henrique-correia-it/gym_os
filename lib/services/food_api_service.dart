import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../data/models/nutrition.dart';
import '../utils/text_normalize.dart';

class FoodApiService {
  static final Map<String, List<FoodItem>> _cache = {};
  static const int _maxCacheSize = 50;

  // User-Agent obrigatório para OFF não bloquear bots anónimos
  static const Map<String, String> _headers = {
    'User-Agent': 'GymOS/1.0 (Flutter; contact@gymos.app)',
    'Accept': 'application/json',
  };

  Future<List<FoodItem>> searchFood(String query) async {
    final cleanQuery = normalizeForSearch(query);
    if (cleanQuery.isEmpty) return [];

    if (_cache.containsKey(cleanQuery)) {
      debugPrint('GymOS Cache: "$cleanQuery"');
      return _cache[cleanQuery]!;
    }

    final apiQuery = cleanQuery;

    List<FoodItem> results = [];

    // 1ª tentativa: Portugal
    try {
      results = await _searchWithRetry(apiQuery, countryFilter: true);
    } catch (e) {
      debugPrint('GymOS PT falhou: $e');
    }

    // 2ª tentativa: global
    if (results.length < 5) {
      try {
        final global = await _searchWithRetry(apiQuery, countryFilter: false);
        final seen = results.map((r) => normalizeForSearch(r.name)).toSet();
        for (final item in global) {
          if (seen.add(normalizeForSearch(item.name))) results.add(item);
        }
      } catch (e) {
        if (results.isEmpty) rethrow;
        debugPrint('GymOS Global falhou, usando PT: $e');
      }
    }

    // 3ª tentativa: query mais curta (primeiras 3 palavras) se ainda poucos resultados
    if (results.length < 3) {
      final words = apiQuery.split(' ').where((w) => w.length > 2).toList();
      if (words.length > 3) {
        final shortQuery = words.take(3).join(' ');
        try {
          final short = await _searchWithRetry(shortQuery, countryFilter: true);
          final seen = results.map((r) => normalizeForSearch(r.name)).toSet();
          for (final item in short) {
            if (seen.add(normalizeForSearch(item.name))) results.add(item);
          }
        } catch (_) {}
      }
    }

    if (results.isNotEmpty) {
      _cache[cleanQuery] = results;
      if (_cache.length > _maxCacheSize) {
        _cache.remove(_cache.keys.first);
      }
    }

    return results;
  }

  Future<List<FoodItem>> _searchWithRetry(
    String query, {
    required bool countryFilter,
  }) async {
    const maxRetries = 3;

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        return await _doSearch(query, countryFilter: countryFilter);
      } on TimeoutException {
        if (attempt == maxRetries - 1) throw Exception('timeout_api');
        await Future.delayed(Duration(seconds: pow(2, attempt).toInt()));
        debugPrint('GymOS Retry ${attempt + 1} (timeout) — "$query"');
      } catch (e) {
        final msg = e.toString();
        // Não retenta para rate-limit ou erros de cliente
        if (msg.contains('rate_limit') || msg.contains('no_internet')) rethrow;
        if (attempt == maxRetries - 1) rethrow;
        await Future.delayed(Duration(seconds: pow(2, attempt).toInt()));
        debugPrint('GymOS Retry ${attempt + 1} — "$query": $msg');
      }
    }
    return [];
  }

  Future<List<FoodItem>> _doSearch(
    String query, {
    required bool countryFilter,
  }) async {
    // /cgi/search.pl é o endpoint clássico — muito mais estável que /api/v2/search
    final params = <String, String>{
      'search_terms': query,
      'action': 'process',
      'json': '1',
      'page_size': '24',
      'sort_by': 'popularity_key',
      'fields': 'product_name,generic_name,brands,nutriments',
    };

    if (countryFilter) {
      params['tagtype_0'] = 'countries';
      params['tag_contains_0'] = 'contains';
      params['tag_0'] = 'portugal';
    }

    final uri = Uri.https(
      'world.openfoodfacts.org',
      '/cgi/search.pl',
      params,
    );

    final response = await http
        .get(uri, headers: _headers)
        .timeout(const Duration(seconds: 12));

    debugPrint(
      'GymOS OFF status=${response.statusCode} country=$countryFilter query="$query"',
    );

    if (response.statusCode == 429) throw Exception('rate_limit');
    if (response.statusCode >= 500) throw Exception('server_down');
    if (response.statusCode != 200) throw Exception('no_internet');

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final products = (data['products'] as List<dynamic>?) ?? [];

    return _parseProducts(products);
  }

  List<FoodItem> _parseProducts(List<dynamic> products) {
    final Map<String, List<String>> macroRegistry = {};
    final List<FoodItem> results = [];

    for (final raw in products) {
      final product = raw as Map<String, dynamic>;

      String name = ((product['product_name'] as String?) ?? '').trim();
      final generic = ((product['generic_name'] as String?) ?? '').trim();
      final brands = ((product['brands'] as String?) ?? '').trim();

      if (name.isEmpty) name = generic;
      if (name.isEmpty && brands.isNotEmpty) name = brands;
      if (name.isEmpty) continue;

      if (brands.isNotEmpty &&
          !name.toLowerCase().contains(brands.toLowerCase())) {
        name = '$name ($brands)';
      }

      final nutriments = product['nutriments'] as Map<String, dynamic>?;
      if (nutriments == null) continue;

      final kcal = _toDouble(
        nutriments['energy-kcal_100g'] ?? nutriments['energy-kcal'],
      );
      if (kcal <= 0) continue;

      final protein = _toDouble(
        nutriments['proteins_100g'] ?? nutriments['proteins'],
      );
      final carbs = _toDouble(
        nutriments['carbohydrates_100g'] ?? nutriments['carbohydrates'],
      );
      final fat = _toDouble(nutriments['fat_100g'] ?? nutriments['fat']);

      final macroKey =
          '${kcal.round()}_${protein.round()}_${carbs.round()}_${fat.round()}';
      final normName = normalizeForSearch(name);

      bool shouldAdd = true;
      if (macroRegistry.containsKey(macroKey)) {
        for (final existing in macroRegistry[macroKey]!) {
          if (existing.contains(normName) || normName.contains(existing)) {
            shouldAdd = false;
            break;
          }
        }
      }

      if (shouldAdd) {
        macroRegistry.putIfAbsent(macroKey, () => []).add(normName);
        results.add(
          FoodItem()
            ..id = -Random().nextInt(1000000)
            ..name = name
            ..searchName = normName
            ..kcal = kcal
            ..protein = protein
            ..carbs = carbs
            ..fat = fat
            ..unit = 'g'
            ..source = 'API'
            ..isFavorite = false,
        );
      }
    }

    return results;
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}
