import 'dart:convert';
import 'dart:io';

import 'repository.dart';

/// Base implementation of [Repository] using local JSON file persistence.
///
/// Features:
/// - In-memory cache for fast read and search queries.
/// - Write-through synchronization to disk on create/update/delete.
/// - Automatic directory and file creation with seed data if file is absent.
abstract class JsonRepository<T, ID> implements Repository<T, ID> {
  final String filePath;
  final List<T> _items = [];

  JsonRepository({required this.filePath}) {
    _initialize();
  }

  /// Extracts the unique ID of an entity.
  ID getId(T item);

  /// Converts a JSON map to an entity instance.
  T fromJson(Map<String, dynamic> json);

  /// Converts an entity instance to a JSON-compatible map.
  Map<String, dynamic> toJson(T item);

  /// Provides initial seed entities if the JSON file does not exist.
  List<T> getInitialSeeds() => [];

  /// Initializes the storage file: ensures directory, seeds if missing, and loads.
  void _initialize() {
    final file = File(filePath);
    if (!file.existsSync()) {
      file.parent.createSync(recursive: true);
      final seeds = getInitialSeeds();
      _items.addAll(seeds);
      _saveToFile();
    } else {
      _loadFromFile();
    }
  }

  /// Loads items from disk into the in-memory cache.
  void _loadFromFile() {
    try {
      final file = File(filePath);
      final content = file.readAsStringSync().trim();
      if (content.isEmpty) {
        _items.clear();
        return;
      }
      final dynamic decoded = jsonDecode(content);
      if (decoded is List) {
        _items.clear();
        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            _items.add(fromJson(item));
          } else if (item is Map) {
            _items.add(fromJson(Map<String, dynamic>.from(item)));
          }
        }
      }
    } catch (e) {
      print('Warning: Failed to load from $filePath: $e');
    }
  }

  /// Persists in-memory cache to disk as formatted JSON.
  void _saveToFile() {
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        file.parent.createSync(recursive: true);
      }
      final jsonList = _items.map((item) => toJson(item)).toList();
      const encoder = JsonEncoder.withIndent('  ');
      file.writeAsStringSync(encoder.convert(jsonList));
    } catch (e) {
      print('Error saving to $filePath: $e');
    }
  }

  @override
  List<T> getAll() => List.unmodifiable(_items);

  @override
  T? getById(ID id) {
    for (final item in _items) {
      if (getId(item) == id) return item;
    }
    return null;
  }

  @override
  void create(T item) {
    // If an item with this ID already exists, update it or reject
    final existingIndex = _items.indexWhere((element) => getId(element) == getId(item));
    if (existingIndex != -1) {
      _items[existingIndex] = item;
    } else {
      _items.add(item);
    }
    _saveToFile();
  }

  @override
  bool update(T item) {
    final index = _items.indexWhere((element) => getId(element) == getId(item));
    if (index == -1) return false;
    _items[index] = item;
    _saveToFile();
    return true;
  }

  @override
  bool delete(ID id) {
    final index = _items.indexWhere((element) => getId(element) == id);
    if (index == -1) return false;
    _items.removeAt(index);
    _saveToFile();
    return true;
  }

  @override
  List<T> search(bool Function(T item) predicate) {
    return _items.where(predicate).toList();
  }
}
