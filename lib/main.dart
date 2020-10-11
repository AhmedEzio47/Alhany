import 'package:dubsmash/constants/colors.dart';
import 'package:dubsmash/services/auth.dart';
import 'package:dubsmash/services/auth_provider.dart';
import 'package:dubsmash/services/route_generator.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return AuthProvider(
      auth: Auth(),
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          primaryColor: MyColors.primaryColor,
          primaryColorDark: MyColors.darkPrimaryColor,
          primaryColorLight: MyColors.lightPrimaryColor,
          brightness: Brightness.light,
        ),
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        onGenerateRoute: RouteGenerator.generateRoute,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
    );
  }
}
