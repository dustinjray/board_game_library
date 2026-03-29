class Optional<T> {
  final T? value;
  final bool isPresent;

  const Optional.absent()
    : value = null,
      isPresent = false;

  const Optional.of(this.value) : isPresent = true;
}