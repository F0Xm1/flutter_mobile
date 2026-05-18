part of 'profile_cubit.dart';

abstract class ProfileState {
  const ProfileState();
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final int locationCount;
  final int sensorCount;
  final int todayEventCount;

  const ProfileLoaded({
    required this.locationCount,
    required this.sensorCount,
    required this.todayEventCount,
  });
}

class ProfileError extends ProfileState {
  final String message;

  const ProfileError(this.message);
}
