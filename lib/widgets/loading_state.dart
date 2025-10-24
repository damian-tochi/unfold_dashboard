import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LoadingState extends StatelessWidget {
  const LoadingState({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Lottie.asset('assets/lottie/circular_loading_anim.json', height: 120, width: 120),
          SizedBox(height: 12),
        ]),
      ),
    );
  }
}