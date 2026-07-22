import 'package:bill_split/core/models/bill_item.dart';
import 'package:bill_split/core/models/tax_line.dart';
import 'package:equatable/equatable.dart';

class ParsedBill extends Equatable {
  final List<BillItem> items;

  final double taxAmount;

  final List<TaxLine> taxLines;

  final double? detectedTotal;

  final double? detectedSubtotal;
  const ParsedBill({
    required this.items,
    required this.taxAmount,
    this.taxLines = const [],
    this.detectedTotal,
    this.detectedSubtotal,
  });

  @override
  List<Object?> get props => [
    items,
    taxAmount,
    taxLines,
    detectedTotal,
    detectedSubtotal,
  ];
}
