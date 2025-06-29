import 'dart:convert';
import 'package:pointeur_app/bloc/backend_repository_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BackendRepositoryInternalStorage<T> implements IRepository<T> {
  final String _storageKey;
  final T Function(Map<String, dynamic>) _fromJson;
  final Map<String, dynamic> Function(T) _toJson;
  final String Function(T) _getId;

  BackendRepositoryInternalStorage({
    required String storageKey,
    required T Function(Map<String, dynamic>) fromJson,
    required Map<String, dynamic> Function(T) toJson,
    required String Function(T) getId,
  }) : _storageKey = storageKey,
       _fromJson = fromJson,
       _toJson = toJson,
       _getId = getId;

  @override
  Future<List<T>> fetchAll() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);

    if (jsonString == null) return [];

    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => _fromJson(json)).toList();
  }

  @override
  Future<T?> fetchById(String id) async {
    final items = await fetchAll();
    try {
      return items.firstWhere((item) => _getId(item) == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<T> create(T data) async {
    final items = await fetchAll();
    items.add(data);
    await _saveItems(items);
    return data;
  }

  @override
  Future<T> update(T data) async {
    final items = await fetchAll();
    final index = items.indexWhere((item) => _getId(item) == _getId(data));

    if (index == -1) {
      throw Exception('Item not found');
    }

    items[index] = data;
    await _saveItems(items);
    return data;
  }

  @override
  Future<void> delete(String id) async {
    final items = await fetchAll();
    items.removeWhere((item) => _getId(item) == id);
    await _saveItems(items);
  }

  Future<void> _saveItems(List<T> items) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = items.map((item) => _toJson(item)).toList();
    await prefs.setString(_storageKey, json.encode(jsonList));
  }
}
