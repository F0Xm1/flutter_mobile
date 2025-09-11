import 'package:test1/src/domain/models/metric_type.dart';

class StationArgs {
  final String stationId;
  final MetricType? metric;

  StationArgs(this.stationId, {this.metric});
}
