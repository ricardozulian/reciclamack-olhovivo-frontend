import 'totem_camera_adapter_stub.dart'
    if (dart.library.js_interop) 'totem_camera_adapter_web.dart'
    as implementation;
import 'totem_camera_adapter_types.dart';

TotemCameraAdapter createTotemCameraAdapter() =>
    implementation.createTotemCameraAdapter();
