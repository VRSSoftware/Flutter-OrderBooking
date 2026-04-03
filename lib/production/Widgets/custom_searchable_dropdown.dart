import 'package:flutter/material.dart';
import 'package:vrs_erp/constants/app_constants.dart';

class CustomSearchableDropdown extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final List<Map<String, dynamic>> items;
  final Map<String, dynamic>? selected;
  final ValueChanged<Map<String, dynamic>?> onChanged;
  final FocusNode focusNode;
  final bool isRequired;
  final bool isLoading;
  final bool showClearButton;
  final bool allowClear;

  const CustomSearchableDropdown({
    super.key,
    required this.label,
    required this.controller,
    required this.items,
    required this.selected,
    required this.onChanged,
    required this.focusNode,
    this.isRequired = false,
    this.isLoading = false,
    this.showClearButton = true,
    this.allowClear = true,
  });

  @override
  State<CustomSearchableDropdown> createState() => _CustomSearchableDropdownState();
}

class _CustomSearchableDropdownState extends State<CustomSearchableDropdown> {
  late FocusNode _internalFocusNode;
  OverlayEntry? _overlayEntry;
  final TextEditingController _searchController = TextEditingController();
  bool _isFocused = false;
  bool _isDropdownOpen = false;

  @override
  void initState() {
    super.initState();
    _internalFocusNode = widget.focusNode;
    _internalFocusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _internalFocusNode.hasFocus;
      if (!_isFocused) {
        _closeDropdown();
      }
    });
  }

  void _toggleDropdown() {
    if (_isDropdownOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    if (_isDropdownOpen || widget.items.isEmpty) return;

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final double height = renderBox.size.height;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double spaceBelow = screenHeight - offset.dy - height;
    final double spaceAbove = offset.dy;
    
    final bool openBelow = spaceBelow > 250;
    double maxHeight = openBelow 
        ? (spaceBelow - 10).clamp(150.0, 350.0)
        : (spaceAbove - 10).clamp(150.0, 350.0);
    
    // Remove all gaps - position exactly at the bottom/top edge
    final double topPosition = openBelow 
        ? offset.dy + height  // Exactly at bottom edge (no gap)
        : offset.dy - maxHeight; // Exactly at top edge (no gap)

    List<Map<String, dynamic>> filteredItems = List.from(widget.items);

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeDropdown,
              child: Container(color: Colors.transparent),
            ),
          ),
          Positioned(
            left: offset.dx,
            top: topPosition,
            width: renderBox.size.width,
            child: Material(
              elevation: 8,
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: maxHeight,
                  minHeight: 100,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Search field
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: TextField(
                          controller: _searchController,
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: 'Search ${widget.label}...',
                            hintStyle: const TextStyle(fontSize: 13),
                            prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.primaryColor),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 10,
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.close, size: 16),
                                    onPressed: () {
                                      _searchController.clear();
                                      filteredItems = List.from(widget.items);
                                      _overlayEntry?.markNeedsBuild();
                                    },
                                  )
                                : null,
                          ),
                          onChanged: (query) {
                            filteredItems = widget.items
                                .where((e) => e['name']
                                    .toLowerCase()
                                    .contains(query.toLowerCase()))
                                .toList();
                            _overlayEntry?.markNeedsBuild();
                          },
                        ),
                      ),
                    ),
                    // Add "Clear Selection" option at the top if a value is selected
                    if (widget.allowClear && widget.selected != null)
                      Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey.shade200,
                              width: 1,
                            ),
                          ),
                        ),
                        child: ListTile(
                          dense: true,
                          leading: const Icon(Icons.clear, size: 18, color: Colors.red),
                          title: const Text(
                            'Clear Selection',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.red,
                            ),
                          ),
                          onTap: () {
                            _clearSelection();
                            _closeDropdown();
                          },
                        ),
                      ),
                    // List items
                    Expanded(
                      child: filteredItems.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: Text(
                                  'No items found',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const BouncingScrollPhysics(),
                              padding: EdgeInsets.zero,
                              itemCount: filteredItems.length,
                              itemBuilder: (c, i) {
                                final item = filteredItems[i];
                                final isSelected = widget.selected != null && 
                                    widget.selected?['key'] == item['key'];
                                
                                return ListTile(
                                  dense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 0,
                                  ),
                                  title: Text(
                                    item['name'],
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                      color: isSelected ? AppColors.primaryColor : Colors.black87,
                                    ),
                                  ),
                                  selected: isSelected,
                                  selectedTileColor: AppColors.primaryColor.withOpacity(0.1),
                                  trailing: isSelected
                                      ? const Icon(Icons.check, size: 16, color: AppColors.primaryColor)
                                      : null,
                                  onTap: () {
                                    setState(() {
                                      widget.onChanged(item);
                                      widget.controller.text = item['name'];
                                      _searchController.clear();
                                    });
                                    _closeDropdown();
                                  },
                                );
                              },
                            ),
                    ),
                    // Item count
                    if (filteredItems.length > 10)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          '${filteredItems.length} items',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    setState(() {
      _isDropdownOpen = true;
    });
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _closeDropdown() {
    if (_overlayEntry != null) {
      _overlayEntry?.remove();
      _overlayEntry = null;
      _searchController.clear();
      setState(() {
        _isDropdownOpen = false;
      });
    }
  }

  void _clearSelection() {
    setState(() {
      widget.onChanged(null);
      widget.controller.clear();
    });
  }

  @override
  void dispose() {
    _internalFocusNode.removeListener(_onFocusChange);
    _closeDropdown();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 4),
            child: Row(
              children: [
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
                if (widget.isRequired)
                  Text(
                    ' *',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red.shade400,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
          widget.isLoading
              ? Container(
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Center(
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                )
              : GestureDetector(
                  onTap: _toggleDropdown,
                  child: Focus(
                    focusNode: _internalFocusNode,
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _internalFocusNode.hasFocus 
                              ? AppColors.primaryColor 
                              : Colors.grey.shade300,
                          width: _internalFocusNode.hasFocus ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.controller.text.isEmpty 
                                  ? 'Select ${widget.label}' 
                                  : widget.controller.text,
                              style: TextStyle(
                                fontSize: 14,
                                color: widget.controller.text.isEmpty 
                                    ? Colors.grey.shade400 
                                    : Colors.black87,
                              ),
                            ),
                          ),
                          if (widget.showClearButton && 
                              widget.allowClear &&
                              widget.selected != null && 
                              _isFocused)
                            GestureDetector(
                              onTap: _clearSelection,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                child: const Icon(
                                  Icons.close,
                                  size: 18,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          const SizedBox(width: 4),
                          AnimatedRotation(
                            duration: const Duration(milliseconds: 200),
                            turns: _isDropdownOpen ? 0.5 : 0.0,
                            child: Icon(
                              Icons.arrow_drop_down,
                              size: 22,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}