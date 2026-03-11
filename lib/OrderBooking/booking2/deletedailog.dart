import 'package:flutter/material.dart';

class DeleteConfirmationDialog extends StatelessWidget {
  final String styleCode;
  final VoidCallback onConfirm;

  const DeleteConfirmationDialog({
    Key? key,
    required this.styleCode,
    required this.onConfirm,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      elevation: 24,
      titlePadding: const EdgeInsets.all(24),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      actionsPadding: const EdgeInsets.only(right: 16, bottom: 16, left: 16),
      icon: _buildIcon(),
      title: _buildTitle(context),
      content: _buildContent(context),
      actions: _buildActions(context),
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 56, height: 56,
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.delete_outline_rounded, color: Colors.red.shade400, size: 32),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text("Delete Style",
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600, color: Colors.grey.shade800
          )
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      _buildStyleInfoCard(),
      const SizedBox(height: 20),
      _buildWarningBanner(),
    ]);
  }

  Widget _buildStyleInfoCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(children: [
        Icon(Icons.style_rounded, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Style Code", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            Text(styleCode, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        )),
      ]),
    );
  }

  Widget _buildWarningBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade100),
      ),
      child: Row(children: [
        Icon(Icons.warning_amber_rounded, size: 20, color: Colors.amber.shade700),
        const SizedBox(width: 8),
        Expanded(child: Text("This action cannot be undone",
          style: TextStyle(fontSize: 13, color: Colors.amber.shade800, fontWeight: FontWeight.w500)
        )),
      ]),
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    return [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        style: TextButton.styleFrom(
          foregroundColor: Colors.grey.shade700,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
        child: const Text("Cancel", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
      ),
      ElevatedButton(
        onPressed: () {
          Navigator.pop(context, true);
          onConfirm();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade600,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.delete_outline, size: 20),
          const SizedBox(width: 8),
          const Text("Delete Style", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        ]),
      ),
    ];
  }
}