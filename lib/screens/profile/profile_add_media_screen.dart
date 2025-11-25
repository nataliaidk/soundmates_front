import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../api/api_client.dart';
import '../../api/token_store.dart';

/// Simple screen for adding photos/videos/audio to profile
class ProfileAddMediaScreen extends StatefulWidget {
  final ApiClient api;
  final TokenStore tokens;

  const ProfileAddMediaScreen({
    super.key,
    required this.api,
    required this.tokens,
  });

  @override
  State<ProfileAddMediaScreen> createState() => _ProfileAddMediaScreenState();
}

class _ProfileAddMediaScreenState extends State<ProfileAddMediaScreen> {
  List<PlatformFile> _pickedFiles = [];
  String _status = '';
  bool _uploading = false;
  bool _loadingExisting = true;

  // Limits for each file type
  static const int maxImageFiles = 5;
  static const int maxAudioVideoFiles = 5; // MP3 and MP4 combined

  // Current counts from server
  int _existingImageCount = 0;
  int _existingAudioVideoCount = 0; // MP3 + MP4 combined

  @override
  void initState() {
    super.initState();
    _loadExistingMedia();
  }

  Future<void> _loadExistingMedia() async {
    setState(() => _loadingExisting = true);
    
    try {
      // Load user profile which contains musicSamples and profilePictures
      final profileResp = await widget.api.getMyProfile();
      print('👤 Profile response: ${profileResp.statusCode}');
      
      if (profileResp.statusCode == 200) {
        var profileData = jsonDecode(profileResp.body);
        print('👤 Profile data type: ${profileData.runtimeType}');
        
        // Handle double-encoded JSON
        if (profileData is String) {
          profileData = jsonDecode(profileData);
        }
        
        if (profileData is Map) {
          // Get profile pictures
          final profilePictures = profileData['profilePictures'];
          if (profilePictures is List) {
            _existingImageCount = profilePictures.length;
            print('📷 Found ${_existingImageCount} existing images');
          }
          
          // Get music samples (MP3 and MP4 combined)
          final musicSamples = profileData['musicSamples'];
          if (musicSamples is List) {
            _existingAudioVideoCount = musicSamples.length;
            print('🎵 Found ${_existingAudioVideoCount} audio/video files');
          }
        } else {
          print('👤 Unexpected profile data type: ${profileData.runtimeType}');
        }
      }
    } catch (e) {
      print('❌ Error loading existing media: $e');
    } finally {
      if (mounted) {
        setState(() => _loadingExisting = false);
      }
    }
  }

  int _countFileType(String extension) {
    return _pickedFiles.where((f) {
      final lower = f.name.toLowerCase();
      return lower.endsWith('.$extension');
    }).length;
  }

  Map<String, int> _getRemainingSlots() {
    final audioVideoInPicked = _countFileType('mp3') + _countFileType('mp4');
    return {
      'audio-video': maxAudioVideoFiles - _existingAudioVideoCount - audioVideoInPicked,
      'images': maxImageFiles - _existingImageCount - _countFileType('jpg') - _countFileType('jpeg'),
    };
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'mp3', 'mp4'],
      withData: true,
      allowMultiple: true,
    );
    
    if (result != null && result.files.isNotEmpty) {
      final remaining = _getRemainingSlots();
      final List<PlatformFile> acceptedFiles = [];
      final List<String> rejectedReasons = [];

      for (final file in result.files) {
        final lower = file.name.toLowerCase();
        
        if (lower.endsWith('.mp3') || lower.endsWith('.mp4')) {
          if (remaining['audio-video']! > 0) {
            acceptedFiles.add(file);
            remaining['audio-video'] = remaining['audio-video']! - 1;
          } else {
            rejectedReasons.add('Audio/Video: limit reached (max $maxAudioVideoFiles MP3+MP4 combined)');
          }
        } else if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
          if (remaining['images']! > 0) {
            acceptedFiles.add(file);
            remaining['images'] = remaining['images']! - 1;
          } else {
            rejectedReasons.add('Images: limit reached (max $maxImageFiles)');
          }
        }
      }

      setState(() {
        if (acceptedFiles.isNotEmpty) {
          _pickedFiles.addAll(acceptedFiles);
        }
        
        if (rejectedReasons.isNotEmpty) {
          final uniqueReasons = rejectedReasons.toSet().toList();
          _status = 'Some files were not added:\n${uniqueReasons.join('\n')}';
        } else if (acceptedFiles.isNotEmpty) {
          _status = 'Added ${acceptedFiles.length} file(s)';
        } else {
          _status = 'No files were added';
        }
      });
    }
  }

  void _removeFile(int index) {
    setState(() {
      _pickedFiles.removeAt(index);
    });
  }

  Future<void> _uploadFiles() async {
    if (_pickedFiles.isEmpty) {
      setState(() => _status = 'Please select files first');
      return;
    }

    setState(() {
      _uploading = true;
      _status = 'Uploading ${_pickedFiles.length} file(s)...';
    });

    int successCount = 0;
    int failCount = 0;

    for (final file in _pickedFiles) {
      String uploadName = file.name;
      
      // Validate and fix extension
      final extMatch = RegExp(r'^(.+?)\.(jpg|jpeg|mp3|mp4)$', caseSensitive: false)
          .firstMatch(uploadName);
      
      if (extMatch != null) {
        uploadName = extMatch.group(0)!;
      } else {
        // Check if it's a JPEG by magic bytes
        final bytes = file.bytes!;
        if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xD8) {
          uploadName = uploadName.trim();
          if (!uploadName.toLowerCase().endsWith('.jpg') &&
              !uploadName.toLowerCase().endsWith('.jpeg')) {
            uploadName = '$uploadName.jpg';
          }
        } else {
          failCount++;
          continue;
        }
      }

      try {
        // Determine file type and use appropriate upload method
        final lowerName = uploadName.toLowerCase();
        final isAudio = lowerName.endsWith('.mp3') || lowerName.endsWith('.mp4');
        
        final streamed = isAudio
            ? await widget.api.uploadMusicSample(file.bytes!, uploadName)
            : await widget.api.uploadProfilePicture(file.bytes!, uploadName);
            
        await streamed.stream.bytesToString();
        
        if (streamed.statusCode == 200) {
          successCount++;
        } else {
          failCount++;
        }
      } catch (e) {
        failCount++;
      }
    }

    if (!mounted) return;

    setState(() {
      _uploading = false;
      if (failCount == 0) {
        _status = 'Successfully uploaded $successCount file(s)! Refreshing...';
        _pickedFiles.clear();
        
        // Wait 2 seconds before going back to allow backend processing
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pop(context, true); // true = files were uploaded
          }
        });
      } else {
        _status = 'Uploaded: $successCount, Failed: $failCount';
      }
    });
  }

  String _getFileIcon(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.mp4')) return '';
    if (lower.endsWith('.mp3')) return '';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return '';
    return '';
  }

  Widget _buildLimitCard({
    required IconData icon,
    required String label,
    required int current,
    required int max,
    required MaterialColor color,
    required String subtitle,
  }) {
    final remaining = max - current;
    final isAtLimit = remaining <= 0;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isAtLimit 
              ? [Colors.red.shade50, Colors.red.shade100]
              : [color.shade50, color.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAtLimit ? Colors.red.shade300 : color.shade300,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 40,
            color: isAtLimit ? Colors.red.shade700 : color.shade700,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isAtLimit ? Colors.red.shade700 : color.shade700,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isAtLimit ? 'Limit reached' : '$remaining left',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$current / $max',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isAtLimit ? Colors.red.shade700 : color.shade700,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Add Media'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Select photos, videos, or audio files to add to your profile',
                      style: TextStyle(color: Colors.blue.shade900, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // File limits display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: _loadingExisting
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Upload Limits:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildLimitCard(
                                icon: Icons.image_outlined,
                                label: 'Photos',
                                current: _existingImageCount + _countFileType('jpg') + _countFileType('jpeg'),
                                max: maxImageFiles,
                                color: Colors.blue,
                                subtitle: 'JPG, JPEG',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildLimitCard(
                                icon: Icons.music_note_outlined,
                                label: 'Audio/Video',
                                current: _existingAudioVideoCount + _countFileType('mp3') + _countFileType('mp4'),
                                max: maxAudioVideoFiles,
                                color: Colors.purple,
                                subtitle: 'MP3, MP4',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 24),

            // Pick Files Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _uploading ? null : _pickFiles,
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('Select Files'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade400,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Supported: JPG, JPEG, MP3, MP4',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 24),

            // Selected Files List
            if (_pickedFiles.isNotEmpty) ...[
              Text(
                'Selected Files (${_pickedFiles.length})',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _pickedFiles.length,
                itemBuilder: (context, index) {
                  final file = _pickedFiles[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: file.bytes != null && 
                             (file.name.toLowerCase().endsWith('.jpg') || 
                              file.name.toLowerCase().endsWith('.jpeg'))
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(
                                file.bytes!,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  _getFileIcon(file.name),
                                  style: const TextStyle(fontSize: 24),
                                ),
                              ),
                            ),
                      title: Text(
                        file.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${(file.size / 1024).toStringAsFixed(1)} KB',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      trailing: _uploading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () => _removeFile(index),
                            ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Upload Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _uploading ? null : _uploadFiles,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  child: _uploading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Uploading...'),
                          ],
                        )
                      : const Text('Upload Files'),
                ),
              ),
            ],

            // Status Message
            if (_status.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _status.contains('Success') || _status.contains('uploaded')
                      ? Colors.green.shade50
                      : _status.contains('Failed') || _status.contains('Invalid')
                          ? Colors.red.shade50
                          : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _status.contains('Success') || _status.contains('uploaded')
                        ? Colors.green.shade300
                        : _status.contains('Failed') || _status.contains('Invalid')
                            ? Colors.red.shade300
                            : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  _status,
                  style: TextStyle(
                    color: _status.contains('Success') || _status.contains('uploaded')
                        ? Colors.green.shade900
                        : _status.contains('Failed') || _status.contains('Invalid')
                            ? Colors.red.shade900
                            : Colors.grey.shade900,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
