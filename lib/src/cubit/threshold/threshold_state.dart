part of 'threshold_cubit.dart';

abstract class ThresholdState {
  const ThresholdState();
}

class ThresholdInitial extends ThresholdState {
  const ThresholdInitial();
}

class ThresholdLoading extends ThresholdState {
  const ThresholdLoading();
}

class ThresholdLoaded extends ThresholdState {
  final double? min;
  final double? max;

  const ThresholdLoaded({this.min, this.max});
}

class ThresholdError extends ThresholdState {
  final String message;

  const ThresholdError(this.message);
}
