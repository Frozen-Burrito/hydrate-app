class ValidationError<T> {

  final String fieldName;

  final T currentValue;
  final T? expectedValue;

  ValidationError(this.fieldName, this.currentValue, this.expectedValue);
}