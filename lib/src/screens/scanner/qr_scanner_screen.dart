import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:test1/src/cubit/scanner/qr_scanner_cubit.dart';
import 'package:test1/src/services/usb/usb_manager.dart';
import 'package:test1/src/services/usb/usb_service.dart';

class QRScannerScreen extends StatelessWidget {
  const QRScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => QrScannerCubit(usbManager: UsbManager(UsbService())),
      child: BlocListener<QrScannerCubit, QrScannerState>(
        listener: (context, state) {
          if (state is QrScannerFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error)),
            );
          } else if (state is QrScannerSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        child: Scaffold(
          appBar: AppBar(title: const Text('Сканування QR-коду')),
          body: MobileScanner(
            onDetect: (capture) {
              final barcode = capture.barcodes.first;
              final code = barcode.rawValue;
              if (code != null) {
                context.read<QrScannerCubit>().sendToArduino(code);
                Navigator.pop(context);
              }
            },
          ),
        ),
      ),
    );
  }
}
