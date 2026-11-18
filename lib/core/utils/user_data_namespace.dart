class UserDataNamespace {
  UserDataNamespace._();

  static String sanitizeUserId(String userId) =>
      userId.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');

  static String localCollection(String collectionName, String? userId) {
    if (userId == null || userId.isEmpty) return collectionName;
    return 'user_${sanitizeUserId(userId)}_$collectionName';
  }

  static String secureStorageKey(String key, String? userId) {
    if (userId == null || userId.isEmpty) return key;
    return 'user_${sanitizeUserId(userId)}_$key';
  }
}
