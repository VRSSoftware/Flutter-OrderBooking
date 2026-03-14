// import 'package:flutter/material.dart';
// import 'package:vrs_erp/constants/app_constants.dart';

// class ToggleOptionsScreen extends StatefulWidget {
//   final bool includeDesign;
//   final bool includeShade;
//   final bool includeRate;
//   final bool includeWsp;
//   final bool includeSize;
//   final bool includeSizeMrp;
//   final bool includeSizeWsp;
//   final bool includeProduct;
//   final bool includeRemark;

//   const ToggleOptionsScreen({
//     Key? key,
//     required this.includeDesign,
//     required this.includeShade,
//     required this.includeRate,
//     required this.includeWsp,
//     required this.includeSize,
//     required this.includeSizeMrp,
//     required this.includeSizeWsp,
//     required this.includeProduct,
//     required this.includeRemark,
//   }) : super(key: key);

//   @override
//   _ToggleOptionsScreenState createState() => _ToggleOptionsScreenState();
// }

// class _ToggleOptionsScreenState extends State<ToggleOptionsScreen> {
//   late bool includeDesign;
//   late bool includeShade;
//   late bool includeRate;
//   late bool includeWsp;
//   late bool includeSize;
//   late bool includeSizeMrp;
//   late bool includeSizeWsp;
//   late bool includeProduct;
//   late bool includeRemark;

//   @override
//   void initState() {
//     super.initState();
//     includeDesign = widget.includeDesign;
//     includeShade = widget.includeShade;
//     includeRate = widget.includeRate;
//     includeWsp = widget.includeWsp;
//     includeSize = widget.includeSize;
//     includeSizeMrp = widget.includeSizeMrp;
//     includeSizeWsp = widget.includeSizeWsp;
//     includeProduct = widget.includeProduct;
//     includeRemark = widget.includeRemark;
//   }

//   bool get allSelected =>
//       includeDesign &&
//       includeShade &&
//       includeRate &&
//       includeWsp &&
//       includeSize &&
//       includeSizeMrp &&
//       includeSizeWsp &&
//       includeProduct &&
//       includeRemark;

//   void toggleAll(bool? value) {
//     final newValue = value ?? false;
//     setState(() {
//       includeDesign = newValue;
//       includeShade = newValue;
//       includeRate = newValue;
//       includeWsp = newValue;
//       includeSize = newValue;
//       includeSizeMrp = newValue;
//       includeSizeWsp = newValue;
//       includeProduct = newValue;
//       includeRemark = newValue;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//         constraints: BoxConstraints(
//           maxHeight: MediaQuery.of(context).size.height * 0.65,
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 const Text(
//                   'Select Share Options',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 Row(
//                   children: [
//                     Checkbox(
//                       value: allSelected,
//                       onChanged: toggleAll,
//                       activeColor: AppColors.primaryColor,
//                       materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
//                     ),
//                     IconButton(
//                       icon: const Icon(Icons.close),
//                       onPressed: () => Navigator.pop(context),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//             Expanded(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.spaceAround,
//                 children: [
//                   Flexible(
//                     child: _buildCompactSwitchTile(
//                         'Include Design No', includeDesign, (v) => setState(() => includeDesign = v)),
//                   ),
//                   Flexible(
//                     child: _buildCompactSwitchTile(
//                         'Include Shade', includeShade, (v) => setState(() => includeShade = v)),
//                   ),
//                   Flexible(
//                     child: _buildCompactSwitchTile(
//                         'Include Mrp', includeRate, (v) => setState(() => includeRate = v)),
//                   ),
//                   Flexible(
//                     child: _buildCompactSwitchTile(
//                         'Include Wsp', includeWsp, (v) => setState(() => includeWsp = v)),
//                   ),
//                   Flexible(
//                     child: _buildCompactSwitchTile('Include Size', includeSize, (v) => setState(() {
//                           includeSize = v;
//                           if (!v) {
//                             includeSizeMrp = false;
//                             includeSizeWsp = false;
//                           }
//                         })),
//                   ),
//                   Flexible(
//                     child: _buildCompactSwitchTile('Include Size Wise Mrp', includeSizeMrp,
//                         (v) => setState(() {
//                           includeSizeMrp = v;
//                           if (!v) includeSizeWsp = false;
//                         }), disabled: !includeSize),
//                   ),
//                   Flexible(
//                     child: _buildCompactSwitchTile('Include Size wise Wsp', includeSizeWsp,
//                         (v) => setState(() => includeSizeWsp = v), disabled: !includeSize || !includeSizeMrp),
//                   ),
//                   Flexible(
//                     child: _buildCompactSwitchTile(
//                         'Include Product', includeProduct, (v) => setState(() => includeProduct = v)),
//                   ),
//                   Flexible(
//                     child: _buildCompactSwitchTile(
//                         'Include Remark', includeRemark, (v) => setState(() => includeRemark = v)),
//                   ),
//                 ],
//               ),
//             ),
//             Container(
//               padding: const EdgeInsets.only(top: 12, bottom: 8),
//               child: ElevatedButton(
//                 onPressed: () {
//                   // Return the updated toggle states when "Done" is pressed
//                   Navigator.pop(context, {
//                     'design': includeDesign,
//                     'shade': includeShade,
//                     'rate': includeRate,
//                     'wsp': includeWsp,
//                     'size': includeSize,
//                     'product': includeProduct,
//                     'remark': includeRemark,
//                     'rate1': includeSizeMrp,
//                     'wsp1': includeSizeWsp,
//                   });
//                 },
//                 child: const Text(
//                   'Done',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 style: ElevatedButton.styleFrom(
//                   minimumSize: const Size(double.infinity, 50),
//                   backgroundColor: AppColors.primaryColor,
//                   side: BorderSide(color: AppColors.primaryColor),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildCompactSwitchTile(String title, bool value, Function(bool) onChanged, {bool disabled = false}) {
//     return SwitchListTile(
//       title: Text(title),
//       value: value,
//       onChanged: disabled ? null : onChanged,
//       dense: true,
//       contentPadding: const EdgeInsets.symmetric(horizontal: 4),
//       activeColor: AppColors.primaryColor,
//       inactiveTrackColor: Colors.grey[300],
//     );
//   }
// }



import 'package:flutter/material.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:google_fonts/google_fonts.dart';

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
    return 
    SafeArea(
   child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.tune_rounded,
                        color: AppColors.primaryColor,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Share Options',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    // Select All
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Text(
                          //   'All',
                          //   style: GoogleFonts.poppins(
                          //     fontSize: 11,
                          //     color: Colors.grey.shade700,
                          //   ),
                          // ),
                          const SizedBox(width: 2),
                          SizedBox(
                            height: 18,
                            width: 18,
                            child: Checkbox(
                              value: allSelected,
                              onChanged: toggleAll,
                              activeColor: AppColors.primaryColor,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Close
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: Colors.grey.shade700,
                          size: 16,
                        ),
                        onPressed: () => Navigator.pop(context),
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 4),
          
          // Options Grid - 2 columns
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(child: _buildCompactOption(
                      'Design',
                      includeDesign,
                      (v) => setState(() => includeDesign = v),
                      icon: Icons.design_services_rounded,
                      iconColor: Colors.blue[700]!,
                    )),
                    const SizedBox(width: 8),
                    Expanded(child: _buildCompactOption(
                      'Shade',
                      includeShade,
                      (v) => setState(() => includeShade = v),
                      icon: Icons.color_lens_rounded,
                      iconColor: Colors.purple[700]!,
                    )),
                  ],
                ),
                const SizedBox(height: 6),
                
                Row(
                  children: [
                    Expanded(child: _buildCompactOption(
                      'MRP',
                      includeRate,
                      (v) => setState(() => includeRate = v),
                      icon: Icons.attach_money_rounded,
                      iconColor: Colors.green[700]!,
                    )),
                    const SizedBox(width: 8),
                    Expanded(child: _buildCompactOption(
                      'WSP',
                      includeWsp,
                      (v) => setState(() => includeWsp = v),
                      icon: Icons.currency_rupee_rounded,
                      iconColor: Colors.orange[700]!,
                    )),
                  ],
                ),
                const SizedBox(height: 6),
                
                Row(
                  children: [
                    Expanded(child: _buildCompactOption(
                      'Size',
                      includeSize,
                      (v) => setState(() {
                        includeSize = v;
                        if (!v) {
                          includeSizeMrp = false;
                          includeSizeWsp = false;
                        }
                      }),
                      icon: Icons.straighten_rounded,
                      iconColor: Colors.teal[700]!,
                    )),
                    const SizedBox(width: 8),
                    Expanded(child: _buildCompactOption(
                      'Size MRP',
                      includeSizeMrp,
                      (v) => setState(() {
                        includeSizeMrp = v;
                        if (!v) includeSizeWsp = false;
                      }),
                      icon: Icons.calculate_rounded,
                      iconColor: Colors.indigo[700]!,
                      disabled: !includeSize,
                    )),
                  ],
                ),
                const SizedBox(height: 6),
                
                Row(
                  children: [
                    Expanded(child: _buildCompactOption(
                      'Size WSP',
                      includeSizeWsp,
                      (v) => setState(() => includeSizeWsp = v),
                      icon: Icons.currency_rupee_rounded,
                      iconColor: Colors.pink[700]!,
                      disabled: !includeSize || !includeSizeMrp,
                    )),
                    const SizedBox(width: 8),
                    Expanded(child: _buildCompactOption(
                      'Product',
                      includeProduct,
                      (v) => setState(() => includeProduct = v),
                      icon: Icons.inventory_2_rounded,
                      iconColor: Colors.brown[700]!,
                    )),
                  ],
                ),
                const SizedBox(height: 6),
                
                Row(
                  children: [
                    Expanded(child: _buildCompactOption(
                      'Remark',
                      includeRemark,
                      (v) => setState(() => includeRemark = v),
                      icon: Icons.comment_rounded,
                      iconColor: Colors.cyan[700]!,
                    )),
                    const SizedBox(width: 8),
                    Expanded(child: Container()), // Empty spacer
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Done Button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: ElevatedButton(
              onPressed: () {
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
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Apply',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.check_rounded, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
   ), );
  }

  Widget _buildCompactOption(
    String title,
    bool value,
    Function(bool) onChanged, {
    bool disabled = false,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: disabled 
              ? Colors.grey.shade200 
              : value 
                  ? AppColors.primaryColor.withOpacity(0.3) 
                  : Colors.grey.shade200,
          width: value ? 1.2 : 1,
        ),
        color: disabled 
            ? Colors.grey.shade50 
            : value 
                ? AppColors.primaryColor.withOpacity(0.02)
                : Colors.white,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: disabled ? null : () => onChanged(!value),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(disabled ? 0.1 : 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 14,
                    color: disabled ? Colors.grey.shade400 : iconColor,
                  ),
                ),
                const SizedBox(width: 6),
                
                // Title
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: value ? FontWeight.w600 : FontWeight.w400,
                      color: disabled 
                          ? Colors.grey.shade400 
                          : const Color(0xFF1E293B),
                    ),
                  ),
                ),
                
                // Compact Switch
                Container(
                  height: 20,
                  width: 32,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: disabled 
                        ? Colors.grey.shade200 
                        : value 
                            ? AppColors.primaryColor 
                            : Colors.grey.shade300,
                  ),
                  child: Stack(
                    children: [
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 150),
                        curve: Curves.easeInOut,
                        left: value ? 14 : 2,
                        right: value ? 2 : 14,
                        top: 2,
                        bottom: 2,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 1,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}