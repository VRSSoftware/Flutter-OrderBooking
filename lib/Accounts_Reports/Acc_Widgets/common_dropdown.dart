import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:vrs_erp/constants/app_constants.dart';

class MultiSelectConfig<T> {
  final List<T> items;
  final List<T> selectedItems;
  final Function(List<T>) onChanged;
  final String Function(T) displayName;
  final String hintText;
  final String searchHintText;
  final bool isLoading;
  final Widget? loadingWidget;
  final Color? primaryColor;

  const MultiSelectConfig({
    required this.items,
    required this.selectedItems,
    required this.onChanged,
    required this.displayName,
    this.hintText = 'Select items',
    this.searchHintText = 'Search...',
    this.isLoading = false,
    this.loadingWidget,
    this.primaryColor,
  });
}

class CommonMultiSelectDropdown<T> extends StatefulWidget {
  final MultiSelectConfig<T> config;
  final VoidCallback? onDropdownOpen;
  final VoidCallback? onDropdownClose;

  const CommonMultiSelectDropdown({
    super.key,
    required this.config,
    this.onDropdownOpen,
    this.onDropdownClose,
  });

  @override
  State<CommonMultiSelectDropdown<T>> createState() =>
      _CommonMultiSelectDropdownState<T>();
}

class _CommonMultiSelectDropdownState<T>
    extends State<CommonMultiSelectDropdown<T>> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<T> _tempSelectedItems = [];
  bool _isDropdownOpen = false;
  final GlobalKey _containerKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  ScrollController? _scrollController;

  List<T> get _filteredItems {
    if (_searchQuery.isEmpty) return widget.config.items;
    return widget.config.items.where((item) {
      final displayName = widget.config.displayName(item).toLowerCase();
      return displayName.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  String get _displayText {
    if (widget.config.selectedItems.isEmpty) {
      return widget.config.hintText;
    }
    if (widget.config.selectedItems.length == 1) {
      return widget.config.displayName(widget.config.selectedItems.first);
    }
    final firstTwo = widget.config.selectedItems
        .take(2)
        .map((e) => widget.config.displayName(e))
        .join(', ');
    if (widget.config.selectedItems.length > 2) {
      return '$firstTwo... (${widget.config.selectedItems.length})';
    }
    return firstTwo;
  }

  @override
  void initState() {
    super.initState();
    _tempSelectedItems = List.from(widget.config.selectedItems);
    _findAndListenToScrollController();
  }

  void _findAndListenToScrollController() {
    // Find the scrollable widget in the tree
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      // Try to get the primary scroll controller
      _scrollController = PrimaryScrollController.maybeOf(context);
      
      if (_scrollController != null) {
        _scrollController!.addListener(_onScroll);
      } else {
        // If no primary controller, try to find any scrollable
        final ScrollableState? scrollable = Scrollable.maybeOf(context);
        if (scrollable != null && scrollable.widget.controller != null) {
          _scrollController = scrollable.widget.controller;
          _scrollController!.addListener(_onScroll);
        }
      }
    });
  }

  void _onScroll() {
    if (_isDropdownOpen && mounted) {
      _closeDropdown();
    }
  }

  @override
  void didUpdateWidget(covariant CommonMultiSelectDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config.selectedItems != widget.config.selectedItems) {
      _tempSelectedItems = List.from(widget.config.selectedItems);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _closeDropdown();
    if (_scrollController != null) {
      _scrollController!.removeListener(_onScroll);
    }
    super.dispose();
  }

  void _openDropdown() {
    if (_isDropdownOpen) return;
    
    widget.onDropdownOpen?.call();
    
    _tempSelectedItems = List.from(widget.config.selectedItems);

    final RenderBox renderBox =
        _containerKey.currentContext!.findRenderObject() as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => _buildDropdownOverlay(offset, size),
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _isDropdownOpen = true;
    });
  }

  void _closeDropdown() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
    if (_isDropdownOpen) {
      widget.onDropdownClose?.call();
    }
    if (mounted) {
      setState(() {
        _isDropdownOpen = false;
        _searchQuery = '';
        _searchController.clear();
      });
    }
  }

  void _applyAndClose() {
    widget.config.onChanged(_tempSelectedItems);
    _closeDropdown();
  }

  Widget _buildDropdownOverlay(Offset offset, Size size) {
    final colorPrimary = widget.config.primaryColor ?? AppColors.primaryColor;
    final screenHeight = MediaQuery.of(context).size.height;
    
    double topPosition = offset.dy + size.height + 5;
    double bottomPosition = screenHeight - topPosition;
    
    if (bottomPosition < 200 && offset.dy > 200) {
      topPosition = offset.dy - 250;
    }
    
    double dropdownHeight = 400;
    if (bottomPosition < 400 && topPosition > 200) {
      dropdownHeight = bottomPosition - 20;
    } else if (topPosition + 400 > screenHeight) {
      dropdownHeight = screenHeight - topPosition - 20;
    }
    
    dropdownHeight = dropdownHeight.clamp(150.0, 400.0);

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: _closeDropdown,
            behavior: HitTestBehavior.translucent,
          ),
        ),
        Positioned(
          top: topPosition,
          left: offset.dx,
          width: size.width,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: BoxConstraints(maxHeight: dropdownHeight),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: StatefulBuilder(
                builder: (context, setOverlayState) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.config.items.length > 5)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextField(
                            controller: _searchController,
                            autofocus: true,
                            decoration: InputDecoration(
                              hintText: widget.config.searchHintText,
                              hintStyle: GoogleFonts.poppins(fontSize: 13),
                              prefixIcon: const Icon(Icons.search, size: 20),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () {
                                        setState(() {
                                          _searchQuery = '';
                                          _searchController.clear();
                                        });
                                        setOverlayState(() {});
                                      },
                                    )
                                  : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: colorPrimary, width: 1.5),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                              setOverlayState(() {});
                            },
                          ),
                        ),
                      widget.config.isLoading
                          ? SizedBox(
                              height: 150,
                              child: Center(
                                child: widget.config.loadingWidget ??
                                    LoadingAnimationWidget.waveDots(
                                      color: colorPrimary,
                                      size: 40,
                                    ),
                              ),
                            )
                          : _filteredItems.isEmpty
                              ? SizedBox(
                                  height: 150,
                                  child: Center(
                                    child: Text(
                                      'No items found',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ),
                                )
                              : Flexible(
                                  child: ListView.builder(
                                    key: ValueKey(_searchQuery),
                                    shrinkWrap: true,
                                    itemCount: _filteredItems.length,
                                    itemBuilder: (context, index) {
                                      final item = _filteredItems[index];
                                      final isSelected = _tempSelectedItems.any(
                                        (selected) =>
                                            widget.config.displayName(selected) ==
                                            widget.config.displayName(item),
                                      );
                                      return InkWell(
                                        onTap: () {
                                          setState(() {
                                            if (isSelected) {
                                              _tempSelectedItems.removeWhere(
                                                (selected) =>
                                                    widget.config.displayName(selected) ==
                                                    widget.config.displayName(item),
                                              );
                                            } else {
                                              _tempSelectedItems.add(item);
                                            }
                                          });
                                          setOverlayState(() {});
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          color: isSelected
                                              ? colorPrimary.withOpacity(0.1)
                                              : Colors.transparent,
                                          child: Row(
                                            children: [
                                              Checkbox(
                                                value: isSelected,
                                                onChanged: (checked) {
                                                  setState(() {
                                                    if (checked == true) {
                                                      _tempSelectedItems.add(item);
                                                    } else {
                                                      _tempSelectedItems.removeWhere(
                                                        (selected) =>
                                                            widget.config.displayName(selected) ==
                                                            widget.config.displayName(item),
                                                      );
                                                    }
                                                  });
                                                  setOverlayState(() {});
                                                },
                                                activeColor: colorPrimary,
                                                materialTapTargetSize:
                                                    MaterialTapTargetSize.shrinkWrap,
                                              ),
                                              Expanded(
                                                child: Text(
                                                  widget.config.displayName(item),
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 13,
                                                    fontWeight: isSelected
                                                        ? FontWeight.w600
                                                        : FontWeight.normal,
                                                    color: isSelected
                                                        ? colorPrimary
                                                        : Colors.black87,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border(top: BorderSide(color: Colors.grey[200]!)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: _closeDropdown,
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.grey[600],
                              ),
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.poppins(fontSize: 13),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _applyAndClose,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorPrimary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                'OK',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorPrimary = widget.config.primaryColor ?? AppColors.primaryColor;

    return GestureDetector(
      key: _containerKey,
      onTap: _openDropdown,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _displayText,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: widget.config.selectedItems.isEmpty
                      ? Colors.grey[500]
                      : Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              _isDropdownOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
              color: Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }
}