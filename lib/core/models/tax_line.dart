import 'package:equatable/equatable.dart';

/// One tax or charge line as printed on a bill, e.g. "CGST (2.5%)" ₹89.75.
class TaxLine extends Equatable {
  const TaxLine({required this.label, required this.amount});

  final String label;
  final double amount;

  @override
  List<Object?> get props => [label, amount];
}
