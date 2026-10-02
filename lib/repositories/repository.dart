/// Generic repository interface defining standard CRUD operations.
abstract class Repository<T, ID> {
  /// Retrieve all entities.
  List<T> getAll();

  /// Retrieve an entity by its unique identifier.
  T? getById(ID id);

  /// Create and persist a new entity.
  void create(T item);

  /// Update an existing entity and persist changes.
  bool update(T item);

  /// Delete an entity by its unique identifier.
  bool delete(ID id);

  /// Search for entities matching a filter [predicate].
  List<T> search(bool Function(T item) predicate);
}
