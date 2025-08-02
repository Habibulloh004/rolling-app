import 'package:flutter/material.dart';
import 'package:sushi_alpha_project/Consts/Colors.dart';
import 'package:timeline_tile/timeline_tile.dart';

class MyTimeLine extends StatelessWidget {
  final bool isFirst;
  final bool isLast;
  final bool isPast;
  final String imageName;
  final String processName;
  final double sizeContainer;
  const MyTimeLine(
      {super.key,
      required this.isFirst,
      required this.isLast,
      required this.isPast,
      required this.imageName,
      required this.processName,
      required this.sizeContainer});

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return SizedBox(
      // defolt ) 0.12
      height: size.height * sizeContainer,
      child: TimelineTile(
        alignment: TimelineAlign.center,
        isFirst: isFirst,
        isLast: isLast,
        //decorations
        beforeLineStyle: LineStyle(
          color: isPast ? cDarkGreen : Colors.grey.shade400,
          thickness: 2,
        ),
        indicatorStyle: IndicatorStyle(
          color: isPast ? cDarkGreen : Colors.grey.shade400,
        ),
        startChild: Container(
          alignment: Alignment.center,
          child:
              Container(width: 50, height: 50, child: Image.asset(imageName)),
        ),
        endChild: Container(
          alignment: Alignment.center,
          child: Text(
            processName,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: cBlack,
            ),
          ),
        ),
      ),
    );
  }
}
