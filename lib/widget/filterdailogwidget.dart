import 'package:flutter/material.dart';
import 'package:vrs_erp/constants/app_constants.dart';


class FilterMenuWidget extends StatefulWidget {
  final Set<String> initialFilters;
  final void Function(Set<String>) onApply;
  final VoidCallback onCancel;

  const FilterMenuWidget({
    super.key,
    required this.initialFilters,
    required this.onApply,
    required this.onCancel,
  });

  @override
  State<FilterMenuWidget> createState() => _FilterMenuWidgetState();
}

class _FilterMenuWidgetState extends State<FilterMenuWidget> {
  late Set<String> _selectedFilters;

  @override
  void initState() {
    super.initState();
    _selectedFilters = Set.from(widget.initialFilters);
  }

  Widget _buildCheckbox(String label, String key) {
    return CheckboxListTile(
      title: Text(label),
      value: _selectedFilters.contains(key),
      onChanged: (bool? value) {
        setState(() {
          value ?? false
              ? _selectedFilters.add(key)
              : _selectedFilters.remove(key);
        });
      },
      dense: true,
      controlAffinity: ListTileControlAffinity.leading,
      activeColor: AppColors.primaryColor,  // Using AppColors.primaryColor
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: SizedBox(
        width: 165,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCheckbox('MRP', 'mrp'),
            _buildCheckbox('WSP', 'wsp'),
            _buildCheckbox('Shades', 'shades'),
            _buildCheckbox('Style Code', 'stylecode'),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                TextButton(
                  onPressed: widget.onCancel,
                  child: const Text('Cancel'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.primaryColor),  // Using AppColors.primaryColor for text color
                ),
                TextButton(
                  onPressed: () => widget.onApply(_selectedFilters),
                  child: const Text('Apply'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.primaryColor),  // Using AppColors.primaryColor for text color
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
