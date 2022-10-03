/// Un intervalo de dos números, que permite comparar otros valores para 
/// saber si están dentro del rango (exclusivo).
class Range implements Comparable {

  const Range({
    this.min = 0, 
    this.max = 0,
  });

  final num min;
  final num max;

  /// Compara este rango con [other], un objeto. Retorna un número de la misma
  /// manera que un [Comparator].
  /// 
  /// Si [other] es un [num], este método retorna un número negativo si [num] es 
  /// menor que el límite inferior del rango y un número positivo si [num] 
  /// excede el límite superior. Si [num] está dentro del rango, este método 
  /// retorna 0.
  @override
  int compareTo(other) {

    int order = 0;

    if (other is Range) {
      return 0;
    } else if (other is num) {
      // Compare upper and lower to other using absolute differences. 
      if (other < min) {
        order = -1;
      } else if (other > max) {
        order = 1;
      }
    }

    return order;
  }

  @override
  String toString() => "Range: ($min, $max)";

  @override
  bool operator==(covariant Range other) {

    final areMinLimitsEqual = min == other.min;
    final areMaxLimitsEqual = max == other.max;

    return areMinLimitsEqual && areMaxLimitsEqual;
  }

  @override
  int get hashCode => Object.hashAll([
    min, max,
  ]);
}