import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:vrs_erp/catalog/toggle_option_screen.dart';
import 'package:vrs_erp/constants/app_constants.dart';

class ShareOptionsPage extends StatefulWidget {
  final Function({
    bool includeDesign,
    bool includeShade,
    bool includeRate,
    bool includeWsp,
    bool includeSize,
    bool includeSizeMrp,
    bool includeSizeWsp,
    bool includeProduct,
    bool includeRemark,
  })
  onImageShare;
  final Function({
    bool includeDesign,
    bool includeShade,
    bool includeRate,
    bool includeSize,
    bool includeProduct,
    bool includeRemark,
  })
  onWhatsAppShare;
  final Function({
    bool includeDesign,
    bool includeShade,
    bool includeRate,
    bool includeWsp,
    bool includeSize,
    bool includeSizeMrp,
    bool includeSizeWsp,
    bool includeProduct,
    bool includeRemark,
  })
  onPDFShare;
  final Function(bool, bool, bool, bool, bool, bool, bool, bool, bool)
  onToggleOptions;
  final bool includeDesign;
  final bool includeShade;
  final bool includeRate;
  final bool includeWsp;
  final bool includeSize;
  final bool includeSizeMrp;
  final bool includeSizeWsp;
  final bool includeProduct;
  final bool includeRemark;
  final VoidCallback onLinkShare;

  const ShareOptionsPage({
    Key? key,
    required this.onImageShare,
    required this.onWhatsAppShare,
    required this.onPDFShare,
    required this.onToggleOptions,
    required this.includeDesign,
    required this.includeShade,
    required this.includeRate,
    required this.includeWsp,
    required this.includeSize,
    required this.includeSizeMrp,
    required this.includeSizeWsp,
    required this.includeProduct,
    required this.includeRemark,
    required this.onLinkShare,
  }) : super(key: key);

  @override
  _ShareOptionsPageState createState() => _ShareOptionsPageState();
}

class _ShareOptionsPageState extends State<ShareOptionsPage> {
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

  Future<void> _showToggleOptions(BuildContext context) async {
    final options = await showModalBottomSheet<Map<String, bool>>(
      context: context,
      builder:
          (context) => ToggleOptionsScreen(
            includeDesign: includeDesign,
            includeShade: includeShade,
            includeRate: includeRate,
            includeWsp: includeWsp,
            includeSize: includeSize,
            includeSizeMrp: includeSizeMrp,
            includeSizeWsp: includeSizeWsp,
            includeProduct: includeProduct,
            includeRemark: includeRemark,
          ),
    );

    if (options != null) {
      setState(() {
        includeDesign = options['design'] ?? includeDesign;
        includeShade = options['shade'] ?? includeShade;
        includeRate = options['rate'] ?? includeRate;
        includeWsp = options['wsp'] ?? includeWsp;
        includeSize = options['size'] ?? includeSize;
        includeSizeMrp = options['rate1'] ?? includeSizeMrp;
        includeSizeWsp = options['wsp1'] ?? includeSizeWsp;
        includeProduct = options['product'] ?? includeProduct;
        includeRemark = options['remark'] ?? includeRemark;
      });

      // Call onToggleOptions to update parent state and save to shared_preferences
      widget.onToggleOptions(
        includeDesign,
        includeShade,
        includeRate,
        includeWsp,
        includeSize,
        includeSizeMrp,
        includeSizeWsp,
        includeProduct,
        includeRemark,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Share Design as',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => _showToggleOptions(context),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildShareOption(
            icon: const FaIcon(
              FontAwesomeIcons.image,
              color: AppColors.primaryColor,
              size: 22,
            ),

            title: 'Image',
            onTap: () {
              widget.onImageShare(
                includeDesign: includeDesign,
                includeShade: includeShade,
                includeRate: includeRate,
                includeWsp: includeWsp,
                includeSize: includeSize,
                includeSizeMrp: includeSizeMrp,
                includeSizeWsp: includeSizeWsp,
                includeProduct: includeProduct,
                includeRemark: includeRemark,
              );
            },
            context: context,
          ),
          _buildShareOption(
            icon: const FaIcon(
              FontAwesomeIcons.whatsapp,
              size: 22,
              color: AppColors.primaryColor,
            ),
            title: 'WhatsApp',
            onTap: () {
              widget.onWhatsAppShare(
                includeDesign: includeDesign,
                includeShade: includeShade,
                includeRate: includeRate,
                includeSize: includeSize,
                includeProduct: includeProduct,
                includeRemark: includeRemark,
              );
            },
            context: context,
          ),

          _buildShareOption(
            icon: const FaIcon(
              FontAwesomeIcons.filePdf,
              color: AppColors.primaryColor,
              size: 22,
            ),

            title: 'PDF',
            onTap: () {
              widget.onPDFShare(
                includeDesign: includeDesign,
                includeShade: includeShade,
                includeRate: includeRate,
                includeWsp: includeWsp,
                includeSize: includeSize,
                includeSizeMrp: includeSizeMrp,
                includeSizeWsp: includeSizeWsp,
                includeProduct: includeProduct,
                includeRemark: includeRemark,
              );
            },
            context: context,
          ),
          _buildShareOption(
            icon: const FaIcon(
              FontAwesomeIcons.link,
              color: Colors.blue,
              size: 22,
            ),

            title: 'Web Link',
            onTap: () {
              widget.onLinkShare();
            },
            context: context,
          ),
        ],
      ),
    );
  }

  Widget _buildShareOption({
    required Widget icon, // change from IconData to Widget
    required String title,
    required VoidCallback onTap,
    required BuildContext context,
  }) {
    return ListTile(leading: icon, title: Text(title), onTap: onTap);
  }

  // import 'package:flutter/material.dart';
  // import 'package:vrs_erp/constants/app_constants.dart';

  // class ShareOptionsPage extends StatefulWidget {
  //   final bool includeDesign;
  //   final bool includeShade;
  //   final bool includeRate;
  //   final bool includeWsp;
  //   final bool includeSize;
  //   final bool includeSizeMrp;
  //   final bool includeSizeWsp;
  //   final bool includeProduct;
  //   final bool includeRemark;
  //   final Function({
  //     bool includeDesign,
  //     bool includeShade,
  //     bool includeRate,
  //     bool includeSize,
  //     bool includeProduct,
  //     bool includeRemark,
  //   }) onWhatsAppShare;
  //   final Function({
  //     bool includeDesign,
  //     bool includeShade,
  //     bool includeRate,
  //     bool includeWsp,
  //     bool includeSize,
  //     bool includeSizeMrp,
  //     bool includeSizeWsp,
  //     bool includeProduct,
  //     bool includeRemark,
  //   }) onImageShare;
  //   final Function({
  //     bool includeDesign,
  //     bool includeShade,
  //     bool includeRate,
  //     bool includeWsp,
  //     bool includeSize,
  //     bool includeSizeMrp,
  //     bool includeSizeWsp,
  //     bool includeProduct,
  //     bool includeRemark,
  //   }) onPDFShare;
  //   final VoidCallback onLinkShare;
  //   final Function(
  //     bool design,
  //     bool shade,
  //     bool rate,
  //     bool wsp,
  //     bool size,
  //     bool rate1,
  //     bool wsp1,
  //     bool product,
  //     bool remark,
  //   ) onToggleOptions;

  //   const ShareOptionsPage({
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
  //     required this.onWhatsAppShare,
  //     required this.onImageShare,
  //     required this.onPDFShare,
  //     required this.onLinkShare,
  //     required this.onToggleOptions,
  //   }) : super(key: key);

  //   @override
  //   _ShareOptionsPageState createState() => _ShareOptionsPageState();
  // }

  // class _ShareOptionsPageState extends State<ShareOptionsPage> {
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

  //   @override
  //   Widget build(BuildContext context) {
  //     final isLargeScreen = MediaQuery.of(context).size.width > 600;

  //     return Container(
  //       padding: EdgeInsets.all(isLargeScreen ? 24.0 : 16.0),
  //       child: SingleChildScrollView(
  //         child: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Text(
  //               'Share Options',
  //               style: TextStyle(
  //                 fontSize: isLargeScreen ? 22 : 18,
  //                 fontWeight: FontWeight.bold,
  //               ),
  //             ),
  //             const SizedBox(height: 20),
  //             Wrap(
  //               spacing: 8,
  //               runSpacing: 8,
  //               children: [
  //                 ElevatedButton.icon(
  //                   onPressed: () => widget.onWhatsAppShare(
  //                     includeDesign: includeDesign,
  //                     includeShade: includeShade,
  //                     includeRate: includeRate,
  //                     includeSize: includeSize,
  //                     includeProduct: includeProduct,
  //                     includeRemark: includeRemark,
  //                   ),
  //                   icon: Icon(Icons.message),
  //                   label: Text('WhatsApp'),
  //                   style: ElevatedButton.styleFrom(
  //                     backgroundColor: AppColors.primaryColor,
  //                     foregroundColor: Colors.white,
  //                     padding: EdgeInsets.symmetric(
  //                       horizontal: isLargeScreen ? 24 : 16,
  //                       vertical: 12,
  //                     ),
  //                   ),
  //                 ),
  //                 ElevatedButton.icon(
  //                   onPressed: () => widget.onImageShare(
  //                     includeDesign: includeDesign,
  //                     includeShade: includeShade,
  //                     includeRate: includeRate,
  //                     includeWsp: includeWsp,
  //                     includeSize: includeSize,
  //                     includeSizeMrp: includeSizeMrp,
  //                     includeSizeWsp: includeSizeWsp,
  //                     includeProduct: includeProduct,
  //                     includeRemark: includeRemark,
  //                   ),
  //                   icon: Icon(Icons.image),
  //                   label: Text('Image'),
  //                   style: ElevatedButton.styleFrom(
  //                     backgroundColor: AppColors.primaryColor,
  //                     foregroundColor: Colors.white,
  //                     padding: EdgeInsets.symmetric(
  //                       horizontal: isLargeScreen ? 24 : 16,
  //                       vertical: 12,
  //                     ),
  //                   ),
  //                 ),
  //                 ElevatedButton.icon(
  //                   onPressed: () => widget.onPDFShare(
  //                     includeDesign: includeDesign,
  //                     includeShade: includeShade,
  //                     includeRate: includeRate,
  //                     includeWsp: includeWsp,
  //                     includeSize: includeSize,
  //                     includeSizeMrp: includeSizeMrp,
  //                     includeSizeWsp: includeSizeWsp,
  //                     includeProduct: includeProduct,
  //                     includeRemark: includeRemark,
  //                   ),
  //                   icon: Icon(Icons.picture_as_pdf),
  //                   label: Text('PDF'),
  //                   style: ElevatedButton.styleFrom(
  //                     backgroundColor: AppColors.primaryColor,
  //                     foregroundColor: Colors.white,
  //                     padding: EdgeInsets.symmetric(
  //                       horizontal: isLargeScreen ? 24 : 16,
  //                       vertical: 12,
  //                     ),
  //                   ),
  //                 ),
  //                 ElevatedButton.icon(
  //                   onPressed: widget.onLinkShare,
  //                   icon: Icon(Icons.link),
  //                   label: Text('Share as Link'),
  //                   style: ElevatedButton.styleFrom(
  //                     backgroundColor: AppColors.primaryColor,
  //                     foregroundColor: Colors.white,
  //                     padding: EdgeInsets.symmetric(
  //                       horizontal: isLargeScreen ? 24 : 16,
  //                       vertical: 12,
  //                     ),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //             const SizedBox(height: 20),
  //             Text(
  //               'Include in Share',
  //               style: TextStyle(
  //                 fontSize: isLargeScreen ? 18 : 16,
  //                 fontWeight: FontWeight.bold,
  //               ),
  //             ),
  //             const SizedBox(height: 10),
  //             _buildToggleRow('Design', includeDesign, (val) {
  //               setState(() => includeDesign = val);
  //               widget.onToggleOptions(
  //                 includeDesign,
  //                 includeShade,
  //                 includeRate,
  //                 includeWsp,
  //                 includeSize,
  //                 includeSizeMrp,
  //                 includeSizeWsp,
  //                 includeProduct,
  //                 includeRemark,
  //               );
  //             }),
  //             _buildToggleRow('Shade', includeShade, (val) {
  //               setState(() => includeShade = val);
  //               widget.onToggleOptions(
  //                 includeDesign,
  //                 includeShade,
  //                 includeRate,
  //                 includeWsp,
  //                 includeSize,
  //                 includeSizeMrp,
  //                 includeSizeWsp,
  //                 includeProduct,
  //                 includeRemark,
  //               );
  //             }),
  //             _buildToggleRow('Rate', includeRate, (val) {
  //               setState(() => includeRate = val);
  //               widget.onToggleOptions(
  //                 includeDesign,
  //                 includeShade,
  //                 includeRate,
  //                 includeWsp,
  //                 includeSize,
  //                 includeSizeMrp,
  //                 includeSizeWsp,
  //                 includeProduct,
  //                 includeRemark,
  //               );
  //             }),
  //             _buildToggleRow('WSP', includeWsp, (val) {
  //               setState(() => includeWsp = val);
  //               widget.onToggleOptions(
  //                 includeDesign,
  //                 includeShade,
  //                 includeRate,
  //                 includeWsp,
  //                 includeSize,
  //                 includeSizeMrp,
  //                 includeSizeWsp,
  //                 includeProduct,
  //                 includeRemark,
  //               );
  //             }),
  //             _buildToggleRow('Size', includeSize, (val) {
  //               setState(() => includeSize = val);
  //               widget.onToggleOptions(
  //                 includeDesign,
  //                 includeShade,
  //                 includeRate,
  //                 includeWsp,
  //                 includeSize,
  //                 includeSizeMrp,
  //                 includeSizeWsp,
  //                 includeProduct,
  //                 includeRemark,
  //               );
  //             }),
  //             _buildToggleRow('Size MRP', includeSizeMrp, (val) {
  //               setState(() => includeSizeMrp = val);
  //               widget.onToggleOptions(
  //                 includeDesign,
  //                 includeShade,
  //                 includeRate,
  //                 includeWsp,
  //                 includeSize,
  //                 includeSizeMrp,
  //                 includeSizeWsp,
  //                 includeProduct,
  //                 includeRemark,
  //               );
  //             }),
  //             _buildToggleRow('Size WSP', includeSizeWsp, (val) {
  //               setState(() => includeSizeWsp = val);
  //               widget.onToggleOptions(
  //                 includeDesign,
  //                 includeShade,
  //                 includeRate,
  //                 includeWsp,
  //                 includeSize,
  //                 includeSizeMrp,
  //                 includeSizeWsp,
  //                 includeProduct,
  //                 includeRemark,
  //               );
  //             }),
  //             _buildToggleRow('Product', includeProduct, (val) {
  //               setState(() => includeProduct = val);
  //               widget.onToggleOptions(
  //                 includeDesign,
  //                 includeShade,
  //                 includeRate,
  //                 includeWsp,
  //                 includeSize,
  //                 includeSizeMrp,
  //                 includeSizeWsp,
  //                 includeProduct,
  //                 includeRemark,
  //               );
  //             }),
  //             _buildToggleRow('Remark', includeRemark, (val) {
  //               setState(() => includeRemark = val);
  //               widget.onToggleOptions(
  //                 includeDesign,
  //                 includeShade,
  //                 includeRate,
  //                 includeWsp,
  //                 includeSize,
  //                 includeSizeMrp,
  //                 includeSizeWsp,
  //                 includeProduct,
  //                 includeRemark,
  //               );
  //             }),
  //             const SizedBox(height: 20),
  //             Align(
  //               alignment: Alignment.centerRight,
  //               child: TextButton(
  //                 onPressed: () => Navigator.pop(context),
  //                 child: Text(
  //                   'Close',
  //                   style: TextStyle(fontSize: isLargeScreen ? 18 : 16),
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //     );
  //   }

  //   Widget _buildToggleRow(String title, bool value, Function(bool) onChanged) {
  //     return Row(
  //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //       children: [
  //         Text(title, style: TextStyle(fontSize: 16)),
  //         Switch(value: value, onChanged: onChanged),
  //       ],
  //     );
  //   }
}
