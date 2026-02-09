import 'package:flutter/material.dart';
import 'package:vrs_erp/constants/app_constants.dart';

class ToggleOptionsScreen extends StatefulWidget {
  final bool includeDesign;
  final bool includeShade;
  final bool includeRate;
  final bool includeWsp;
  final bool includeSize;
  final bool includeSizeMrp;
  final bool includeSizeWsp;
  final bool includeProduct;
  final bool includeRemark;

  const ToggleOptionsScreen({
    Key? key,
    required this.includeDesign,
    required this.includeShade,
    required this.includeRate,
    required this.includeWsp,
    required this.includeSize,
    required this.includeSizeMrp,
    required this.includeSizeWsp,
    required this.includeProduct,
    required this.includeRemark,
  }) : super(key: key);

  @override
  _ToggleOptionsScreenState createState() => _ToggleOptionsScreenState();
}

class _ToggleOptionsScreenState extends State<ToggleOptionsScreen> {
  late bool includeDesign;
  late bool includeShade;
  late bool includeRate;
  late bool includeWsp;
  late bool includeSize;
  late bool includeSizeMrp;
  late bool includeSizeWsp;
  late bool includeProduct;
  late bool includeRemark;

  @override
  void initState() {
    super.initState();
    includeDesign = widget.includeDesign;
    includeShade = widget.includeShade;
    includeRate = widget.includeRate;
    includeWsp = widget.includeWsp;
    includeSize = widget.includeSize;
    includeSizeMrp = widget.includeSizeMrp;
    includeSizeWsp = widget.includeSizeWsp;
    includeProduct = widget.includeProduct;
    includeRemark = widget.includeRemark;
  }

  bool get allSelected =>
      includeDesign &&
      includeShade &&
      includeRate &&
      includeWsp &&
      includeSize &&
      includeSizeMrp &&
      includeSizeWsp &&
      includeProduct &&
      includeRemark;

  void toggleAll(bool? value) {
    final newValue = value ?? false;
    setState(() {
      includeDesign = newValue;
      includeShade = newValue;
      includeRate = newValue;
      includeWsp = newValue;
      includeSize = newValue;
      includeSizeMrp = newValue;
      includeSizeWsp = newValue;
      includeProduct = newValue;
      includeRemark = newValue;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.65,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Share Options',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Checkbox(
                      value: allSelected,
                      onChanged: toggleAll,
                      activeColor: AppColors.primaryColor,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Flexible(
                    child: _buildCompactSwitchTile(
                        'Include Design No', includeDesign, (v) => setState(() => includeDesign = v)),
                  ),
                  Flexible(
                    child: _buildCompactSwitchTile(
                        'Include Shade', includeShade, (v) => setState(() => includeShade = v)),
                  ),
                  Flexible(
                    child: _buildCompactSwitchTile(
                        'Include Mrp', includeRate, (v) => setState(() => includeRate = v)),
                  ),
                  Flexible(
                    child: _buildCompactSwitchTile(
                        'Include Wsp', includeWsp, (v) => setState(() => includeWsp = v)),
                  ),
                  Flexible(
                    child: _buildCompactSwitchTile('Include Size', includeSize, (v) => setState(() {
                          includeSize = v;
                          if (!v) {
                            includeSizeMrp = false;
                            includeSizeWsp = false;
                          }
                        })),
                  ),
                  Flexible(
                    child: _buildCompactSwitchTile('Include Size Wise Mrp', includeSizeMrp,
                        (v) => setState(() {
                          includeSizeMrp = v;
                          if (!v) includeSizeWsp = false;
                        }), disabled: !includeSize),
                  ),
                  Flexible(
                    child: _buildCompactSwitchTile('Include Size wise Wsp', includeSizeWsp,
                        (v) => setState(() => includeSizeWsp = v), disabled: !includeSize || !includeSizeMrp),
                  ),
                  Flexible(
                    child: _buildCompactSwitchTile(
                        'Include Product', includeProduct, (v) => setState(() => includeProduct = v)),
                  ),
                  Flexible(
                    child: _buildCompactSwitchTile(
                        'Include Remark', includeRemark, (v) => setState(() => includeRemark = v)),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: ElevatedButton(
                onPressed: () {
                  // Return the updated toggle states when "Done" is pressed
                  Navigator.pop(context, {
                    'design': includeDesign,
                    'shade': includeShade,
                    'rate': includeRate,
                    'wsp': includeWsp,
                    'size': includeSize,
                    'product': includeProduct,
                    'remark': includeRemark,
                    'rate1': includeSizeMrp,
                    'wsp1': includeSizeWsp,
                  });
                },
                child: const Text(
                  'Done',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: AppColors.primaryColor,
                  side: BorderSide(color: AppColors.primaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactSwitchTile(String title, bool value, Function(bool) onChanged, {bool disabled = false}) {
    return SwitchListTile(
      title: Text(title),
      value: value,
      onChanged: disabled ? null : onChanged,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      activeColor: AppColors.primaryColor,
      inactiveTrackColor: Colors.grey[300],
    );
  }
}