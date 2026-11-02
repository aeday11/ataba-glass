import 'package:flutter/foundation.dart';

import '../data/iraq_locations.dart';
import 'store_provider.dart';

/// الموقع المختار من محافظات العراق — يحكم حساب المواقيت والقبلة.
class LocationProvider extends ChangeNotifier {
  LocationProvider(this._store)
      : _current = governorateById(_store.governorateId) ??
            iraqGovernorates.first;

  final StoreProvider _store;
  Governorate _current;

  /// المحافظة الحالية (كربلاء افتراضياً حتى يختار المستخدم).
  Governorate get current => _current;

  /// اختيار محافظة جديدة وحفظها.
  void select(Governorate governorate) {
    if (governorate.id == _current.id) return;
    _current = governorate;
    _store.saveGovernorateId(governorate.id);
    notifyListeners();
  }
}
