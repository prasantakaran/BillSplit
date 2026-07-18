import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/models/bill_item.dart';

/// Holds the draft bill through the temporary Scan -> Edit -> Assign ->
/// Settle flow.
///
/// This is the app's single ChangeNotifier, per the architecture: multiple
/// screens mutate and observe one evolving draft, so a shared notifier is
/// the right tool. It is reset when a new scan starts.
class BillFlowState extends ChangeNotifier {
  static const Uuid _uuid = Uuid();

  String _restaurantName = '';
  List<BillItem> _items = [];
  double _taxAmount = 0;
  double? _detectedTotal;

  String get restaurantName => _restaurantName;
  List<BillItem> get items => List.unmodifiable(_items);
  double get taxAmount => _taxAmount;

  /// The grand total printed on the scanned bill, if OCR found one.
  double? get detectedTotal => _detectedTotal;

  double get subtotal => _items.fold(0, (sum, item) => sum + item.price);
  double get grandTotal => subtotal + _taxAmount;

  bool get hasItems => _items.isNotEmpty;

  /// True when every item has at least one friend assigned.
  bool get allItemsAssigned =>
      _items.isNotEmpty && _items.every((item) => item.isAssigned);

  /// Seeds the flow from parser output (or an empty draft for manual entry).
  void startNewBill({
    List<BillItem> items = const [],
    double taxAmount = 0,
    double? detectedTotal,
    String restaurantName = '',
  }) {
    _items = items
        .map((item) => item.copyWith(id: _uuid.v4()))
        .toList(growable: true);
    _taxAmount = taxAmount;
    _detectedTotal = detectedTotal;
    _restaurantName = restaurantName;
    notifyListeners();
  }

  void setRestaurantName(String name) {
    _restaurantName = name.trim();
    notifyListeners();
  }

  void addItem({String name = '', double price = 0}) {
    _items.add(BillItem(id: _uuid.v4(), name: name, price: price));
    notifyListeners();
  }

  void updateItem(String id, {String? name, double? price}) {
    final int index = _items.indexWhere((item) => item.id == id);
    if (index == -1) {
      return;
    }
    _items[index] = _items[index].copyWith(name: name, price: price);
    notifyListeners();
  }

  void removeItem(String id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  void setTaxAmount(double amount) {
    _taxAmount = amount < 0 ? 0 : amount;
    notifyListeners();
  }

  /// Adds or removes [friendId] from the sharers of item [itemId].
  void toggleAssignment(String itemId, String friendId) {
    final int index = _items.indexWhere((item) => item.id == itemId);
    if (index == -1) {
      return;
    }
    final BillItem item = _items[index];
    final List<String> sharers = List.of(item.sharedByFriendIds);
    if (sharers.contains(friendId)) {
      sharers.remove(friendId);
    } else {
      sharers.add(friendId);
    }
    _items[index] = item.copyWith(sharedByFriendIds: sharers);
    notifyListeners();
  }

  /// Clears the draft once the flow completes or is abandoned.
  void reset() {
    _restaurantName = '';
    _items = [];
    _taxAmount = 0;
    _detectedTotal = null;
    notifyListeners();
  }
}
