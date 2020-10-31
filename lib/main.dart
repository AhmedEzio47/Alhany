import 'package:dubsmash/constants/colors.dart';
import 'package:dubsmash/services/auth.dart';
import 'package:dubsmash/services/auth_provider.dart';
import 'package:dubsmash/services/route_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:overlay_support/overlay_support.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({
    Key key,
  }) : super(key: key);

  static void restartApp(BuildContext context) {
    context.findAncestorStateOfType<_RestartWidgetState>().restartApp();
  }

  @override
  _RestartWidgetState createState() => _RestartWidgetState();
}

class _RestartWidgetState extends State<MyApp> {
  Key key = UniqueKey();

  void restartApp() {
    setState(() {
      key = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: key,
      child: AuthProvider(
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
      ),
    );
  }
}
