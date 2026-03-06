import 'package:flutter/material.dart';

class InfoRowWidget extends StatelessWidget {
  final String label;
  final String value;

  const InfoRowWidget({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
			padding: const EdgeInsets.only(bottom: 8),
			child: Row(
				mainAxisAlignment: MainAxisAlignment.spaceBetween,
				children: [
					Text(
						label,
						style: Theme.of(context).textTheme.bodyMedium,
					),
					Text(
						value,
						style: Theme.of(context).textTheme.bodyMedium?.copyWith(
									fontWeight: FontWeight.bold,
								),
					),
				],
			),
		);
  }
}