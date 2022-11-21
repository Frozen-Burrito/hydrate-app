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

enum AuthResult {
  none,
  authenticated,
  newProfileCreated,
  canSendAuthRequest,
  canLinkProfileToAccount,
  canFetchProfileSettings,
  credentialsError,
  serviceUnavailable,
}

enum UsernameError { 
  none,
  noUsernameProvided,
  noEmailProvided,
  incorrectEmailFormat,
  usernameTooShort,
  usernameTooLong,
  incorrectUsernameFormat,
}

enum PasswordError { 
  none,
  noPasswordProvided,
  passwordTooShort,
  passwordTooLong,
  requiresSymbols,
  noPasswordConfirm,
  passwordsDoNotMatch,
}
