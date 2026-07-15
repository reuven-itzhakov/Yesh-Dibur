import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class InterestsSelector extends StatefulWidget {
  final Function(List<String>) onInterestsChanged;

  const InterestsSelector({super.key, required this.onInterestsChanged});

  @override
  State<InterestsSelector> createState() => _InterestsSelectorState();
}

class _InterestsSelectorState extends State<InterestsSelector> {
  // רשימה לדוגמה, בהמשך נוכל למשוך אותה מהשרת
  final List<String> _availableInterests = [
    'מוזיקה', 'גיימינג', 'ספורט', 'טכנולוגיה', 'אופנה', 
    'קולנוע וסדרות', 'אוכל', 'טיולים', 'אמנות', 'כושר'
  ];
  
  final List<String> _selectedInterests = [];

  void _toggleInterest(String interest) {
    setState(() {
      if (_selectedInterests.contains(interest)) {
        _selectedInterests.remove(interest);
      } else {
        if (_selectedInterests.length < 5) {
          _selectedInterests.add(interest);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ניתן לבחור עד 5 תחומי עניין בלבד')),
          );
        }
      }
    });
    widget.onInterestsChanged(_selectedInterests);
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: _availableInterests.map((interest) {
        final isSelected = _selectedInterests.contains(interest);
        return FilterChip(
          label: Text(interest),
          selected: isSelected,
          onSelected: (_) => _toggleInterest(interest),
          selectedColor: AppColors.primary.withOpacity(0.2),
          checkmarkColor: AppColors.primary,
          labelStyle: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }
}