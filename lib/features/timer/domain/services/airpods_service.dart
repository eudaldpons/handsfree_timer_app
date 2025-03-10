import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter/foundation.dart';

class AirPodsService {
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();
  final StreamController<AirPodsEvent> _eventController =
      StreamController<AirPodsEvent>.broadcast();

  bool _isConnected = false;
  List<BluetoothDevice> _connectedDevices = [];

  Stream<bool> get connectionStream => _connectionController.stream;
  Stream<AirPodsEvent> get eventStream => _eventController.stream;
  bool get isConnected => _isConnected;

  AirPodsService() {
    _init();
  }

  Future<void> _init() async {
    // Escuchar cambios en el estado de Bluetooth
    FlutterBluePlus.adapterState.listen((state) {
      if (state == BluetoothAdapterState.on) {
        _startScan();
      } else {
        _isConnected = false;
        _connectionController.add(false);
      }
    });

    // Escuchar dispositivos conectados
    _connectedDevices = FlutterBluePlus.connectedDevices;
    _checkForAirPods();

    // Escuchar nuevas conexiones
    FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult result in results) {
        if (_isAirPods(result.device)) {
          _connectToDevice(result.device);
        }
      }
    });
  }

  void _startScan() {
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));

    // Escanear periódicamente
    Timer.periodic(const Duration(seconds: 10), (timer) {
      if (FlutterBluePlus.isScanningNow) return;
      FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
    });
  }

  bool _isAirPods(BluetoothDevice device) {
    // Verificar si el dispositivo es AirPods basado en el nombre o ID
    final name = device.platformName.toLowerCase();
    return name.contains('airpods') ||
        name.contains('beats') ||
        name.contains('headphone') ||
        name.contains('earphone') ||
        name.contains('buds');
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      _connectedDevices.add(device);
      _isConnected = true;
      _connectionController.add(true);

      // Configurar escucha de eventos
      _setupEventListeners(device);
    } catch (e) {
      debugPrint('Error connecting to AirPods: $e');
    }
  }

  void _checkForAirPods() {
    bool hasAirPods = _connectedDevices.any(_isAirPods);
    _isConnected = hasAirPods;
    _connectionController.add(hasAirPods);

    if (hasAirPods) {
      final airPods = _connectedDevices.firstWhere(_isAirPods);
      _setupEventListeners(airPods);
    }
  }

  void _setupEventListeners(BluetoothDevice device) async {
    try {
      List<BluetoothService> services = await device.discoverServices();

      for (BluetoothService service in services) {
        for (BluetoothCharacteristic characteristic
            in service.characteristics) {
          if (characteristic.properties.notify) {
            await characteristic.setNotifyValue(true);
            characteristic.lastValueStream.listen((value) {
              _handleAirPodsEvent(value);
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error setting up AirPods event listeners: $e');
    }
  }

  void _handleAirPodsEvent(List<int> value) {
    // Interpretar los datos recibidos de los AirPods
    // Esto puede variar según el modelo específico de AirPods

    // Ejemplo simplificado:
    if (value.isNotEmpty) {
      if (value[0] == 1) {
        _eventController.add(AirPodsEvent.singleTap);
      } else if (value[0] == 2) {
        _eventController.add(AirPodsEvent.doubleTap);
      } else if (value[0] == 3) {
        _eventController.add(AirPodsEvent.longPress);
      }
    }
  }

  // Simular un evento de AirPods (para pruebas)
  void simulateAirPodsEvent(AirPodsEvent event) {
    _eventController.add(event);
  }

  void dispose() {
    _connectionController.close();
    _eventController.close();
  }
}

enum AirPodsEvent { singleTap, doubleTap, longPress }
