
  /*
  //  SUPABASE UPLOAD LOGIC ---
  Future<void> _uploadToSupabase() async {
    if (_recordedFilePath == null) return;

    setState(() => _isUploading = true);

    try {
      final file = File(_recordedFilePath!);
      final fileExt = _recordedFilePath!.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = 'flashcard_audios/$fileName'; // Folder structure in Bucket

      // A. Upload file to Storage Bucket named 'audio_bucket'
      await _supabase.storage.from('audio_bucket').upload(
        filePath,
        file,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );

      // B. Get the Public URL (so we can listen to it later)
      final publicUrl = _supabase.storage.from('audio_bucket').getPublicUrl(filePath);
      
      setState(() {
        _remoteAudioUrl = publicUrl; // Switch to using the remote URL
        _isUploading = false;
      });

      _showSnackBar("Audio saved to cloud successfully!");
      print("File uploaded to: $publicUrl");

    } catch (e) {
      setState(() => _isUploading = false);
      _showSnackBar("Upload failed: $e", isError: true);
    }
  }
  */