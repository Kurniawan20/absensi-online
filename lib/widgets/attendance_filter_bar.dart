import 'package:flutter/material.dart';

class AttendanceFilterBar extends StatelessWidget {
  final String currentFilter;
  final Function(String) onFilterChanged;

  const AttendanceFilterBar({
    Key? key,
    required this.currentFilter,
    required this.onFilterChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterChip(
            context: context,
            label: 'All',
            value: 'all',
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            context: context,
            label: 'Present',
            value: 'present',
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            context: context,
            label: 'Late',
            value: 'late',
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            context: context,
            label: 'Absent',
            value: 'absent',
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required BuildContext context,
    required String label,
    required String value,
  }) {
    final isSelected = currentFilter == value;
    final theme = Theme.of(context);

    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : theme.textTheme.bodyLarge?.color,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (bool selected) {
        if (selected) {
          onFilterChanged(value);
        }
      },
      backgroundColor: Colors.grey[200],
      selectedColor: theme.primaryColor,
      checkmarkColor: Colors.white,
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }
}
