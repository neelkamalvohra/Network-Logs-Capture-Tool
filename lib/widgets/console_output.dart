import 'package:flutter/material.dart';

class ConsoleOutput extends StatelessWidget {
  final String output;
  final ScrollController scrollController;
  
  const ConsoleOutput({
    super.key,
    required this.output,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade700),
      ),
      child: output.isEmpty
          ? const Center(
              child: Text(
                'Captured output will appear here',
                style: TextStyle(color: Colors.grey),
              ),
            )
          : Scrollbar(
              controller: scrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(12.0),
                child: SelectableText(
                  output,
                  style: const TextStyle(
                    color: Colors.green,
                    fontFamily: 'monospace',
                    fontSize: 14,
                  ),
                ),
              ),
            ),
    );
  }
}
