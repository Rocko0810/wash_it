import 'package:flutter/cupertino.dart';


import '../Dimensions/dimensions.dart';
//no use
class AppIcon extends StatelessWidget {
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final double size;
   AppIcon ({Key? key,
     required this.icon,
     this.backgroundColor=const Color(0xffffffff),
     this.size=40,
     this.iconColor=const Color(0xff000000),
   }) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size/2),
        color: backgroundColor
      ),
      child: Icon(
        icon,
        color: iconColor,
        size: Dimensions.iconSize16,

      ),
    );
  }
}
