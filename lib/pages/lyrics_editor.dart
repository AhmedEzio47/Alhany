import 'package:Alhany/app_util.dart';
import 'package:Alhany/constants/constants.dart';
import 'package:Alhany/models/melody_model.dart';
import 'package:flutter/material.dart';
import 'package:html_editor/html_editor.dart';

class LyricsEditor extends StatefulWidget {
  final Melody melody;

  const LyricsEditor({Key key, this.melody}) : super(key: key);

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
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.cloud_upload),
        onPressed: updateLyrics,
      ),
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

  updateLyrics() async {
    final String lyrics = await keyEditor.currentState.getText();
    melodiesRef.doc(widget.melody.id).update({'lyrics': lyrics});
    AppUtil.showToast('Lyrics updated!');
  }
}
