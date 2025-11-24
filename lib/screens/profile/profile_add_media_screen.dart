import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../api/api_client.dart';
import '../../api/token_store.dart';
import '../../theme/app_design_system.dart';

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

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'mp3', 'mp4'],
      withData: true,
      allowMultiple: true,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _pickedFiles.addAll(result.files);
        _status = '';
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
      final extMatch = RegExp(
        r'^(.+?)\.(jpg|jpeg|mp3|mp4)$',
        caseSensitive: false,
      ).firstMatch(uploadName);

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
        final isAudio =
            lowerName.endsWith('.mp3') || lowerName.endsWith('.mp4');

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
        _status = 'Successfully uploaded $successCount file(s)!';
        _pickedFiles.clear();

        // Auto-navigate back after 1 second
        Future.delayed(const Duration(seconds: 1), () {
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
    if (lower.endsWith('.mp4')) return '🎥';
    if (lower.endsWith('.mp3')) return '🎵';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return '🖼️';
    return '📄';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
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
                border: Border.all(color: AppColors.borderLightAlt),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Select photos, videos, or audio files to add to your profile',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
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
                  backgroundColor: AppColors.accentPurple,
                  foregroundColor: AppColors.textWhite,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Supported: JPG, JPEG, MP3, MP4',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 24),

            // Selected Files List
            if (_pickedFiles.isNotEmpty) ...[
              Text(
                'Selected Files (${_pickedFiles.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
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
                      leading:
                          file.bytes != null &&
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
                                color: AppColors.backgroundLight,
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
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
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
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
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
                  color:
                      _status.contains('Success') ||
                          _status.contains('uploaded')
                      ? Colors.green.shade50
                      : _status.contains('Failed') ||
                            _status.contains('Invalid')
                      ? Colors.red.shade50
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        _status.contains('Success') ||
                            _status.contains('uploaded')
                        ? Colors.green.shade300
                        : _status.contains('Failed') ||
                              _status.contains('Invalid')
                        ? Colors.red.shade300
                        : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  _status,
                  style: TextStyle(
                    color:
                        _status.contains('Success') ||
                            _status.contains('uploaded')
                        ? Colors.green.shade900
                        : _status.contains('Failed') ||
                              _status.contains('Invalid')
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
