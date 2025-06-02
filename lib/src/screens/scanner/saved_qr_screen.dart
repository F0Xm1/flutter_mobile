import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test1/src/cubit/scanner/saved_qr_cubit.dart';
import 'package:test1/src/services/usb/usb_manager.dart';
import 'package:test1/src/services/usb/usb_service.dart';

class SavedQrScreen extends StatelessWidget {
  const SavedQrScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SavedQrCubit(
        usbManager: UsbManager(UsbService()),
      )..readFromArduino(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Збережене повідомлення')),
        body: BlocBuilder<SavedQrCubit, SavedQrState>(
          builder: (context, state) {
            String text = 'Очікування...';

            if (state is SavedQrLoading) {
              text = 'Зчитування...';
            } else if (state is SavedQrWithMessage) {
              text = state.message;
            }

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  text,
                  style: const TextStyle(fontSize: 20),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
