import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:path_provider/path_provider.dart';


class FashionDesignerScreen extends StatefulWidget {
  @override
  _FashionDesignerScreenState createState() => _FashionDesignerScreenState();
}

class _FashionDesignerScreenState extends State<FashionDesignerScreen> {
  File? _fabricImage;
  File? _modelImage;
  File? _generatedImage;
  bool _isLoading = false;
  String _selectedModel = 'stable-image-ultra';
  String _selectedAspectRatio = '2:3'; // Portrait orientation for models
  final TextEditingController _promptController = TextEditingController();
  
  // ADD YOUR STABILITY AI API KEY HERE
  final String _stabilityApiKey = 'sk-pWlAiqMTis8Dfj4lJWstDURxCWMStEX7Ob9OM80lb39AgR89';
  
  // Valid aspect ratios from the API
  final List<Map<String, String>> _aspectRatios = [
    {'value': '1:1', 'label': 'Square (1:1)'},
    {'value': '2:3', 'label': 'Portrait (2:3)'},
    {'value': '3:2', 'label': 'Landscape (3:2)'},
    {'value': '4:5', 'label': 'Portrait (4:5)'},
    {'value': '5:4', 'label': 'Landscape (5:4)'},
    {'value': '9:16', 'label': 'Phone Portrait (9:16)'},
    {'value': '16:9', 'label': 'Widescreen (16:9)'},
    {'value': '21:9', 'label': 'Cinematic (21:9)'},
  ];
  
  // Model options
  final List<Map<String, dynamic>> _models = [
    {
      'name': 'Stable Image Ultra',
      'value': 'stable-image-ultra',
      'description': 'Highest quality - Best for fashion',
      'price': '8 credits',
      'endpoint': 'https://api.stability.ai/v2beta/stable-image/generate/ultra'
    },
    {
      'name': 'SD3.5 Large',
      'value': 'sd3.5-large',
      'description': 'Excellent quality & prompt adherence',
      'price': '6.5 credits',
      'endpoint': 'https://api.stability.ai/v2beta/stable-image/generate/sd3.5-large'
    },
    {
      'name': 'SD3.5 Large Turbo',
      'value': 'sd3.5-large-turbo',
      'description': 'Fast generation, good quality',
      'price': '4 credits',
      'endpoint': 'https://api.stability.ai/v2beta/stable-image/generate/sd3.5-large-turbo'
    },
  ];
  
  // Pre-defined clothing suggestions
  final List<String> _suggestions = [
    'blue silk kurta with golden embroidery, mandarin collar, festive wear',
    'white cotton shirt with modern design, slim fit, business casual',
    'red velvet dress with sequins, evening gown style, floor-length',
    'traditional sherwani with intricate zari work, wedding wear',
    'casual denim jacket with patches, street style, oversized',
    'elegant saree with designer blouse, floral pattern, silk fabric',
  ];

  @override
  Widget build(BuildContext context) {
    bool isButtonEnabled = _promptController.text.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text('AI Fashion Designer', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fabric Image Section
            Text(
              'Fabric/Clothing Image (Optional)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo.shade900),
            ),
            SizedBox(height: 8),
            Center(
              child: GestureDetector(
                onTap: () => _pickFabricImage(),
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300, width: 2),
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.grey.shade50,
                  ),
                  child: _fabricImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.file(
                            _fabricImage!,
                            width: double.infinity,
                            height: 180,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate, size: 40, color: Colors.indigo.shade300),
                            SizedBox(height: 8),
                            Text(
                              'Tap to upload fabric image',
                              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                            ),
                            Text(
                              '(Helps match colors & patterns)',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            
            SizedBox(height: 20),
            
            // Model Image Section (Optional)
            Text(
              'Model Image (Optional)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo.shade900),
            ),
            SizedBox(height: 8),
            Center(
              child: GestureDetector(
                onTap: () => _pickModelImage(),
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300, width: 2),
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.grey.shade50,
                  ),
                  child: _modelImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.file(
                            _modelImage!,
                            width: double.infinity,
                            height: 180,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_outline, size: 40, color: Colors.indigo.shade300),
                            SizedBox(height: 8),
                            Text(
                              'Tap to upload model image',
                              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                            ),
                            Text(
                              '(Model will wear the clothing)',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            
            SizedBox(height: 20),
            
            // Model Selection
            Text(
              'AI Model Selection',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo.shade900),
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.indigo.shade200),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedModel,
                  isExpanded: true,
                  items: _models.map<DropdownMenuItem<String>>((model) {
                    return DropdownMenuItem<String>(
                      value: model['value'] as String,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            model['name'] as String,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            '${model['description']} - ${model['price']}',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (String? value) {
                    setState(() {
                      _selectedModel = value!;
                    });
                  },
                ),
              ),
            ),
            
            SizedBox(height: 20),
            
            // Aspect Ratio Selection
            Text(
              'Image Aspect Ratio',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo.shade900),
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.indigo.shade200),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedAspectRatio,
                  isExpanded: true,
                  items: _aspectRatios.map<DropdownMenuItem<String>>((ratio) {
                    return DropdownMenuItem<String>(
                      value: ratio['value'],
                      child: Text(ratio['label']!),
                    );
                  }).toList(),
                  onChanged: (String? value) {
                    setState(() {
                      _selectedAspectRatio = value!;
                    });
                  },
                ),
              ),
            ),
            
            SizedBox(height: 20),
            
            // Prompt Input Section
            Text(
              'Describe the clothing item',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo.shade900),
            ),
            SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.indigo.shade200),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _promptController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'E.g., "blue silk kurta with golden embroidery, mandarin collar"',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      setState(() {
                        _promptController.clear();
                      });
                    },
                  ),
                ),
                onChanged: (value) {
                  setState(() {});
                },
              ),
            ),
            
            SizedBox(height: 16),
            
            // Quick Suggestions
            Text(
              'Quick suggestions',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey.shade700),
            ),
            SizedBox(height: 8),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _suggestions.length,
                separatorBuilder: (_, __) => SizedBox(width: 8),
                itemBuilder: (context, index) {
                  return ActionChip(
                    label: Text(_suggestions[index].length > 35 
                        ? _suggestions[index].substring(0, 35) + '...' 
                        : _suggestions[index]),
                    onPressed: () {
                      setState(() {
                        _promptController.text = _suggestions[index];
                      });
                    },
                    backgroundColor: Colors.indigo.shade50,
                    labelStyle: TextStyle(fontSize: 11),
                  );
                },
              ),
            ),
            
            SizedBox(height: 30),
            
            // Generate Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: isButtonEnabled ? _generateFashion : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                ),
                child: _isLoading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Generating...', style: TextStyle(fontSize: 16)),
                        ],
                      )
                    : Text(
                        'Generate Fashion Design',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            
            SizedBox(height: 30),
            
            // Generated Result
            if (_generatedImage != null) ...[
              Divider(height: 1, color: Colors.grey.shade300),
              SizedBox(height: 20),
              Text(
                '✨ Generated Design',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo.shade900),
              ),
              SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.indigo.shade200, width: 2),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.file(
                    _generatedImage!,
                    width: double.infinity,
                    height: 450,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _saveImage,
                      icon: Icon(Icons.save),
                      label: Text('Save to Gallery'),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.indigo),
                        foregroundColor: Colors.indigo,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _regenerate,
                      icon: Icon(Icons.refresh),
                      label: Text('Regenerate'),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.indigo),
                        foregroundColor: Colors.indigo,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickFabricImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        setState(() {
          _fabricImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      _showError('Failed to pick fabric image: $e');
    }
  }

  Future<void> _pickModelImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        setState(() {
          _modelImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      _showError('Failed to pick model image: $e');
    }
  }

  Future<void> _generateFashion() async {
    if (_promptController.text.isEmpty) {
      _showError('Please describe the clothing item');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get the selected model endpoint
      final Map<String, dynamic> selectedModelConfig = _models.firstWhere(
        (model) => model['value'] == _selectedModel
      );
      final String endpoint = selectedModelConfig['endpoint'] as String;
      
      // Build the enhanced prompt
      String prompt = _buildPrompt();
      
      print('=== API Request ===');
      print('Endpoint: $endpoint');
      print('Prompt: $prompt');
      print('Aspect Ratio: $_selectedAspectRatio');
      print('Has Fabric Image: ${_fabricImage != null}');
      print('Has Model Image: ${_modelImage != null}');
      
      // Create multipart request
      var request = http.MultipartRequest('POST', Uri.parse(endpoint));
      
      // Add headers
      request.headers.addAll({
        'authorization': 'Bearer $_stabilityApiKey',
      });
      
      // Add form fields
      request.fields['prompt'] = prompt;
      request.fields['output_format'] = 'png';
      request.fields['aspect_ratio'] = _selectedAspectRatio;
      request.fields['negative_prompt'] = 'blurry, distorted, deformed, ugly, bad anatomy, watermark, text, logo, low quality, extra limbs';
      
      // If fabric image is provided, add it and required strength parameter
      if (_fabricImage != null) {
        var imageFile = await http.MultipartFile.fromPath(
          'image',
          _fabricImage!.path,
        );
        request.files.add(imageFile);
        request.fields['strength'] = '0.7'; // Required when image is provided
      }
      
      // Note: The API only accepts ONE image. If both are provided, use fabric image as reference
      // and incorporate model in the prompt
      if (_modelImage != null && _fabricImage == null) {
        // If only model image, use it as reference
        var modelFile = await http.MultipartFile.fromPath(
          'image',
          _modelImage!.path,
        );
        request.files.add(modelFile);
        request.fields['strength'] = '0.6';
      }
      
      print('Request fields: ${request.fields}');
      print('Number of files: ${request.files.length}');
      
      // Send request
      var streamedResponse = await request.send().timeout(
        Duration(seconds: 90),
        onTimeout: () {
          throw Exception('Request timeout after 90 seconds');
        },
      );
      
      var response = await http.Response.fromStream(streamedResponse);
      
      print('Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        // Save the generated image
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/fashion_${DateTime.now().millisecondsSinceEpoch}.png');
        await file.writeAsBytes(response.bodyBytes);
        
        setState(() {
          _generatedImage = file;
          _isLoading = false;
        });
        
        _showSuccess('Fashion design generated successfully!');
      } else {
        String errorBody = response.body;
        print('Error body: $errorBody');
        
        String errorMessage = 'API Error: ${response.statusCode}\n';
        try {
          var errorJson = json.decode(errorBody);
          if (errorJson['errors'] != null && errorJson['errors'] is List) {
            errorMessage += (errorJson['errors'] as List).join('\n');
          } else if (errorJson['message'] != null) {
            errorMessage += errorJson['message'];
          } else {
            errorMessage += errorBody;
          }
        } catch (e) {
          errorMessage += errorBody;
        }
        _showError(errorMessage);
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      _showError('Error: $e');
      print('Full error: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _buildPrompt() {
    String basePrompt = _promptController.text;
    
    // Add model hint if model image is provided
    String modelHint = '';
    if (_modelImage != null && _fabricImage != null) {
      modelHint = ' wearing the exact clothing design that matches the fabric pattern and colors from the reference image,';
    } else if (_modelImage != null) {
      modelHint = ' wearing the clothing on the provided model figure,';
    } else if (_fabricImage != null) {
      modelHint = ' using the exact colors and patterns from the reference fabric image,';
    }
    
    // Build full prompt
    String fullPrompt = 'A professional fashion model$modelHint wearing a beautiful $basePrompt. High quality fashion photography, studio lighting, clean white background. Detailed fabric texture, perfect fit. Vogue editorial style, photorealistic, highly detailed.';
    
    return fullPrompt;
  }

  Future<void> _saveImage() async {
    if (_generatedImage == null) return;
    
    try {
      final directory = await getApplicationDocumentsDirectory();
      final newPath = '${directory.path}/fashion_${DateTime.now().millisecondsSinceEpoch}.png';
      await _generatedImage!.copy(newPath);
      
      _showSuccess('Image saved to:\n${directory.path}');
    } catch (e) {
      _showError('Failed to save image: $e');
    }
  }

  void _regenerate() {
    _generateFashion();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, maxLines: 5),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 8),
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }
}