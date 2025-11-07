import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';

class VideoEditorScreen extends StatefulWidget {
  @override
  _VideoEditorScreenState createState() => _VideoEditorScreenState();
}

class _VideoEditorScreenState extends State<VideoEditorScreen> {
  File? _videoFile;
  VideoPlayerController? _controller;
  bool _isProcessing = false;

  Future<void> _pickVideo() async {
    final pickedFile = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _videoFile = File(pickedFile.path);
        _controller = VideoPlayerController.file(_videoFile!)
          ..initialize().then((_) {
            setState(() {});
            _controller!.play();
          });
      });
    }
  }

  Future<void> _trimVideo() async {
    if (_videoFile == null) return;

    setState(() => _isProcessing = true);

    final dir = await getTemporaryDirectory();
    final outputPath = '${dir.path}/trimmed_video.mp4';

    String command = '-i ${_videoFile!.path} -ss 00:00:02 -t 00:00:05 -c copy $outputPath';

    await FFmpegKit.execute(command);

    setState(() {
      _videoFile = File(outputPath);
      _controller = VideoPlayerController.file(_videoFile!)
        ..initialize().then((_) {
          setState(() {});
          _controller!.play();
        });
      _isProcessing = false;
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Video Editor")),
      body: Column(
        children: [
          if (_controller != null && _controller!.value.isInitialized)
            AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: VideoPlayer(_controller!),
            )
          else
            Container(height: 200, color: Colors.grey[300], child: Center(child: Text("No Video Selected"))),

          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _pickVideo,
            child: Text("Pick Video"),
          ),
          ElevatedButton(
            onPressed: _isProcessing ? null : _trimVideo,
            child: _isProcessing ? CircularProgressIndicator() : Text("Trim Video (First 5s)"),
          ),
        ],
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: VideoEditorScreen(),
  ));
}
