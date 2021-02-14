import 'package:Alhany/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';

class InAppBrowser extends StatefulWidget {
  String url = 'https://gl1tch3r.com';
  InAppBrowser(this.url);
  @override
  _InAppBrowserState createState() => _InAppBrowserState();
}

class _InAppBrowserState extends State<InAppBrowser> {
  final flutterWebViewPlugin = FlutterWebviewPlugin();
  // ignore: prefer_collection_literals
  final Set<JavascriptChannel> jsChannels = [
    JavascriptChannel(
        name: 'Print',
        onMessageReceived: (JavascriptMessage message) {
          print(message.message);
        }),
  ].toSet();
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        centerTitle: true,
      ),
      // We're using a Builder here so we have a context that is below the Scaffold
      // to allow calling Scaffold.of(context) so we can show a snackbar.
      body: SafeArea(
        child: Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Flexible(
                  flex: 10,
                  child: Stack(
                    children: <Widget>[
                      WebviewScaffold(
                        url: widget.url,
                        javascriptChannels: jsChannels,
                        mediaPlaybackRequiresUserGesture: false,
                        withZoom: true,
                        withLocalStorage: true,
                        hidden: true,
                        initialChild: Container(
                          color: MyColors.primaryColor,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        bottomNavigationBar: BottomAppBar(
                          child: Row(
                            children: <Widget>[
                              IconButton(
                                icon: const Icon(Icons.arrow_back_ios),
                                onPressed: () {
                                  flutterWebViewPlugin.goBack();
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.arrow_forward_ios),
                                onPressed: () {
                                  flutterWebViewPlugin.goForward();
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.autorenew),
                                onPressed: () {
                                  flutterWebViewPlugin.reload();
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
