import 'package:rxdart/rxdart.dart';
import 'package:test1/src/services/usb/usb_service.dart';
import 'package:usb_serial/usb_serial.dart';

class UsbManager {
  UsbManager(this.service) {
    refreshDeviceList();
  }

  final BaseUsbService service;
  final _cachedDevice = BehaviorSubject<List<UsbDevice>>.seeded([]);
  final _cachedPort = BehaviorSubject<UsbPort?>();
  final _cachedRate = BehaviorSubject<int>.seeded(115200);

  Stream<List<UsbDevice>> get device => _cachedDevice.stream;

  UsbPort? get port => _cachedPort.valueOrNull;

  Future<void> refreshDeviceList() async {
    final devices = await service.getDeviceList();
    _cachedDevice.add(devices);
  }

  Future<UsbPort?> selectDevice() async {
    var devices = _cachedDevice.value;
    if (devices.isEmpty) {
      await refreshDeviceList();
      devices = _cachedDevice.value;
    }

    if (devices.isEmpty) {
      return null;
    }

    final port = await service.connectToDevice(
      devices.first,
      rate: _cachedRate.value,
    );

    _cachedPort.add(port);
    return port;
  }

  Future<void> sendData(String data) async {
    await service.sendData(_cachedPort.valueOrNull, data: data);
  }

  Future<void> dispose() async {
    await _cachedPort.valueOrNull?.close();
    _cachedPort.add(null);
  }
}
