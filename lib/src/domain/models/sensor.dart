class Sensor {
  final int? id;
  final String name;
  final String type;

  Sensor({required this.id, required this.name, required this.type});

  factory Sensor.fromJson(Map<String, dynamic> json) => Sensor(
        id: json['id'] as int?,
        name: json['name'] as String,
        type: json['type'] as String,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type,
      };
}
extension SensorCopy on Sensor{
  Sensor copyWith({int? id, String? name, String? type }) {
    return Sensor(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
    );
  }
}
