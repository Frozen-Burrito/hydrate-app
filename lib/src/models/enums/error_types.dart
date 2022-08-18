enum TextLengthError {
  none,
  textIsEmptyError,
  textExceedsCharLimit,
}

enum NumericInputError {
  none,
  isNaN,
  isNotCompatible,
  inputIsBeforeRange,
  inputIsAfterRange,
}