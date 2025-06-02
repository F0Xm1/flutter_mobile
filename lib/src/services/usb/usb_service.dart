import 'package:flutter/foundation.dart';
import 'package:usb_serial/usb_serial.dart';

abstract class BaseUsbService {
  Future<List<UsbDevice>> getDeviceList();

  Future<UsbPort?> connectToDevice(UsbDevice device, {int rate = 115200});

  Future<void> sendData(UsbPort? port, {required String data});
}

class UsbService extends BaseUsbService {
  @override
  Future<List<UsbDevice>> getDeviceList() async {
    return await UsbSerial.listDevices();
  }

  @override
  Future<UsbPort?> connectToDevice(
    UsbDevice device, {
    int rate = 115200,
  }) async {
    final port = await device.create();
    final bool openResult = await port?.open() ?? false;
    if (!openResult) {
      debugPrint('❌ Не вдалося відкрити порт');
      return null;
    }

    await port?.setDTR(true);
    await port?.setRTS(true);
    await port?.setPortParameters(
      rate,
      UsbPort.DATABITS_8,
      UsbPort.STOPBITS_1,
      UsbPort.PARITY_NONE,
    );

    return port;
  }

  @override
  Future<void> sendData(UsbPort? port, {required String data}) async {
    if (port != null) {
      await port.write(Uint8List.fromList(data.codeUnits));
    }
  }
}
