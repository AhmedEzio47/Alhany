import 'package:Alhany/app_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_summernote/flutter_summernote.dart';
import 'package:html_editor/html_editor.dart';

class LyricsEditor extends StatefulWidget {
  @override
  _LyricsEditorState createState() => _LyricsEditorState();
}

class _LyricsEditorState extends State<LyricsEditor> {
  GlobalKey<FlutterSummernoteState> _keyEditor = GlobalKey();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lyrics Editor'),
      ),
      body:
          SingleChildScrollView(child: FlutterSummernote(hint: "Your text here...", key: _keyEditor, customToolbar: """
            [
                ['style', ['bold', 'italic', 'underline', 'clear']],
                ['font', ['strikethrough', 'superscript', 'subscript']]
            ]""")),
    );
  }
}
