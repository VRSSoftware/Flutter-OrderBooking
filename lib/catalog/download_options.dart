// import 'package:flutter/material.dart';
// import 'package:vrs_erp/constants/app_constants.dart';

// class DownloadOptionsSheet extends StatefulWidget {
//   final Function(String, Map<String, bool>) onDownload;
//   final Function(Map<String, bool>)? onToggleOptions; // New callback for toggle changes
//   final Map<String, bool>? initialOptions;

//   const DownloadOptionsSheet({
//     Key? key,
//     required this.onDownload,
//     this.onToggleOptions,
//     this.initialOptions,
//   }) : super(key: key);

//   @override
//   _DownloadOptionsSheetState createState() => _DownloadOptionsSheetState();
// }

// class _DownloadOptionsSheetState extends State<DownloadOptionsSheet> {
//   late Map<String, bool> options;

//   @override
//   void initState() {
//     super.initState();
//     options = Map.from(widget.initialOptions ?? {
//       'design': true,
//       'shade': true,
//       'rate': true,
//       'wsp': false,
//       'size': true,
//       'rate1': true,
//       'wsp1': false,
//       'product': true,
//       'remark': true,
//     });
//   }

//   void _toggleAllOptions(bool? value) {
//     setState(() {
//       final newValue = value ?? false;
//       options.updateAll((key, value) => newValue);
//     });
//   }

//   Future<Map<String, bool>?> _showOptionsBottomSheet(BuildContext context) async {
//     // Create a copy of options for the bottom sheet to avoid direct mutation
//     Map<String, bool> tempOptions = Map.from(options);

//     return await showModalBottomSheet<Map<String, bool>>(
//       context: context,
//       isScrollControlled: true,
//       builder: (BuildContext context) {
//         return 
//         SafeArea(
//       child:  StatefulBuilder(
//           builder: (context, setState) {
//             return SingleChildScrollView(
//               child: Container(
//                 padding: EdgeInsets.only(
//                   left: 16,
//                   right: 16,
//                   top: 16,
//                   bottom: MediaQuery.of(context).viewInsets.bottom + 16,
//                 ),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         const Text(
//                           'Select Fields to Include',
//                           style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         Row(
//                           children: [
//                             Padding(
//                               padding: const EdgeInsets.only(right: 8.0),
//                               child: SizedBox(
//                                 height: 24,
//                                 width: 24,
//                                 child: Checkbox(
//                                   materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
//                                   value: tempOptions.values.every((v) => v),
//                                   onChanged: (value) {
//                                     setState(() {
//                                       tempOptions.updateAll((key, _) => value ?? false);
//                                     });
//                                   },
//                                   activeColor: AppColors.primaryColor,
//                                 ),
//                               ),
//                             ),
//                             IconButton(
//                               icon: const Icon(Icons.close),
//                               onPressed: () => Navigator.pop(context),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 16),
//                     _buildToggleOption('Include Design No', tempOptions['design']!, (value) {
//                       setState(() => tempOptions['design'] = value);
//                     }),
//                     _buildToggleOption('Include Shade', tempOptions['shade']!, (value) {
//                       setState(() => tempOptions['shade'] = value);
//                     }),
//                     _buildToggleOption('Include Mrp', tempOptions['rate']!, (value) {
//                       setState(() => tempOptions['rate'] = value);
//                     }),
//                     _buildToggleOption('Include Wsp', tempOptions['wsp']!, (value) {
//                       setState(() => tempOptions['wsp'] = value);
//                     }),
//                     _buildToggleOption('Include Size', tempOptions['size']!, (value) {
//                       setState(() {
//                         tempOptions['size'] = value;
//                         if (!value) {
//                           tempOptions['rate1'] = false;
//                           tempOptions['wsp1'] = false;
//                         }
//                       });
//                     }),
//                     _buildToggleOption('Include Size Wise Mrp', tempOptions['rate1']!, (value) {
//                       setState(() {
//                         tempOptions['rate1'] = value;
//                         if (!value) tempOptions['wsp1'] = false;
//                       });
//                     }, disabled: !tempOptions['size']!),
//                     _buildToggleOption('Include Size wise Wsp', tempOptions['wsp1']!, (value) {
//                       setState(() => tempOptions['wsp1'] = value);
//                     }, disabled: !tempOptions['size']! || !tempOptions['rate1']!),
//                     _buildToggleOption('Include Product', tempOptions['product']!, (value) {
//                       setState(() => tempOptions['product'] = value);
//                     }),
//                     _buildToggleOption('Include Remark', tempOptions['remark']!, (value) {
//                       setState(() => tempOptions['remark'] = value);
//                     }),
//                     const SizedBox(height: 16),
//                     SizedBox(
//                       width: double.infinity,
//                       child: ElevatedButton(
//                         onPressed: () {
//                           Navigator.pop(context, tempOptions); // Return updated options
//                         },
//                         child: const Text(
//                           'Done',
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         style: ElevatedButton.styleFrom(
//                           minimumSize: const Size(double.infinity, 50),
//                           backgroundColor: AppColors.primaryColor,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             );
//           },
//      ), );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return 
//     SafeArea(
//    child: Container(
//       padding: const EdgeInsets.all(16),
//       constraints: BoxConstraints(
//         maxHeight: MediaQuery.of(context).size.height * 0.7,
//       ),
//       child: SingleChildScrollView(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 const Text(
//                   'Download ',
//                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                 ),
//                 Row(
//                   children: [
//                     IconButton(
//                       icon: const Icon(Icons.more_vert),
//                       onPressed: () async {
//                         final updatedOptions = await _showOptionsBottomSheet(context);
//                         if (updatedOptions != null) {
//                           setState(() {
//                             options = updatedOptions;
//                           });
//                           widget.onToggleOptions?.call(updatedOptions); // Notify parent
//                         }
//                       },
//                     ),
//                     IconButton(
//                       icon: const Icon(Icons.close),
//                       onPressed: () => Navigator.pop(context),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16),
//             _buildDownloadOption(
//               icon: Icons.image,
//               title: 'Download as Image',
//               onTap: () {
//                 Navigator.pop(context);
//                 widget.onDownload('image', options);
//               },
//             ),
//             const SizedBox(height: 8),
//             _buildDownloadOption(
//               icon: Icons.picture_as_pdf,
//               title: 'Download as PDF',
//               onTap: () {
//                 Navigator.pop(context);
//                 widget.onDownload('pdf', options);
//               },
//             ),
//             const SizedBox(height: 16),
//           ],
//         ),
//       ),
//   ),  );
//   }

//   Widget _buildDownloadOption({
//     required IconData icon,
//     required String title,
//     required VoidCallback onTap,
//   }) {
//     return InkWell(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.all(12),
//         decoration: BoxDecoration(
//           color: Colors.grey[200],
//           borderRadius: BorderRadius.circular(8),
//         ),
//         child: Row(
//           children: [
//             Icon(icon, color: AppColors.primaryColor),
//             const SizedBox(width: 12),
//             Text(title),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildToggleOption(
//     String label,
//     bool value,
//     Function(bool) onChanged, {
//     bool disabled = false,
//   }) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4),
//       child: Row(
//         children: [
//           Expanded(child: Text(label)),
//           Switch(
//             value: value,
//             onChanged: disabled ? null : onChanged,
//             activeColor: AppColors.primaryColor,
//             inactiveTrackColor: Colors.grey[300],
//           ),
//         ],
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:vrs_erp/constants/app_constants.dart';

class DownloadOptionsSheet extends StatefulWidget {
  final Function(String, Map<String, bool>) onDownload;
  final Function(Map<String, bool>)? onToggleOptions; // New callback for toggle changes
  final Map<String, bool>? initialOptions;

  const DownloadOptionsSheet({
    Key? key,
    required this.onDownload,
    this.onToggleOptions,
    this.initialOptions,
  }) : super(key: key);

  @override
  _DownloadOptionsSheetState createState() => _DownloadOptionsSheetState();
}

class _DownloadOptionsSheetState extends State<DownloadOptionsSheet> {
  late Map<String, bool> options;

  @override
  void initState() {
    super.initState();
    options = Map.from(widget.initialOptions ?? {
      'design': true,
      'shade': true,
      'rate': true,
      'wsp': false,
      'size': true,
      'rate1': true,
      'wsp1': false,
      'product': true,
      'remark': true,
    });
  }

  void _toggleAllOptions(bool? value) {
    setState(() {
      final newValue = value ?? false;
      options.updateAll((key, value) => newValue);
    });
  }

  Future<Map<String, bool>?> _showOptionsBottomSheet(BuildContext context) async {
    // Create a copy of options for the bottom sheet to avoid direct mutation
    Map<String, bool> tempOptions = Map.from(options);

    return await showModalBottomSheet<Map<String, bool>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: StatefulBuilder(
            builder: (context, setState) {
              return Container(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Select Fields to Include',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              // Select All checkbox
                              Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: Checkbox(
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    value: tempOptions.values.every((v) => v),
                                    onChanged: (value) {
                                      setState(() {
                                        tempOptions.updateAll((key, _) => value ?? false);
                                      });
                                    },
                                    activeColor: AppColors.primaryColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ),
                              // Close button
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => Navigator.pop(context),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Options List
                      _buildToggleOption('Include Design No', tempOptions['design']!, (value) {
                        setState(() => tempOptions['design'] = value);
                      }),
                      _buildToggleOption('Include Shade', tempOptions['shade']!, (value) {
                        setState(() => tempOptions['shade'] = value);
                      }),
                      _buildToggleOption('Include MRP', tempOptions['rate']!, (value) {
                        setState(() => tempOptions['rate'] = value);
                      }),
                      _buildToggleOption('Include WSP', tempOptions['wsp']!, (value) {
                        setState(() => tempOptions['wsp'] = value);
                      }),
                      _buildToggleOption('Include Size', tempOptions['size']!, (value) {
                        setState(() {
                          tempOptions['size'] = value;
                          if (!value) {
                            tempOptions['rate1'] = false;
                            tempOptions['wsp1'] = false;
                          }
                        });
                      }),
                      _buildToggleOption(
                        'Include Size Wise MRP', 
                        tempOptions['rate1']!, 
                        (value) {
                          setState(() {
                            tempOptions['rate1'] = value;
                            if (!value) tempOptions['wsp1'] = false;
                          });
                        }, 
                        disabled: !tempOptions['size']!,
                      ),
                      _buildToggleOption(
                        'Include Size Wise WSP', 
                        tempOptions['wsp1']!, 
                        (value) {
                          setState(() => tempOptions['wsp1'] = value);
                        }, 
                        disabled: !tempOptions['size']! || !tempOptions['rate1']!,
                      ),
                      _buildToggleOption('Include Product', tempOptions['product']!, (value) {
                        setState(() => tempOptions['product'] = value);
                      }),
                      _buildToggleOption('Include Remark', tempOptions['remark']!, (value) {
                        setState(() => tempOptions['remark'] = value);
                      }),
                      
                      const SizedBox(height: 16),
                      
                      // Done Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context, tempOptions);
                          },
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            backgroundColor: AppColors.primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Apply Selection',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Download Options',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    // Settings button
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.tune_rounded,
                          color: AppColors.primaryColor,
                          size: 22,
                        ),
                        onPressed: () async {
                          final updatedOptions = await _showOptionsBottomSheet(context);
                          if (updatedOptions != null) {
                            setState(() {
                              options = updatedOptions;
                            });
                            widget.onToggleOptions?.call(updatedOptions);
                          }
                        },
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                      ),
                    ),
                    // Close button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.close,
                          color: Colors.grey.shade700,
                          size: 22,
                        ),
                        onPressed: () => Navigator.pop(context),
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Download options
            _buildDownloadOption(
              icon: Icons.image_rounded,
              title: 'Download as Image',
              subtitle: 'Save as image format',
              onTap: () {
                Navigator.pop(context);
                widget.onDownload('image', options);
              },
            ),
            
            const SizedBox(height: 12),
            
            _buildDownloadOption(
              icon: Icons.picture_as_pdf_rounded,
              title: 'Download as PDF',
              subtitle: 'Save as PDF document',
              onTap: () {
                Navigator.pop(context);
                widget.onDownload('pdf', options);
              },
            ),
            
         
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleOption(
    String label,
    bool value,
    Function(bool) onChanged, {
    bool disabled = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: disabled ? Colors.grey.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: disabled ? Colors.grey.shade200 : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: disabled ? Colors.grey.shade500 : Colors.grey.shade800,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: disabled ? null : (newValue) => onChanged(newValue),
            activeColor: AppColors.primaryColor,
            activeTrackColor: AppColors.primaryColor.withOpacity(0.5),
            inactiveThumbColor: Colors.grey.shade400,
            inactiveTrackColor: Colors.grey.shade300,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}