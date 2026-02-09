import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vrs_erp/catalog/dotIndicatorDesign.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/models/catalog.dart';

class ImageZoomScreen1 extends StatefulWidget {
  final List<String> imageUrls;
  final Catalog item;
  final bool showShades;
  final bool showMRP;
  final bool showWSP;
  final bool showSizes;
  final bool showProduct;
  final bool showRemark;
  final bool isLargeScreen;

  const ImageZoomScreen1({
    super.key,
    required this.imageUrls,
    required this.item,
    required this.showShades,
    required this.showMRP,
    required this.showWSP,
    required this.showSizes,
    required this.showProduct,
    required this.showRemark,
    required this.isLargeScreen,
  });

  @override
  State<ImageZoomScreen1> createState() => _ImageZoomScreen1State();
}

class _ImageZoomScreen1State extends State<ImageZoomScreen1> {
  int _currentPageIndex = 0;

  // Text style for values
  TextStyle _valueTextStyle() {
    return TextStyle(
      fontSize: widget.isLargeScreen ? 16 : 14,
      color: Colors.grey[800],
      fontWeight: FontWeight.w400,
    );
  }

  // Text style for labels
  Widget _buildLabelText(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: widget.isLargeScreen ? 16 : 14,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  // Spacer row for consistent spacing
  TableRow _buildSpacerRow() {
    return const TableRow(
      children: [
        SizedBox(height: 12),
        SizedBox(height: 12),
        SizedBox(height: 12),
      ],
    );
  }

  void _openFullScreen(BuildContext context, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenImage(
          imageUrl: widget.imageUrls[index],
          tag: 'fullscreen-${widget.item.styleCode}-$index',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Split shades with null safety
    List<String> shades = widget.item.shadeName.isNotEmpty
        ? widget.item.shadeName.split(',').map((shade) => shade.trim()).toList()
        : [];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 3,
        title: Text(
          widget.item.styleCode,
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: widget.isLargeScreen ? 22 : 20,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.fullscreen),
            onPressed: () => _openFullScreen(context, _currentPageIndex),
          ),
        ],
      ),
      body: Column(
        children: [
          // Image Carousel Section
          Expanded(
            child: PageView.builder(
              itemCount: widget.imageUrls.length,
              onPageChanged: (index) => setState(() => _currentPageIndex = index),
              itemBuilder: (context, index) {
                return GestureDetector(
                  onDoubleTap: () => _openFullScreen(context, index),
                  child: Hero(
                    tag: 'fullscreen-${widget.item.styleCode}-$index',
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: InteractiveViewer(
                          panEnabled: true,
                          minScale: 1.0,
                          maxScale: 4.0,
                          child: Image.network(
                            widget.imageUrls[index],
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                child: const Center(
                                  child: Icon(
                                    Icons.error,
                                    color: Colors.red,
                                    size: 40,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Dot Indicator for multiple images
          if (widget.imageUrls.length > 1)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: DotIndicator(
                count: widget.imageUrls.length,
                currentIndex: _currentPageIndex,
              ),
            ),

          // Description Section
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: EdgeInsets.all(widget.isLargeScreen ? 20 : 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Table(
              columnWidths: const {
                0: IntrinsicColumnWidth(),
                1: FixedColumnWidth(12),
                2: FlexColumnWidth(),
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                // 1. Design
                TableRow(
                  children: [
                    _buildLabelText('Design'),
                    const Text(':'),
                    Text(
                      widget.item.styleCodeWithcount,
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: widget.isLargeScreen ? 18 : 16,
                      ),
                    ),
                  ],
                ),
                _buildSpacerRow(),

                // 2. Brand
                TableRow(
                  children: [
                    _buildLabelText('Brand'),
                    const Text(':'),
                    Text(
                      widget.item.brandName,
                      style: _valueTextStyle(),
                    ),
                  ],
                ),
                _buildSpacerRow(),

                // 3. Shade
                if (widget.showShades && shades.isNotEmpty)
                  TableRow(
                    children: [
                      _buildLabelText('Shade'),
                      const Text(':'),
                      Text(
                        shades.join(', '),
                        style: _valueTextStyle(),
                      ),
                    ],
                  ),
                if (widget.showShades && shades.isNotEmpty) _buildSpacerRow(),

                // 4. MRP
                if (widget.showMRP)
                  TableRow(
                    children: [
                      _buildLabelText('MRP'),
                      const Text(':'),
                      Text(
                        widget.item.mrp.toStringAsFixed(2),
                        style: _valueTextStyle(),
                      ),
                    ],
                  ),
                if (widget.showMRP) _buildSpacerRow(),

                // 5. WSP
                if (widget.showWSP)
                  TableRow(
                    children: [
                      _buildLabelText('WSP'),
                      const Text(':'),
                      Text(
                        widget.item.wsp.toStringAsFixed(2),
                        style: _valueTextStyle(),
                      ),
                    ],
                  ),
                if (widget.showWSP) _buildSpacerRow(),

                // 6. Size
                if (widget.item.sizeWithMrp.isNotEmpty && widget.showSizes)
                  TableRow(
                    children: [
                      _buildLabelText('Size'),
                      const Text(':'),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Text(
                          widget.item.sizeWithMrp,
                          style: _valueTextStyle(),
                        ),
                      ),
                    ],
                  ),
                if (widget.item.sizeWithMrp.isNotEmpty && widget.showSizes) _buildSpacerRow(),

                // 7. Product
                if (widget.showProduct)
                  TableRow(
                    children: [
                      _buildLabelText('Product'),
                      const Text(':'),
                      Text(
                        widget.item.itemName,
                        style: _valueTextStyle(),
                      ),
                    ],
                  ),
                if (widget.showProduct) _buildSpacerRow(),

                // 8. Quantity
                TableRow(
                  children: [
                    _buildLabelText('Quantity'),
                    const Text(':'),
                    Text(
                      widget.item.clqty.toString(),
                      style: _valueTextStyle(),
                    ),
                  ],
                ),
                _buildSpacerRow(),

                // 9. Remark
                if (widget.showRemark)
                  TableRow(
                    children: [
                      _buildLabelText('Remark'),
                      const Text(':'),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Text(
                          widget.item.remark?.trim().isNotEmpty == true
                              ? widget.item.remark!
                              : '--',
                          style: _valueTextStyle(),
                        ),
                      ),
                    ],
                  ),
                if (widget.showRemark) _buildSpacerRow(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FullScreenImage extends StatelessWidget {
  final String imageUrl;
  final String tag;

  const FullScreenImage({
    super.key,
    required this.imageUrl,
    required this.tag,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: SizedBox.expand(
          child: Hero(
            tag: tag,
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 1.0,
              maxScale: 5.0,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(
                      Icons.error,
                      color: Colors.red,
                      size: 50,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
