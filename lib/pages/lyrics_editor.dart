import 'package:Alhany/app_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_summernote/flutter_summernote.dart';
import 'package:html_editor/html_editor.dart';

class LyricsEditor extends StatefulWidget {
  @override
  _LyricsEditorState createState() => _LyricsEditorState();
}

class _LyricsEditorState extends State<LyricsEditor> {
  GlobalKey<HtmlEditorState> keyEditor = GlobalKey();

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
      body: HtmlEditor(
        hint: "Your text here...",
        //value: "text content initial, if any",
        key: keyEditor,
        height: MediaQuery.of(context).size.height,
      ),
    );
  }
}
