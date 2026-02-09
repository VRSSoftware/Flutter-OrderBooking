import 'package:flutter/material.dart';
import 'package:vrs_erp/constants/app_constants.dart';


void showOrderMenu(BuildContext context, Offset position) async {
  final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

  await showMenu(
    context: context,
    position: RelativeRect.fromRect(
      position & const Size(40, 40), 
      Offset.zero & overlay.size, 
    ),
    items: [
      PopupMenuItem(
        child: ListTile(
          leading: Icon(Icons.add_shopping_cart, color: AppColors.primaryColor),
          title: const Text('View Order'),
          onTap: () {
             Navigator.pop(context);
      Navigator.pushNamed(context, '/viewOrder'); 
          },
        ),
      ),
      //    PopupMenuItem(
      //   child: ListTile(
      //     leading: Icon(Icons.add_shopping_cart, color: AppColors.primaryColor),
      //     title: const Text('View Order 1'),
      //     onTap: () {
      //        Navigator.pop(context); 
      // Navigator.pushNamed(context, '/viewOrders'); 
      //     },
      //   ),
      // ),
      PopupMenuItem(
        child: ListTile(
          leading: Icon(Icons.inventory, color: AppColors.primaryColor),
          title: const Text('My Orders'),
          onTap: () {
            Navigator.pop(context);
  
          },
        ),
      ),
      PopupMenuItem(
        child: ListTile(
          leading: Icon(Icons.favorite, color: AppColors.primaryColor),
          title: const Text('Favourite'),
          onTap: () {
            Navigator.pop(context);
     
          },
        ),
      ),
    ],
  );
}
