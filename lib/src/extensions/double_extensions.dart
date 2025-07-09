extension TemperatureConversion on double {
  int get toFahrenheit => ((this * 9) / 5 + 32).round();
}
