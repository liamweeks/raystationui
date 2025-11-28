import 'package:flutter/material.dart';

enum BatteryStatusType { low, mid, normal, full }

class BatteryIcon extends StatelessWidget {
  final int batteryLevel;
  final double segmentHeight;
  final double segmentWidth;
  final Color segmentColor;

  BatteryIcon({
    Key? key,
    this.batteryLevel = 0,
    this.segmentHeight = 10,
    this.segmentWidth = 30,
    this.segmentColor = Colors.transparent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: segmentWidth * 0.5,
          height: segmentHeight * 0.6,
          decoration: BoxDecoration(
            color: batteryLevel >= 5 ? segmentColor : Colors.transparent,
            border: const Border(
              top: BorderSide(width: 1.0, color: Colors.white),
              right: BorderSide(width: 1.0, color: Colors.white),
              left: BorderSide(width: 1.0, color: Colors.white),
            ),
          ),
        ),
        Container(
          width: segmentWidth,
          height: segmentHeight,
          decoration: BoxDecoration(
            color: batteryLevel >= 4 ? segmentColor : Colors.transparent,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(5),
              topLeft: Radius.circular(5),
            ),
            border: Border.all(color: Colors.white, width: 1),
          ),
        ),

        Container(
          width: segmentWidth,
          height: segmentHeight,
          decoration: BoxDecoration(
            color: batteryLevel >= 3 ? segmentColor : Colors.transparent,
            border: const Border(
              bottom: BorderSide(width: 1.0, color: Colors.white),
              right: BorderSide(width: 1.0, color: Colors.white),
              left: BorderSide(width: 1.0, color: Colors.white),
            ),
          ),
        ),

        Container(
          width: segmentWidth,
          height: segmentHeight,
          decoration: BoxDecoration(
            color: batteryLevel >= 2 ? segmentColor : Colors.transparent,
            border: const Border(
              right: BorderSide(width: 1.0, color: Colors.white),
              left: BorderSide(width: 1.0, color: Colors.white),
            ),
          ),
        ),

        Container(
          width: segmentWidth,
          height: segmentHeight,
          decoration: BoxDecoration(
            color: batteryLevel >= 1 ? segmentColor : Colors.transparent,
            borderRadius: const BorderRadius.only(
              bottomRight: Radius.circular(5),
              bottomLeft: Radius.circular(5),
            ),
            border: Border.all(color: Colors.white, width: 1.0),
          ),
        ),
      ],
    );
  }
}

Future<int> getBatteryLevel() async {
  await Future.delayed(const Duration(seconds: 1));
  return 5; // mock battery level
}
