// import 'package:flutter/material.dart';
// import 'package:vrs_erp/constants/app_constants.dart';
// import 'package:vrs_erp/models/catalog.dart';
// import 'package:vrs_erp/widget/booknowwidget.dart';

// class CatalogItemCard extends StatelessWidget {
//   final Catalog catalog;
//   final bool isSelected;
//   final bool isLiked;
//   final VoidCallback onSelect;
//   final VoidCallback onLike;
//   final VoidCallback onAddToCart;
//   final double? width;
//   final double imageHeight;
//   final bool bookNowButton;

//   const CatalogItemCard({
//     Key? key,
//     required this.catalog,
//     required this.isSelected,
//     required this.isLiked,
//     required this.onSelect,
//     required this.onLike,
//     required this.onAddToCart,
//     this.width,
//     this.imageHeight = 200,
//     this.bookNowButton = true,
//   }) : super(key: key);

//   String _getImageUrl() {
//     if (catalog.fullImagePath.isEmpty || catalog.fullImagePath.contains(' ')) {
//       return ''; // Will trigger fallback
//     }

//     if (catalog.fullImagePath.startsWith('http')) {
//       return catalog.fullImagePath;
//     }

//     final imageName = catalog.fullImagePath.split('/').last.split('?').first;
//     return '${AppConstants.BASE_URL}/images/$imageName';
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isDarkMode = Theme.of(context).brightness == Brightness.dark;

//     return LayoutBuilder(
//       builder: (context, constraints) {
//         final isSmallScreen = constraints.maxWidth < 600;

//         return SizedBox(
//           width: width ?? double.infinity,
//           child: Card(
//             clipBehavior: Clip.antiAlias,
//             margin: const EdgeInsets.all(8),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(12),
//               side: BorderSide(
//                 color: isSelected
//                     ? const Color.fromARGB(255, 228, 36, 36)
//                     : Colors.grey.shade300,
//                 width: isSelected ? 2 : 1,
//               ),
//             ),
//             elevation: 2,
//             child: InkWell(
//               onTap: onSelect,
//               borderRadius: BorderRadius.circular(12),
//               child: Stack(
//                 children: [
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.stretch,
//                     children: [
//                       _buildImageSection(constraints),
//                       if (!isSmallScreen)
//                         _buildDetailsSection(isDarkMode, context),
//                       if (isSmallScreen)
//                         Padding(
//                           padding: const EdgeInsets.all(8.0),
//                           child: _buildDetailsSection(isDarkMode, context),
//                         ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildImageSection(BoxConstraints constraints) {
//     final imageUrl = _getImageUrl();

//     return Stack(
//       children: [
//         ClipRRect(
//           borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
//           child: imageUrl.isEmpty
//               ? _buildImageError()
//               : Image.network(
//                   imageUrl,
//                   fit: BoxFit.fitWidth,
//                   width: double.infinity,
//                   height: imageHeight,
//                   loadingBuilder: (context, child, loadingProgress) {
//                     if (loadingProgress == null) return child;
//                     return const Center(child: CircularProgressIndicator());
//                   },
//                   errorBuilder: (context, error, stackTrace) =>
//                       _buildImageError(),
//                 ),
//         ),
//         if (isSelected)
//           Positioned(top: 8, left: 8, child: _buildSelectedIndicator()),
//       ],
//     );
//   }

//   Widget _buildImageError() {
//     return Image.asset(
//       'assets/images/default.png',
//       fit: BoxFit.cover,
//       width: double.infinity,
//       height: imageHeight,
//     );
//   }

//   Widget _buildSelectedIndicator() {
//     return Container(
//       padding: const EdgeInsets.all(4),
//       decoration: BoxDecoration(
//         color: AppColors.primaryColor.withOpacity(0.8),
//         shape: BoxShape.circle,
//       ),
//       child: const Icon(Icons.check, color: Colors.white, size: 16),
//     );
//   }

//   Widget _buildLikeButton() {
//     return Container(
//       decoration: BoxDecoration(
//         shape: BoxShape.circle,
//         color: isLiked ? Colors.red : Colors.transparent,
//       ),
//       child: IconButton(
//         icon: Icon(
//           isLiked ? Icons.favorite : Icons.favorite_border,
//           color: isLiked ? Colors.white : Colors.grey,
//           size: 24,
//         ),
//         onPressed: onLike,
//       ),
//     );
//   }

//   Widget _buildDetailsSection(bool isDarkMode, BuildContext context) {
//     final greyColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Text(
//               catalog.styleCode,
//               style:
//                   const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
//               maxLines: 1,
//               overflow: TextOverflow.ellipsis,
//             ),
//             _buildLikeButton(),
//           ],
//         ),
//         const SizedBox(height: 6),
//         if (catalog.shadeName.isNotEmpty)
//           _buildDetailRow('Shade', catalog.shadeName, greyColor),
//         if (catalog.sizeName.isNotEmpty)
//           _buildDetailRow('Size', catalog.sizeName, greyColor),
//         _buildDetailRow('MRP', '₹${catalog.mrp.toStringAsFixed(2)}', greyColor),
//         _buildDetailRow('WSP', '₹${catalog.wsp.toStringAsFixed(2)}', greyColor),
//         _buildStockRow(greyColor),
//         const SizedBox(height: 8),
//         if (bookNowButton) _buildBookNowButton(context),
//       ],
//     );
//   }

//   Widget _buildDetailRow(String label, String value, Color? color) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 2),
//       child: Text(
//         '$label: $value',
//         style: TextStyle(fontSize: 12, color: color),
//         maxLines: 1,
//         overflow: TextOverflow.ellipsis,
//       ),
//     );
//   }

//   Widget _buildStockRow(Color? color) {
//     return Row(
//       children: [
//         Text('Stock: ', style: TextStyle(fontSize: 12, color: color)),
//         Text(
//           catalog.clqty.toString(),
//           style: TextStyle(
//             fontSize: 12,
//             fontWeight: FontWeight.w500,
//             color: catalog.clqty > 0 ? Colors.green : Colors.red,
//           ),
//         ),
//       ],
//     );
//   }

//   // Widget _buildBookNowButton(BuildContext context) {
//   //   return SizedBox(
//   //     width: double.infinity,
//   //     child: ElevatedButton(
//   //       style: ElevatedButton.styleFrom(
//   //         backgroundColor: AppColors.primaryColor,
//   //         padding: const EdgeInsets.symmetric(vertical: 10),
//   //         shape: RoundedRectangleBorder(
//   //           borderRadius: BorderRadius.circular(8),
//   //         ),
//   //       ),
//   //       onPressed: () => _showBookingDialog(context),
//   //       child: const Text(
//   //         'Book Now',
//   //         style: TextStyle(
//   //           fontSize: 13,
//   //           fontWeight: FontWeight.w600,
//   //           color: AppColors.white,
//   //         ),
//   //       ),
//   //     ),
//   //   );
//   // }

//   // void _showBookingDialog(BuildContext context) {
//   //   showDialog(
//   //     context: context,
//   //     builder: (BuildContext context) {
//   //       return Dialog(
//   //         insetPadding: const EdgeInsets.all(16),
//   //         child: CatalogBookingTable(
//   //           itemSubGrpKey: catalog.itemSubGrpKey,
//   //           itemKey: catalog.itemKey,
//   //           styleKey: catalog.styleKey,
//   //         ),
//   //       );
//   //     },
//   //   );
//   // }
// }
