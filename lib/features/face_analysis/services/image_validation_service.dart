// Use the original Android validator on mobile and a browser-safe validator on Web.
export 'image_validation_service_io.dart'
    if (dart.library.js_interop) 'image_validation_service_web.dart';
