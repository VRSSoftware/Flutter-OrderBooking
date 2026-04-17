import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:vrs_erp/Masters/CommonWebViewMaster.dart';
import 'package:vrs_erp/constants/app_constants.dart';


class MastersHome extends StatefulWidget {
  const MastersHome({super.key});

  @override
  State<MastersHome> createState() => _MastersHomeState();
}

class _MastersHomeState extends State<MastersHome> {
  // List to store recently viewed items dynamically
  List<Map<String, dynamic>> recentlyViewedItems = [];

  // Search query
  String searchQuery = '';

  // Search mode flag
  bool isSearchMode = false;

  // Controller for search field
  final TextEditingController searchController = TextEditingController();

  // Speech to text
  stt.SpeechToText? _speech;
  bool _isListening = false;
  String _text = '';
  bool _speechAvailable = false;

  // All menu items for search functionality
  final List<Map<String, dynamic>> allMenuItems = [
    // Company Section
    {
      "title": "Company",
      "icon": Icons.business,
      "category": "Company",
      "urlPath": "company",
    },

    // Location Section
    {
      "title": "Region",
      "icon": Icons.map,
      "category": "Location",
      "urlPath": "region",
    },
    {
      "title": "Country",
      "icon": Icons.flag,
      "category": "Location",
      "urlPath": "country",
    },
    {
      "title": "State",
      "icon": Icons.location_city,
      "category": "Location",
      "urlPath": "state",
    },
    {
      "title": "Zone",
      "icon": Icons.grid_on,
      "category": "Location",
      "urlPath": "zone",
    },
    {
      "title": "Station",
      "icon": Icons.train,
      "category": "Location",
      "urlPath": "station",
    },

    // Personal Section
    {
      "title": "Department",
      "icon": Icons.account_tree,
      "category": "Personal",
      "urlPath": "department",
    },
    {
      "title": "Designation",
      "icon": Icons.work,
      "category": "Personal",
      "urlPath": "designation",
    },
    {
      "title": "Employee",
      "icon": Icons.people,
      "category": "Personal",
      "urlPath": "employee",
    },
    {
      "title": "Salesperson",
      "icon": Icons.person_outline,
      "category": "Personal",
      "urlPath": "salesperson",
    },

    // Customer Section
    {
      "title": "Customer",
      "icon": Icons.people_alt,
      "category": "Customer",
      "urlPath": "customer",
    },

    // Vendor Section
    {
      "title": "Supplier",
      "icon": Icons.local_shipping,
      "category": "Vendor",
      "urlPath": "supplier",
    },
    {
      "title": "Broker",
      "icon": Icons.account_balance_wallet,
      "category": "Vendor",
      "urlPath": "broker",
    },
    {
      "title": "Transporter",
      "icon": Icons.local_shipping,
      "category": "Vendor",
      "urlPath": "transporter",
    },

    // Product Section
    {
      "title": "Group",
      "icon": Icons.folder,
      "category": "Product",
      "urlPath": "group",
    },
    {
      "title": "Sub-group",
      "icon": Icons.subdirectory_arrow_right,
      "category": "Product",
      "urlPath": "sub-group",
    },
    {
      "title": "Product",
      "icon": Icons.inventory_2,
      "category": "Product",
      "urlPath": "product",
    },
    {
      "title": "Design",
      "icon": Icons.design_services,
      "category": "Product",
      "urlPath": "design",
    },
    {
      "title": "Type",
      "icon": Icons.category,
      "category": "Product",
      "urlPath": "type",
    },
    {
      "title": "Shade",
      "icon": Icons.color_lens,
      "category": "Product",
      "urlPath": "shade",
    },
    {
      "title": "Brand",
      "icon": Icons.branding_watermark,
      "category": "Product",
      "urlPath": "brand",
    },
    {
      "title": "Unit",
      "icon": Icons.straighten,
      "category": "Product",
      "urlPath": "unit",
    },
    {
      "title": "Quality",
      "icon": Icons.numbers,
      "category": "Product",
      "urlPath": "quality",
    },
    {
      "title": "Season",
      "icon": Icons.eco,
      "category": "Product",
      "urlPath": "season",
    },
    {
      "title": "Occassion",
      "icon": Icons.celebration,
      "category": "Product",
      "urlPath": "Occassion",
    },

    // Tax/Terms Section
    {
      "title": "Tax",
      "icon": Icons.receipt,
      "category": "Tax/Terms",
      "urlPath": "tax",
    },
    {
      "title": "Terms",
      "icon": Icons.description,
      "category": "Tax/Terms",
      "urlPath": "terms",
    },
    {
      "title": "Term Discount",
      "icon": Icons.discount,
      "category": "Tax/Terms",
      "urlPath": "term-discount",
    },
  ];

  // Get filtered menu items based on search query and category
  List<Map<String, dynamic>> get filteredCompanyItems {
    if (searchQuery.isEmpty) {
      return allMenuItems
          .where((item) => item['category'] == 'Company')
          .toList();
    }
    return allMenuItems
        .where(
          (item) =>
              item['category'] == 'Company' &&
              item['title'].toLowerCase().contains(searchQuery.toLowerCase()),
        )
        .toList();
  }

  List<Map<String, dynamic>> get filteredLocationItems {
    if (searchQuery.isEmpty) {
      return allMenuItems
          .where((item) => item['category'] == 'Location')
          .toList();
    }
    return allMenuItems
        .where(
          (item) =>
              item['category'] == 'Location' &&
              item['title'].toLowerCase().contains(searchQuery.toLowerCase()),
        )
        .toList();
  }

  List<Map<String, dynamic>> get filteredPersonalItems {
    if (searchQuery.isEmpty) {
      return allMenuItems
          .where((item) => item['category'] == 'Personal')
          .toList();
    }
    return allMenuItems
        .where(
          (item) =>
              item['category'] == 'Personal' &&
              item['title'].toLowerCase().contains(searchQuery.toLowerCase()),
        )
        .toList();
  }

  List<Map<String, dynamic>> get filteredCustomerItems {
    if (searchQuery.isEmpty) {
      return allMenuItems
          .where((item) => item['category'] == 'Customer')
          .toList();
    }
    return allMenuItems
        .where(
          (item) =>
              item['category'] == 'Customer' &&
              item['title'].toLowerCase().contains(searchQuery.toLowerCase()),
        )
        .toList();
  }

  List<Map<String, dynamic>> get filteredVendorItems {
    if (searchQuery.isEmpty) {
      return allMenuItems
          .where((item) => item['category'] == 'Vendor')
          .toList();
    }
    return allMenuItems
        .where(
          (item) =>
              item['category'] == 'Vendor' &&
              item['title'].toLowerCase().contains(searchQuery.toLowerCase()),
        )
        .toList();
  }

  List<Map<String, dynamic>> get filteredProductItems {
    if (searchQuery.isEmpty) {
      return allMenuItems
          .where((item) => item['category'] == 'Product')
          .toList();
    }
    return allMenuItems
        .where(
          (item) =>
              item['category'] == 'Product' &&
              item['title'].toLowerCase().contains(searchQuery.toLowerCase()),
        )
        .toList();
  }

  List<Map<String, dynamic>> get filteredTaxTermsItems {
    if (searchQuery.isEmpty) {
      return allMenuItems
          .where((item) => item['category'] == 'Tax/Terms')
          .toList();
    }
    return allMenuItems
        .where(
          (item) =>
              item['category'] == 'Tax/Terms' &&
              item['title'].toLowerCase().contains(searchQuery.toLowerCase()),
        )
        .toList();
  }

  // Check if any section has items to show
  bool get hasCompanyItems => filteredCompanyItems.isNotEmpty;
  bool get hasLocationItems => filteredLocationItems.isNotEmpty;
  bool get hasPersonalItems => filteredPersonalItems.isNotEmpty;
  bool get hasCustomerItems => filteredCustomerItems.isNotEmpty;
  bool get hasVendorItems => filteredVendorItems.isNotEmpty;
  bool get hasProductItems => filteredProductItems.isNotEmpty;
  bool get hasTaxTermsItems => filteredTaxTermsItems.isNotEmpty;

  bool get hasSearchResults =>
      hasCompanyItems ||
      hasLocationItems ||
      hasPersonalItems ||
      hasCustomerItems ||
      hasVendorItems ||
      hasProductItems ||
      hasTaxTermsItems;

  // Helper method to add item to recently viewed
  void addToRecentlyViewed(String title, IconData icon) {
    setState(() {
      // Remove if already exists
      recentlyViewedItems.removeWhere((item) => item['title'] == title);
      // Add to beginning of list
      recentlyViewedItems.insert(0, {'title': title, 'icon': icon});
      // Keep only last 10 items
      if (recentlyViewedItems.length > 10) {
        recentlyViewedItems.removeLast();
      }
    });
  }

  // Navigation method using common WebViewMaster
  void navigateToPage(String title, String urlPath, IconData icon) {
    addToRecentlyViewed(title, icon);

    // Close search mode if open
    if (isSearchMode) {
      closeSearchMode();
    }

    // Use common WebViewMaster for all masters
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WebViewMaster(
          title: title,
          urlPath: urlPath,
        ),
      ),
    );
  }

  // Clear search
  void clearSearch() {
    setState(() {
      searchQuery = '';
      searchController.clear();
    });
  }

  // Close search mode
  void closeSearchMode() {
    setState(() {
      isSearchMode = false;
      searchQuery = '';
      searchController.clear();
      if (_isListening) {
        _stopListening();
      }
    });
  }

  // Request microphone permission
  Future<bool> _requestMicrophonePermission() async {
    PermissionStatus status = await Permission.microphone.request();
    if (status.isGranted) {
      return true;
    } else if (status.isDenied) {
      status = await Permission.microphone.request();
      return status.isGranted;
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
      return false;
    }
    return false;
  }

  // Initialize speech to text
  Future<void> initSpeech() async {
    _speech = stt.SpeechToText();

    bool available = await _speech!.initialize(
      onStatus: (status) {
        print('Speech status: $status');
        if (status == 'notAvailable') {
          setState(() {
            _speechAvailable = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Speech recognition not available on this device'),
            ),
          );
        }
      },
      onError: (error) {
        print('Speech error: $error');
        setState(() {
          _isListening = false;
          _speechAvailable = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Speech error: ${error.errorMsg}')),
        );
      },
    );

    setState(() {
      _speechAvailable = available;
    });

    if (!available) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech recognition not available')),
      );
    }
  }

  // Start listening
  Future<void> _startListening() async {
    bool hasPermission = await _requestMicrophonePermission();
    if (!hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Microphone permission required for voice search'),
        ),
      );
      return;
    }

    if (_speech == null || !_speechAvailable) {
      await initSpeech();
    }

    if (_speech != null && _speechAvailable) {
      bool isListening = await _speech!.listen(
        onResult: (result) {
          print('Result: ${result.recognizedWords}');
          setState(() {
            _text = result.recognizedWords;
            searchQuery = _text;
            searchController.text = _text;
          });
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 5),
        partialResults: true,
        localeId: 'en_US',
        onSoundLevelChange: (level) {},
      );

      setState(() {
        _isListening = isListening;
      });

      if (!isListening) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to start speech recognition')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech recognition is not ready')),
      );
    }
  }

  // Stop listening
  void _stopListening() {
    if (_speech != null) {
      _speech!.stop();
      setState(() {
        _isListening = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initSpeech();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    if (_speech != null) {
      _speech!.stop();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondaryColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title:
            !isSearchMode
                ? const Text("Masters", style: TextStyle(color: Colors.white))
                : Container(
                  height: 40,
                  child: TextField(
                    controller: searchController,
                    autofocus: true,
                    style: const TextStyle(color: Colors.black, fontSize: 16),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: "Search masters...",
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (searchQuery.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: clearSearch,
                            ),
                          IconButton(
                            icon: Icon(
                              _isListening ? Icons.mic : Icons.mic_none,
                              color: _isListening ? Colors.red : Colors.grey,
                            ),
                            onPressed:
                                _isListening ? _stopListening : _startListening,
                          ),
                        ],
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ),
        actions: [
          if (!isSearchMode)
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: () {
                setState(() {
                  isSearchMode = true;
                });
              },
            ),
          if (isSearchMode)
            TextButton(
              onPressed: closeSearchMode,
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    if (recentlyViewedItems.isNotEmpty && searchQuery.isEmpty)
                      _buildRecentlyViewed(),

                    if (searchQuery.isNotEmpty && !hasSearchResults)
                      _buildNoResultsFound(),

                    if (hasCompanyItems) _buildCompanySection(),

                    if (hasLocationItems) _buildLocationSection(),

                    if (hasPersonalItems) _buildPersonalSection(),

                    if (hasCustomerItems) _buildCustomerSection(),

                    if (hasVendorItems) _buildVendorSection(),

                    if (hasProductItems) _buildProductSection(),

                    if (hasTaxTermsItems) _buildTaxTermsSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // No Results Found Widget
  Widget _buildNoResultsFound() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: AppColors.primaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            "No results found for '$searchQuery'",
            style: TextStyle(fontSize: 16, color: AppColors.textColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "Try searching with different keywords",
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textColor.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Recently Viewed
  Widget _buildRecentlyViewed() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Recently Viewed",
            style: TextStyle(
              color: AppColors.primaryColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 70,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: recentlyViewedItems.length,
              itemBuilder: (context, index) {
                final item = recentlyViewedItems[index];
                return GestureDetector(
                  onTap: () {
                    final menuItem = allMenuItems.firstWhere(
                      (menu) => menu['title'] == item['title'],
                      orElse: () => {'urlPath': ''},
                    );
                    navigateToPage(
                      item['title'],
                      menuItem['urlPath'],
                      item['icon'],
                    );
                  },
                  child: Container(
                    width: 70,
                    margin: const EdgeInsets.only(right: 12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.veryLightGray,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            item['icon'],
                            color: AppColors.primaryColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['title'],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Company Section
  Widget _buildCompanySection() {
    return _buildSection(title: "Company", items: filteredCompanyItems);
  }

  // Location Section
  Widget _buildLocationSection() {
    return _buildSection(title: "Location", items: filteredLocationItems);
  }

  // Personal Section
  Widget _buildPersonalSection() {
    return _buildSection(title: "Personal", items: filteredPersonalItems);
  }

  // Customer Section
  Widget _buildCustomerSection() {
    return _buildSection(title: "Customer", items: filteredCustomerItems);
  }

  // Vendor Section
  Widget _buildVendorSection() {
    return _buildSection(title: "Vendor", items: filteredVendorItems);
  }

  // Product Section
  Widget _buildProductSection() {
    return _buildSection(title: "Product", items: filteredProductItems);
  }

  // Tax/Terms Section
  Widget _buildTaxTermsSection() {
    return _buildSection(title: "Tax/Terms", items: filteredTaxTermsItems);
  }

  // Reusable Section Widget
  Widget _buildSection({
    required String title,
    required List<Map<String, dynamic>> items,
  }) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppColors.primaryColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            itemCount: items.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 0.9,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              final item = items[index];
              return GestureDetector(
                onTap: () {
                  navigateToPage(item['title'], item['urlPath'], item['icon']);
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.veryLightGray,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        item['icon'],
                        color: AppColors.primaryColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item['title'],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}