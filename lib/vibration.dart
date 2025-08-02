import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class VibrationScreen extends StatelessWidget {
  const VibrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            children: [
              ElevatedButton(
                  onPressed: () {
                    HapticFeedback.vibrate();
                  },
                  child: Text("vibrate")),
              SizedBox(height: 20),
              ElevatedButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                  },
                  child: Text("selectionClick")),
              SizedBox(height: 20),
              ElevatedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                  },
                  child: Text("lightImpact")),
              SizedBox(height: 20),
              ElevatedButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                  },
                  child: Text("mediumImpact")),
              SizedBox(height: 20),
              ElevatedButton(
                  onPressed: () {
                    HapticFeedback.heavyImpact();
                  },
                  child: Text("heavyImpact")),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
