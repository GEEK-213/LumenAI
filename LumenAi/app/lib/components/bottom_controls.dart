import 'package:flutter/material.dart';

class BottomControls extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onPrevios;
  final bool isFirst;
  final bool isLast;

  const BottomControls({
    super.key,
    required this.onNext,
    required this.onPrevios,
    required this.isFirst,
    required this.isLast,
    });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(onPressed: isFirst ? null : onPrevios ,
           icon: const Icon(Icons.arrow_back),
           color: Colors.white,
           ),
           IconButton(onPressed: isLast ? null : onNext ,
           icon: const Icon(Icons.arrow_forward),
           color: Colors.white,
           ),
        ],
      ),
    );
  }
}
