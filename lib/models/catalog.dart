class Catalog {
  final String itemSubGrpKey;
  final String itemSubGrpName;
  final String itemKey;
  final String itemName;
  final String brandKey;
  final String brandName;
  final String styleKey;
  final String styleCode;
  final String shadeKey;
  final String shadeName;
  final String styleSizeId;
  final String sizeName;
  final double mrp;
  final double wsp;
  final double onlyMRP;
  final int clqty;
  final String fullImagePath;
  final String remark;
  final String imageId;
  final String sizeDetails; 
  final String sizeDetailsWithoutWSp;
  final String sizeWithMrp;
  final String styleCodeWithcount;
  final String onlySizes;
  final String sizeWithWsp;
  final String createdDate;
  final String shadeImages;
  final String upcoming_Stk;
  final String stkQty;
  final String barcode;
  final int total;
  final String? minMRP;
  final String? maxMRP;

  Catalog({
    required this.itemSubGrpKey,
    required this.itemSubGrpName,
    required this.itemKey,
    required this.itemName,
    required this.brandKey,
    required this.brandName,
    required this.styleKey,
    required this.styleCode,
    required this.shadeKey,
    required this.shadeName,
    required this.styleSizeId,
    required this.sizeName,
    required this.mrp,
    required this.wsp,
    required this.onlyMRP,
    required this.clqty,
    required this.total,
    required this.fullImagePath,
    required this.remark,
    required this.imageId,
    required this.upcoming_Stk,
    this.sizeDetails = '', // ✅ Optional default value
    this.sizeDetailsWithoutWSp = '',
    this.sizeWithMrp = '',
    this.styleCodeWithcount = '',
    this.onlySizes='',
    this.sizeWithWsp='',
    this.createdDate='',
    this.shadeImages='',
    this.stkQty = '',
    this.barcode = '',
    this.minMRP,
    this.maxMRP,
  });

  factory Catalog.fromJson(Map<String, dynamic> json) {
    return Catalog(
      itemSubGrpKey: json['itemSubGrpKey'] ?? '',
      itemSubGrpName: json['itemSubGrpName'] ?? '',
      itemKey: json['itemKey'] ?? '',
      itemName: json['itemName'] ?? '',
      brandKey: json['brandKey'] ?? '',
      brandName: json['brandName'] ?? '',
      styleKey: json['styleKey'] ?? '',
      styleCode: json['styleCode'] ?? '',
      shadeKey: json['shadeKey'] ?? '',
      shadeName: json['shadeName'] ?? '',
      styleSizeId: json['styleSizeId'] ?? '',
      sizeName: json['sizeName'] ?? '',
      mrp: (json['mrp'] ?? 0).toDouble(),
      wsp: (json['wsp'] ?? 0).toDouble(),
      onlyMRP: (json['onlyMRP'] ?? 0).toDouble(),
      clqty: json['clqty'] ?? 0,
      total: json['total'] ?? 0,
      fullImagePath: json['fullImagePath'] ?? '/NoImage.jpg',
      remark: json['remark'] ?? '',
      imageId: json['imageId'] ?? '',
      sizeDetails: json['sizeDetails'] ?? '', // ✅ Include in deserialization
      sizeDetailsWithoutWSp: json['sizeDetailsWithoutWSp'] ?? '',
      sizeWithMrp: json['sizeWithMrp'] ?? '',
      styleCodeWithcount: json['styleCodeWithcount'] ?? '',
       onlySizes: json['onlySizes'] ?? '',
       sizeWithWsp: json['sizeWithWsp'] ?? '',
       createdDate: json['createdDate'] ?? '',
       shadeImages: json['shadeImages'] ?? '',
       upcoming_Stk: json['upcoming_Stk'] ?? '',
       stkQty: json['data2'] ?? '',
       barcode: json['barcode'] ?? '',
        minMRP: json['minMRP']?.toString(),
      maxMRP: json['maxMRP']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemSubGrpKey': itemSubGrpKey,
      'itemSubGrpName': itemSubGrpName,
      'itemKey': itemKey,
      'itemName': itemName,
      'brandKey': brandKey,
      'brandName': brandName,
      'styleKey': styleKey,
      'styleCode': styleCode,
      'shadeKey': shadeKey,
      'shadeName': shadeName,
      'styleSizeId': styleSizeId,
      'sizeName': sizeName,
      'mrp': mrp,
      'wsp': wsp,
      'onlyMRP': onlyMRP,
      'total': total,
      'fullImagePath': fullImagePath,
      'remark': remark,
      'imageId': imageId,
      'sizeDetails': sizeDetails, // ✅ Include in serialization
      'sizeDetailsWithoutWSp' : sizeDetailsWithoutWSp,
      'sizeWithMrp' : sizeWithMrp,
      'styleCodeWithcount' : styleCodeWithcount,
      'onlySizes':onlySizes,
      'sizeWithWsp':sizeWithWsp,
      'createdDate':createdDate,
      'shadeImages':shadeImages,
      'stkQty':stkQty,
      'barcode':barcode,
      'minMRP': minMRP,
      'maxMRP': maxMRP,

    };
  }
}
