import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../services/gdcd_education_service.dart';
import '../services/auth_service.dart';
import '../widgets/eduvision_header.dart';

/// Demo screen để test API trực tiếp với GDCD
class GDCDTestScreen extends StatefulWidget {
  const GDCDTestScreen({Key? key}) : super(key: key);

  @override
  State<GDCDTestScreen> createState() => _GDCDTestScreenState();
}

class _GDCDTestScreenState extends State<GDCDTestScreen> {
  final GDCDEducationService _educationService = GDCDEducationService();
  final AuthService _authService = AuthService();
  
  bool _isLoading = false;
  String? _responseMessage;
  Map<String, dynamic>? _lastResponse;

  Future<void> _testGetSubjects() async {
    setState(() {
      _isLoading = true;
      _responseMessage = null;
    });

    try {
      final subjects = await _educationService.getSubjects();
      setState(() {
        _responseMessage = 'Subjects: ${subjects.join(", ")}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _responseMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _testGetChapters() async {
    setState(() {
      _isLoading = true;
      _responseMessage = null;
    });

    try {
      final chapters = await _educationService.getChapters(
        subject: 'GDCD',
        grade: 12,
      );
      setState(() {
        _responseMessage = 'Chapters: ${chapters.join(", ")}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _responseMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _testGenerateContent() async {
    setState(() {
      _isLoading = true;
      _responseMessage = null;
      _lastResponse = null;
    });

    try {
      final result = await _educationService.generateContent(
        subject: 'GDCD',
        chapter: 'Bài 2',
        grade: 12,
        imageCategory: 'GDCD',
        template: 1,
        mode: 'video',
      );
      
      setState(() {
        _lastResponse = result;
        _responseMessage = 'Content generated successfully!\n'
            'Slide URL: ${result['slideUrl'] ?? 'N/A'}\n'
            'Video URL: ${result['videoUrl'] ?? 'N/A'}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _responseMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const EduVisionHeader(
        title: 'GDCD API Test',
        showBackButton: true,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              const Text(
                'Test GDCD Education API',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Auth Status: ${_authService.isSignedIn ? "Signed In" : "Not Signed In"}',
                style: TextStyle(
                  fontSize: 16,
                  color: _authService.isSignedIn ? Colors.green : Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              // Test Buttons
              _buildTestButton(
                'Test Get Subjects',
                'Lấy danh sách môn học',
                _testGetSubjects,
              ),
              const SizedBox(height: 16),
              
              _buildTestButton(
                'Test Get Chapters',
                'Lấy danh sách bài học GDCD lớp 12',
                _testGetChapters,
              ),
              const SizedBox(height: 16),
              
              _buildTestButton(
                'Test Generate Content',
                'Tạo nội dung GDCD Bài 2',
                _testGenerateContent,
              ),
              
              const SizedBox(height: 32),
              
              // Response Display
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'API Response:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    if (_isLoading)
                      const Center(child: CupertinoActivityIndicator())
                    else if (_responseMessage != null)
                      Text(
                        _responseMessage!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF1F2937),
                          fontFamily: 'monospace',
                        ),
                      )
                    else
                      const Text(
                        'No response yet. Click a test button above.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
              
              // URLs Section (if available)
              if (_lastResponse != null && 
                  (_lastResponse!.containsKey('slideUrl') || _lastResponse!.containsKey('videoUrl')))
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF10B981)),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Generated URLs:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF065F46),
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      if (_lastResponse!.containsKey('slideUrl'))
                        _buildUrlRow('Slides:', _lastResponse!['slideUrl']),
                      
                      if (_lastResponse!.containsKey('videoUrl'))
                        _buildUrlRow('Video:', _lastResponse!['videoUrl']),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTestButton(String title, String subtitle, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CupertinoButton(
        padding: const EdgeInsets.all(16),
        onPressed: _isLoading ? null : onPressed,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                CupertinoIcons.play_arrow_solid,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              CupertinoIcons.chevron_right,
              size: 16,
              color: Color(0xFF9CA3AF),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUrlRow(String label, String url) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF065F46),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFD1FAE5)),
            ),
            child: Text(
              url,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF047857),
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
