part of 'saved_qr_cubit.dart';

abstract class SavedQrState {}

class SavedQrInitial extends SavedQrState {}

class SavedQrLoading extends SavedQrState {}

abstract class SavedQrWithMessage extends SavedQrState {
  String get message;
}

class SavedQrSuccess extends SavedQrWithMessage {
  @override
  final String message;

  SavedQrSuccess(this.message);
}

class SavedQrFailure extends SavedQrWithMessage {
  @override
  final String message;

  SavedQrFailure(this.message);
}
