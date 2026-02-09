import 'package:vrs_erp/models/keyName.dart';

class FilterData {
  static KeyName? selectedLedger;
  // static KeyName? selectedSalesperson;
  static KeyName? selectedState;
  static KeyName? selectedCity;
  // static List<KeyName> selectedsalespersons = [];
  static List<KeyName>? selectedLedgers = [];
  static List<KeyName>? selectedSalespersons = [];
  static List<KeyName>? selectedStates = [];
  static List<KeyName>? selectedCities = [];
  static String? selectedDateRange = 'Today';
  static DateTime? fromDate = DateTime.now();
  static DateTime? toDate = DateTime.now();
}
