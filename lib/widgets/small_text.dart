import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SmallText extends StatelessWidget{
  Color? color;
  final String text;
  double size;
  double height;
  SmallText({Key? key,  this.color = const Color(0xFF000000),
    required this.text,
    this.size=14,  // size of the small text
    this.height=1.2,  //distance bw two lines
  }) : super(key: key);

  @override
  Widget build(BuildContext context){
    return Text(
      text,
      style: GoogleFonts.roboto(
        //fontWeight: FontWeight.w400,
        fontSize: size,
        color: color,
        height: height,
      ),
    );
  }
}
