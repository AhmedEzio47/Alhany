import 'package:Alhany/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class PaywallWidget extends StatefulWidget {
  final String title;
  final String description;
  final List<Package> packages;
  final ValueChanged<Package> onClickedPackage;
  const PaywallWidget(
      {Key key,
      this.title,
      this.description,
      this.packages,
      this.onClickedPackage})
      : super(key: key);

  @override
  _PaywallWidgetState createState() => _PaywallWidgetState();
}

class _PaywallWidgetState extends State<PaywallWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: MyColors.primaryColor,
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.50),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            Text(
              widget.title,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: MyColors.textLightColor),
            ),
            const SizedBox(height: 16),
            Text(
              widget.description,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: MyColors.textLightColor),
            ),
            const SizedBox(height: 16),
            buildPackages(),
          ],
        ),
      ),
    );
  }

  Widget buildPackages() => ListView.builder(
      shrinkWrap: true,
      primary: false,
      itemCount: widget.packages.length,
      itemBuilder: (context, index) {
        final package = widget.packages[index];
        return buildPackage(context, package);
      });

  Widget buildPackage(BuildContext context, Package package) {
    final product = package.product;
    return Card(
      color: MyColors.accentColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Theme(
        data: ThemeData.light(),
        child: ListTile(
          contentPadding: EdgeInsets.all(8),
          title: Text(
            product.title,
            style: TextStyle(fontSize: 18),
          ),
          subtitle: Text(
            product.description,
            style: TextStyle(fontSize: 16),
          ),
          trailing: Text(
            product.priceString,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          onTap: () => widget.onClickedPackage(package),
        ),
      ),
    );
  }
}
