class PaymentItem {
  final String label;
  final double amount;

  PaymentItem({required this.label, required this.amount});

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = new Map();
    map["label"] = this.label;
    map["amount"] = this.amount;
    return map;
  }
}
