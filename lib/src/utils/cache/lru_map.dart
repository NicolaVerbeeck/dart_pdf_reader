class LRUMap<K, V> {
  final int size;
  final _cache = <K, V>{}; // Map literals use LinkedHashMap by default

  LRUMap(this.size);

  V? operator [](K key) {
    if (_cache.containsKey(key)) {
      // Move the accessed item to the end to mark it as most recently used
      final value = _cache.remove(key) as V;
      _cache[key] = value;
      return value;
    }
    return null;
  }

  void operator []=(K key, V value) {
    if (_cache.containsKey(key)) {
      // If the key already exists, update its value and move it to the end
      _cache.remove(key);
    } else if (_cache.length >= size) {
      // If the cache is full, remove the least recently used item (the first item)
      final firstKey = _cache.keys.first;
      _cache.remove(firstKey);
    }
    // Add the new key-value pair to the end
    _cache[key] = value;
  }

  void remove(K key) {
    _cache.remove(key);
  }

  void getOrPut(K key, V Function() put) {
    if (_cache.containsKey(key)) {
      // Move the accessed item to the end to mark it as most recently used
      final value = _cache.remove(key) as V;
      _cache[key] = value;
    } else {
      // If the key doesn't exist, add it to the end
      _cache[key] = put();
    }
  }
}
