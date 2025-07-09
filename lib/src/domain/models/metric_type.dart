enum MetricType {
  temperature,
  pressure,
  humidity;

  static MetricType? fromString(String? value) {
    switch (value) {
      case 'temperature':
        return MetricType.temperature;
      case 'pressure':
        return MetricType.pressure;
      case 'humidity':
        return MetricType.humidity;
      default:
        return null;
    }
  }

  String toShortString() => name;
}
