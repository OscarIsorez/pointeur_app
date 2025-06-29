abstract interface class IRepository<T> {
  /// Fetches all data from the backend.
  ///
  /// Returns a [Future] that resolves to a list of fetched data.
  Future<List<T>> fetchAll();

  /// Fetches a single item by its ID.
  ///
  /// Returns a [Future] that resolves to the fetched item or null if not found.
  Future<T?> fetchById(String id);

  /// Creates new data on the backend.
  ///
  /// Takes [data] as a parameter and returns a [Future] that resolves to the created item.
  Future<T> create(T data);

  /// Updates existing data on the backend.
  ///
  /// Takes [data] as a parameter and returns a [Future] that resolves to the updated item.
  Future<T> update(T data);

  /// Deletes data from the backend.
  ///
  /// Takes an [id] as a parameter and returns a [Future] that resolves when the deletion is complete.
  Future<void> delete(String id);
}
