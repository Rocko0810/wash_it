import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../Dimensions/dimensions.dart';


class BigText extends StatelessWidget{
  Color? color;
  final String text;
  double size;
  TextOverflow overFlow;
  BigText({Key? key,  this.color = const Color(0xFF000000),
    required this.text,
    this.overFlow=TextOverflow.ellipsis,
    this.size=0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context){
    return Text(
      text,
      maxLines: 1,
      overflow: overFlow,
      style: GoogleFonts.roboto(
        fontWeight: FontWeight.w600,
        fontSize: size==0?Dimensions.font20:size, //if this.size==0 then dimension.font20 else size passed
        color: color,
      ),
    );
  }
}

