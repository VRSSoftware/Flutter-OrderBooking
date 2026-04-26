class RegisterOrder {
  final String orderId;
  final String itemName; // Maps to customerName for display
  final String orderNo;
  final String city;
  final String orderDate;
  final String createdTime;
  final int quantity;
  final double amount;
  final String orderBy;
  final String salesPersonKey;
  final String salesPersonName;
  final String salesCommPer;
  final String remark;
  final String whatsAppMobileNo;
  final String orderType;
  final String dlvDate;
  final String deliveryType;
  final String partyLedKey;
    final String partyName; 
      final String packType; 
        final String packingDocNo; 

  RegisterOrder({
    required this.orderId,
    required this.itemName,
    required this.orderNo,
    required this.city,
    required this.orderDate,
    required this.createdTime,
    required this.quantity,
    required this.amount,
    required this.orderBy,
    required this.salesPersonKey,
    required this.salesPersonName,
    required this.salesCommPer,
    required this.remark,
    required this.whatsAppMobileNo,
    required this.orderType,
    required this.dlvDate,
    required this.deliveryType,
     required this.partyLedKey, 
       required this.partyName,
         required this.packType,
         required this.packingDocNo,
  });

  factory RegisterOrder.fromJson(Map<String, dynamic> json) {
    return RegisterOrder(
      orderId: json['orderId']?.toString() ?? '',
      itemName: json['customerName']?.toString() ?? '', // Mapping customerName to itemName
      orderNo: json['orderNo']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      orderDate: json['orderDate']?.toString() ?? '',
      createdTime: json['createdTime']?.toString() ?? '',
      quantity: int.tryParse(json['totalQty']?.toString() ?? '0') ?? 0,
      amount: double.tryParse(json['totalAmt']?.toString() ?? '0.0') ?? 0.0,
      orderBy: json['orderBy']?.toString() ?? '',
      salesPersonKey: json['salesPersonKey']?.toString() ?? '',
      salesPersonName: json['salesPersonName']?.toString() ?? '',
      salesCommPer: json['salesCommPer']?.toString() ?? '',
      remark: json['remark']?.toString() ?? '',
      whatsAppMobileNo: json['whatsAppMobileNo']?.toString() ?? '',
      orderType: json['orderType']?.toString() ?? '',
      dlvDate: json['dlvDate']?.toString() ?? '',
      deliveryType: json['deliveryType']?.toString() ?? '',
      partyLedKey: json['partyKey']?.toString() ?? '',
       partyName: json['customerName']?.toString() ?? '',
        packType: json['packType']?.toString() ?? '0',
              packingDocNo: json['packingDocNo']?.toString() ?? '', 
    );
  }
}