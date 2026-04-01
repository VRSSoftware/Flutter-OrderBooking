import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vrs_erp/constants/app_constants.dart';

// For image resizing on mobile
import 'dart:ui' as ui;

class FabricToGarmentGenerator extends StatefulWidget {
  const FabricToGarmentGenerator({Key? key}) : super(key: key);

  @override
  State<FabricToGarmentGenerator> createState() => _FabricToGarmentGeneratorState();
}

class _FabricToGarmentGeneratorState extends State<FabricToGarmentGenerator> {
  Uint8List? _fabricImageBytes;
  Uint8List? _generatedImage;
  final TextEditingController _promptController = TextEditingController();
  bool _isGenerating = false;
  String? _errorMessage;
  String? _detectedColor;

  final String _apiKey = 'sk-pWlAiqMTis8Dfj4lJWstDURxCWMStEX7Ob9OM80lb39AgR89';

  final List<String> _quickExamples = [
    'a kurta for men',
    'a women\'s party wear dress',
    'a shirt for boys',
    'a lehenga for girls',
    'a saree for women',
    'a jacket for men',
  ];

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<Uint8List> _resizeImageToValidDimensions(Uint8List originalBytes) async {
    try {
      final codec = await ui.instantiateImageCodec(originalBytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      
      const targetWidth = 1024;
      const targetHeight = 1024;
      
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        Rect.fromLTWH(0, 0, targetWidth.toDouble(), targetHeight.toDouble()),
        Paint()..isAntiAlias = true,
      );
      
      final picture = recorder.endRecording();
      final resizedImage = await picture.toImage(targetWidth, targetHeight);
      
      final byteData = await resizedImage.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Failed to convert image to bytes');
      }
      
      image.dispose();
      resizedImage.dispose();
      codec.dispose();
      
      return byteData.buffer.asUint8List();
    } catch (e) {
      print('Resize error: $e');
      return originalBytes;
    }
  }

Future<String> _detectFabricColor(Uint8List imageBytes) async {
  try {
    // Decode image first to get accurate RGB values
    final codec = await ui.instantiateImageCodec(imageBytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    
    // Create a small canvas to sample pixels
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawImage(image, Offset.zero, Paint());
    
    final picture = recorder.endRecording();
    final sampledImage = await picture.toImage(100, 100);
    final byteData = await sampledImage.toByteData(format: ui.ImageByteFormat.rawRgba);
    
    if (byteData == null) return 'Beautiful';
    
    int r = 0, g = 0, b = 0, count = 0;
    final pixels = byteData.buffer.asUint8List();
    
    for (int i = 0; i < pixels.length; i += 4) {
      r += pixels[i];
      g += pixels[i + 1];
      b += pixels[i + 2];
      count++;
    }
    
    r = (r / count).round();
    g = (g / count).round();
    b = (b / count).round();
    
    image.dispose();
    sampledImage.dispose();
    codec.dispose();
    
    return _getColorName(r, g, b);
  } catch (e) {
    return 'Beautiful';
  }
}

  String _getColorName(int r, int g, int b) {
    if (r > 200 && g > 200 && b > 200) return 'White';
    if (r < 50 && g < 50 && b < 50) return 'Black';
    if (r > 200 && g < 100 && b < 100) return 'Red';
    if (r > 200 && g > 150 && b < 100) return 'Orange';
    if (r > 200 && g > 200 && b < 100) return 'Yellow';
    if (r < 100 && g > 150 && b < 100) return 'Green';
    if (r < 100 && g < 100 && b > 200) return 'Blue';
    if (r > 150 && g < 100 && b > 150) return 'Purple';
    if (r > 200 && g > 150 && b > 150) return 'Pink';
    if (r > 150 && g > 150 && b < 100) return 'Golden';
    if (r > 150 && g > 100 && b > 100) return 'Brown';
    return 'Beautiful';
  }

Future<void> _downloadImage() async {
  if (_generatedImage == null) return;
  
  setState(() {
    _isGenerating = true;
  });
  
  try {
    final now = DateTime.now();
    final timestamp = '${now.year}${now.month}${now.day}_${now.hour}${now.minute}${now.second}';
    final fileName = 'garment_$timestamp.png';
    
    Directory? downloadsDir;
    
    if (!kIsWeb) {
      if (Platform.isAndroid) {
        downloadsDir = Directory('/storage/emulated/0/Download');
        if (!await downloadsDir.exists()) {
          downloadsDir = await getExternalStorageDirectory();
        }
      } else {
        downloadsDir = await getApplicationDocumentsDirectory();
      }
    }
    
    if (downloadsDir != null) {
      final file = File('${downloadsDir.path}/$fileName');
      await file.writeAsBytes(_generatedImage!);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Image saved to: ${file.path}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } else {
      throw Exception('Could not access downloads directory');
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error saving image: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  } finally {
    if (mounted) {
      setState(() {
        _isGenerating = false;
      });
    }
  }
}

Future<bool> _requestStoragePermission() async {
  return true;
}

  Future<void> _pickFabricImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        final resizedBytes = await _resizeImageToValidDimensions(bytes);
        final detectedColor = await _detectFabricColor(bytes); 
        
        setState(() {
          _fabricImageBytes = resizedBytes;
          _detectedColor = detectedColor;
          _errorMessage = null;
          _generatedImage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error picking image: $e';
      });
    }
  }

  Future<void> _generateProduct() async {
    if (_fabricImageBytes == null) {
      setState(() {
        _errorMessage = 'Please select a fabric image first';
      });
      return;
    }

    if (_promptController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please describe what you want to make';
      });
      return;
    }

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.stability.ai/v1/generation/stable-diffusion-xl-1024-v1-0/image-to-image'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $_apiKey',
        'Accept': 'application/json',
      });

      request.files.add(
        http.MultipartFile.fromBytes(
          'init_image',
          _fabricImageBytes!,
          filename: 'fabric.png',
          contentType: MediaType('image', 'png'),
        ),
      );

      String userPrompt = _promptController.text.trim();
      String colorName = _detectedColor ?? 'Beautiful';
      
      String finalPrompt = _buildFullBodyPrompt(userPrompt);
      
      request.fields['init_image_mode'] = 'IMAGE_STRENGTH';
      request.fields['image_strength'] = '0.12';
      request.fields['cfg_scale'] = '13';
      request.fields['samples'] = '1';
      request.fields['steps'] = '50';
      request.fields['text_prompts[0][text]'] = finalPrompt;
      request.fields['text_prompts[0][weight]'] = '1.0';
      request.fields['text_prompts[1][text]'] = _getNegativePrompt();
      request.fields['text_prompts[1][weight]'] = '-1.0';
      request.fields['style_preset'] = 'photographic';
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['artifacts'] != null && data['artifacts'].isNotEmpty) {
          setState(() {
            _generatedImage = base64Decode(data['artifacts'][0]['base64']);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✨ Garment generated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          throw Exception('No image generated');
        }
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

String _buildFullBodyPrompt(String userPrompt) {
  return '''
A professional e-commerce fashion photograph of a $userPrompt.

GARMENT RULES:
- The garment MUST be created using ONLY the exact fabric from the input image
- The fabric color MUST remain EXACTLY the same as input image
- The fabric pattern MUST remain EXACTLY the same
- Do NOT change, enhance, or reinterpret colors
- Do NOT generate new textures or designs

MODEL:
- realistic human model, natural face

BACKGROUND:
- pure white (#FFFFFF), no gradient, no environment

STYLE:
- Myntra / Amazon catalog photography

CRITICAL:
- preserve original fabric color and pattern as closely as possible
- allow natural lighting variation
- no artistic interpretation
''';
}
  String _getNegativePrompt() {
return '''
color change, different color fabric, altered fabric, redesigned pattern,
artistic interpretation, stylized fabric, fake texture,
dark background, gradient background, room, outdoor,
cartoon, illustration, painting
''';
  }

  void _useExample(String example) {
    setState(() {
      _promptController.text = example;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.veryLightGray,
      appBar: AppBar(
        title: const Text(
          'Fabric to Garment',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Fabric Image Section
              _buildFabricImageSection(),
              
              const SizedBox(height: 20),
              
              // Quick Examples
              _buildQuickExamplesSection(),
              
              const SizedBox(height: 20),
              
              // Prompt Input
              _buildPromptInput(),
              
              const SizedBox(height: 24),
              
              // Generate Button with Gradient
              _buildGenerateButton(),
              
              const SizedBox(height: 20),
              
              // Error Message
              if (_errorMessage != null) _buildErrorMessage(),
              
              // Generated Result
              if (_generatedImage != null) _buildGeneratedResult(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFabricImageSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: _fabricImageBytes != null
            ? Stack(
                children: [
                  Image.memory(
                    _fabricImageBytes!,
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  Container(
                    height: 220,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.5),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.color_lens, size: 14, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            'Color: $_detectedColor',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: GestureDetector(
                        onTap: _pickFabricImage,
                        child: Icon(
                          Icons.camera_alt,
                          size: 20,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : GestureDetector(
                onTap: _pickFabricImage,
                child: Container(
                  height: 220,
                  decoration: BoxDecoration(
                    color: AppColors.veryLightGray,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.slateBorder, width: 1.5),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate,
                        size: 60,
                        color: AppColors.primaryColor.withOpacity(0.6),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Tap to select fabric',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.slate600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Upload any fabric pattern or texture',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.slate600.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildQuickExamplesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Examples',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.slate600,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _quickExamples.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              return ActionChip(
                label: Text(
                  _quickExamples[index],
                  style: const TextStyle(fontSize: 12),
                ),
                onPressed: () => _useExample(_quickExamples[index]),
                backgroundColor: Colors.white,
                side: BorderSide(color: AppColors.primaryColor.withOpacity(0.3)),
                labelStyle: TextStyle(color: AppColors.primaryColor),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPromptInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _promptController,
        maxLines: 3,
        decoration: InputDecoration(
          hintText: 'Describe what you want to make...',
          hintStyle: TextStyle(color: AppColors.slate600.withOpacity(0.6)),
          labelText: 'Garment Description',
          labelStyle: TextStyle(color: AppColors.primaryColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          prefixIcon: Icon(Icons.edit_note, color: AppColors.primaryColor),
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildGenerateButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF072F5F), Color(0xFF0A4A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isGenerating ? null : _generateProduct,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isGenerating
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Generating...',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Generate Garment',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red.shade700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneratedResult() {
    return Column(
      children: [
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),
        Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
            const SizedBox(width: 8),
            Text(
              'Generated Garment',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primaryColor.withOpacity(0.3), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.memory(
              _generatedImage!,
              height: 500,
              width: double.infinity,
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
     Expanded(
  child: ElevatedButton.icon(
    onPressed: _downloadImage,
    icon: const Icon(Icons.download),
    label: const Text('Download'),
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.green.shade600,
      padding: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _generatedImage = null;
                  });
                },
                icon: const Icon(Icons.refresh),
                label: const Text('New Design'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: AppColors.primaryColor),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}