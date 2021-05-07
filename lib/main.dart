import 'package:Alhany/constants/colors.dart';
import 'package:Alhany/services/AppleSignInAvailable.dart';
import 'package:Alhany/services/auth.dart';
import 'package:Alhany/services/auth_provider.dart';
import 'package:Alhany/services/route_generator.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appleSignInAvailable = await AppleSignInAvailable.check();
  await Firebase.initializeApp();
  runApp(Provider<AppleSignInAvailable>.value(
    value: appleSignInAvailable,
    child: MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({
    Key? key,
  }) : super(key: key);

  static void restartApp(BuildContext context) {
    context.findAncestorStateOfType<_RestartWidgetState>()?.restartApp();
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
          title: 'Alhani',
          theme: ThemeData(
            primaryColor: MyColors.primaryColor,
            primaryColorDark: MyColors.darkPrimaryColor,
            primaryColorLight: MyColors.lightPrimaryColor,
            accentColor: MyColors.accentColor,
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
