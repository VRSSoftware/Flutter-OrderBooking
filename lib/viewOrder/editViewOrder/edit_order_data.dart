import 'package:vrs_erp/models/CatalogOrderData.dart';
import 'package:vrs_erp/models/consignee.dart';

class EditOrderData {
  static List<CatalogOrderData> data = [];
  static String doc_id = '';
  static String partyName = '';
  static String partyKey = '';
  static String brokerName = '';
  static String brokerKey = '';
  static String transporterName = '';
  static String transporterKey = '';
  static String commission = '';
  static String deliveryDays = '';
  static String deliveryDate = '';
  static String remark = '';
  static String paymentDays = '';
  static String detailsForEdit = '';
  static List<Map<String, String>> brokerList = [];
  static List<Map<String, String>> transporterList = [];
  static List<Consignee> consignees = [];
  
  static void clear() {
    data = [];
    doc_id = '';
    partyName = '';
    partyKey = '';
    brokerName = '';
    brokerKey = '';
    transporterName = '';
    transporterKey = '';
    commission = '';
    deliveryDays = '';
    deliveryDate = '';
    remark = '';
    paymentDays = '';
    detailsForEdit = '';
    brokerList = [];
    transporterList = [];
    consignees = [];
  }
}
