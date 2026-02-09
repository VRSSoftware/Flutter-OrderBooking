import 'package:vrs_erp/models/OrderMatrix.dart';
import 'package:vrs_erp/models/catalog.dart';

class CatalogOrderData {
  final Catalog catalog;
  final OrderMatrix orderMatrix;

  CatalogOrderData({
    required this.catalog,
    required this.orderMatrix,
  });
}
