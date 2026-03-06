import 'package:flutter/material.dart';

class GameItemExpansionTile<T> extends StatelessWidget {
  final String title;
  final List<T> items;
  final String Function(T item) labelBuilder;
  
  const GameItemExpansionTile({
    super.key, 
    required this.title, 
    required this.items, 
    required this.labelBuilder});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ExpansionTile(
      title: Text(
        '$title (${items.length})',
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      children: 
        items.map((item) => ListTile(
          dense: true,
          title: Text(labelBuilder(item)),
        )).toList(),
    );
  }
}