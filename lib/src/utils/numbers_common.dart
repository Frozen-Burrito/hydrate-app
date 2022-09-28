/// El número retornado tendrá un valor dentro del rango [min] <= [number] <= [max].
int constrain(int number, { int? min, int? max }) {

  if (min != null && max != null && min > max) {
    int temp = min;
    min = max;
    max = temp;
  }

  final int minValue = min ?? number;
  final int maxValue = max ?? number;

  if (number > maxValue) {
    return maxValue;
  } else if (number < minValue) {
    return minValue;
  } else {
    return number;
  }
}