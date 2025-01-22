import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget {
  final String title;
  final TextStyle? style;
  const CustomAppBar({super.key, required this.title,this.style
  });

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return Padding(
      padding: EdgeInsets.all(8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: Container(
                decoration:
                BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                height: .05 *  size.height ,
                width: .05 *  size.height,
                child: Icon(Icons.arrow_back_ios_new)),
          ),
          SizedBox(
            width: 16.0,
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              style: style?? TextStyle(
                  fontSize: .03 * size.height,
                  fontWeight: FontWeight.w700,
                  color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
