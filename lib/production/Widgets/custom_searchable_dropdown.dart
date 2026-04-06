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
  bool _isDropdownOpen = false;
  bool _hasContent = false;

  @override
  void initState() {
    super.initState();
    _internalFocusNode = widget.focusNode;
    _hasContent = widget.controller.text.isNotEmpty;
    widget.controller.addListener(_updateHasContent);
  }

  void _updateHasContent() {
    final hasContent = widget.controller.text.isNotEmpty;
    if (_hasContent != hasContent) {
      setState(() {
        _hasContent = hasContent;
      });
    }
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
    
    final double topPosition = openBelow 
        ? offset.dy + height
        : offset.dy - maxHeight;

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
                            hintStyle: const TextStyle(fontSize: 12),
                            prefixIcon: const Icon(Icons.search, size: 16, color: AppColors.primaryColor),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 10,
                            ),
                            isDense: true,
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.close, size: 14),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
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
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                          leading: const Icon(Icons.clear, size: 16, color: Colors.red),
                          title: const Text(
                            'Clear Selection',
                            style: TextStyle(
                              fontSize: 12,
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
                                padding: EdgeInsets.all(16),
                                child: Text(
                                  'No items found',
                                  style: TextStyle(fontSize: 12),
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
                                      fontSize: 12,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                      color: isSelected ? AppColors.primaryColor : Colors.black87,
                                    ),
                                  ),
                                  selected: isSelected,
                                  selectedTileColor: AppColors.primaryColor.withOpacity(0.1),
                                  trailing: isSelected
                                      ? const Icon(Icons.check, size: 14, color: AppColors.primaryColor)
                                      : null,
                                  onTap: () {
                                    setState(() {
                                      widget.onChanged(item);
                                      widget.controller.text = item['name'];
                                      _hasContent = true;
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
                        padding: const EdgeInsets.all(6.0),
                        child: Text(
                          '${filteredItems.length} items',
                          style: TextStyle(
                            fontSize: 10,
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
      _hasContent = false;
    });
  }

  @override
  void dispose() {
    _closeDropdown();
    _searchController.dispose();
    widget.controller.removeListener(_updateHasContent);
    // Do NOT dispose _internalFocusNode because it's passed from parent
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isFocused = _internalFocusNode.hasFocus;
    final bool showLabel = isFocused || _hasContent;
    final Color borderColor = isFocused
        ? AppColors.primaryColor
        : (_hasContent ? AppColors.primaryColor.withOpacity(0.5) : Colors.grey.shade300);
    final double borderWidth = isFocused ? 1.5 : 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: widget.isLoading
          ? Container(
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300, width: 1),
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
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: borderColor,
                      width: borderWidth,
                    ),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Main content
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.controller.text.isEmpty 
                                    ? '' 
                                    : widget.controller.text,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (widget.showClearButton && 
                                widget.allowClear &&
                                widget.selected != null && 
                                isFocused)
                              GestureDetector(
                                onTap: _clearSelection,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  child: const Icon(
                                    Icons.close,
                                    size: 16,
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
                                size: 20,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Floating label
                      if (showLabel)
                        Positioned(
                          left: 12,
                          top: -8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            color: Colors.white,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.label,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: isFocused
                                        ? AppColors.primaryColor
                                        : (_hasContent
                                            ? AppColors.primaryColor.withOpacity(0.7)
                                            : Colors.grey.shade600),
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
                        ),
                        
                      // Placeholder text when no selection and label not shown
                      if (!showLabel && widget.controller.text.isEmpty)
                        Positioned(
                          left: 12,
                          top: 10,
                          child: Text(
                            'Select ${widget.label}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade400,
                            ),
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