/// Enum representing the type of a value.
enum ValueType {
  missing,
  filled,
  automaticallyGenerated,
  combined,
  typed,
  errorWhenFilled,
  missingWhenJoined,
  missingWhenTransposed,
  missingWhenCombined,
  selected,
}

/// Represents a value with its type.
class Value {
  final String value;
  final ValueType type;

  const Value(this.value, {this.type = ValueType.selected});
  const Value.missingWhenCombined()
    : this("😕", type: ValueType.missingWhenCombined);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Value &&
          runtimeType == other.runtimeType &&
          value == other.value &&
          type == other.type;

  @override
  int get hashCode => value.hashCode ^ type.hashCode;

  /// Returns a string representation of the value.
  @override
  String toString() {
    return value;
  }
}
