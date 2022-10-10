
enum EntityPersitExceptionType {
  hasReachedEntityCountLimit,
  unknown,
}

class EntityPersistException implements Exception {

  const EntityPersistException(this.exceptionType, [ this.message = "" ]);

  final String message;

  final EntityPersitExceptionType exceptionType;

  @override
  String toString() {

    final strBuf = StringBuffer("EntityPersistException:");

    strBuf.writeAll(["(", exceptionType.name, ")" ]);

    if (message.isNotEmpty) {
      strBuf.writeAll([ ": ", message ]);
    }

    return strBuf.toString();
  }
}