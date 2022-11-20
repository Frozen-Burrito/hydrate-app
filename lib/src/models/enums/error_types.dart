enum TextLengthError {
  none,
  textIsEmptyError,
  textExceedsCharLimit,
}

enum NumericInputError {
  none,
  isNaN,
  isEmptyWhenRequired,
  isNotCompatible,
  inputIsBeforeRange,
  inputIsAfterRange,
}