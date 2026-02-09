import 'package:flutter/material.dart';
import 'package:vrs_erp/screens/mdns/MdnsServiceDiscovery.dart';

class MdnsDiscoveryScreen extends StatefulWidget {
  @override
  _MdnsDiscoveryScreenState createState() => _MdnsDiscoveryScreenState();
}

class _MdnsDiscoveryScreenState extends State<MdnsDiscoveryScreen> {
  String? discoveredUrl;
  bool isLoading = false;

  Future<void> discover() async {
    setState(() => isLoading = true);
    final url = await MdnsServiceDiscovery().discoverHostAndPort();
    setState(() {
      discoveredUrl = url ?? 'No service found';
      isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    discover(); // Auto discover on load
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('mDNS Discovery')),
      body: Center(
        child: isLoading
            ? CircularProgressIndicator()
            : Text(discoveredUrl ?? 'Searching...'),
      ),
    );
  }
}
