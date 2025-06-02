part of 'qr_scanner_cubit.dart';

abstract class QrScannerState {}

class QrScannerInitial extends QrScannerState {}

class QrScannerSending extends QrScannerState {}

class QrScannerSuccess extends QrScannerState {
  final String message;

  QrScannerSuccess(this.message);
}

class QrScannerFailure extends QrScannerState {
  final String error;

  QrScannerFailure(this.error);
}
