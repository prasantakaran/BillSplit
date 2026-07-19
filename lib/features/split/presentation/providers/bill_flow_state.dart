import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/models/bill_item.dart';
import '../../../../core/models/tax_line.dart';

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
  List<TaxLine> _taxLines = const [];
  double? _detectedTotal;
  double? _detectedSubtotal;

  String get restaurantName => _restaurantName;
  List<BillItem> get items => List.unmodifiable(_items);
  double get taxAmount => _taxAmount;

  /// The grand total printed on the scanned bill, if OCR found one.
  double? get detectedTotal => _detectedTotal;

  /// The pre-tax subtotal printed on the scanned bill, if OCR found one.
  double? get detectedSubtotal => _detectedSubtotal;

  /// The tax/charge lines printed on the scanned bill (CGST, SGST, service
  /// charge, ...); display-only breakdown of the editable [taxAmount].
  List<TaxLine> get taxLines => List.unmodifiable(_taxLines);

  /// True when the printed subtotal exists but the current items don't sum
  /// to it — a sign that some prices still need a manual check.
  bool get subtotalMismatch =>
      _detectedSubtotal != null && (subtotal - _detectedSubtotal!).abs() > 0.01;

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
    List<TaxLine> taxLines = const [],
    double? detectedTotal,
    double? detectedSubtotal,
    String restaurantName = '',
  }) {
    _items = items
        .map((item) => item.copyWith(id: _uuid.v4()))
        .toList(growable: true);
    _taxAmount = taxAmount;
    _taxLines = taxLines;
    _detectedTotal = detectedTotal;
    _detectedSubtotal = detectedSubtotal;
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

  /// Adds an empty tax/charge line for the user to fill in.
  void addTaxLine({String label = '', double amount = 0}) {
    _taxLines = List.of(_taxLines)..add(TaxLine(label: label, amount: amount));
    _recomputeTaxAmount();
  }

  void updateTaxLine(int index, {String? label, double? amount}) {
    if (index < 0 || index >= _taxLines.length) {
      return;
    }
    final TaxLine current = _taxLines[index];
    final List<TaxLine> lines = List.of(_taxLines);
    lines[index] = TaxLine(
      label: label ?? current.label,
      amount: amount ?? current.amount,
    );
    _taxLines = lines;
    _recomputeTaxAmount();
  }

  void removeTaxLine(int index) {
    if (index < 0 || index >= _taxLines.length) {
      return;
    }
    _taxLines = List.of(_taxLines)..removeAt(index);
    _recomputeTaxAmount();
  }

  /// The total tax is always the sum of the editable tax lines.
  void _recomputeTaxAmount() {
    _taxAmount = _taxLines.fold(0, (sum, tax) => sum + tax.amount);
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
    _taxLines = const [];
    _detectedTotal = null;
    _detectedSubtotal = null;
    notifyListeners();
  }
}
