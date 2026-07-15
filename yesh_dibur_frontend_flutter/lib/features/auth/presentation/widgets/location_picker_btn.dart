import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/user_model.dart';

class LocationPickerBtn extends StatefulWidget {
  final Function(LocationModel) onLocationSelected;

  const LocationPickerBtn({super.key, required this.onLocationSelected});

  @override
  State<LocationPickerBtn> createState() => _LocationPickerBtnState();
}

class _LocationPickerBtnState extends State<LocationPickerBtn> {
  bool _isLoading = false;
  String _locationText = 'איתור מיקום נוכחי';

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);

    bool serviceEnabled;
    LocationPermission permission;

    // בדיקה האם שירותי המיקום פועלים
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _isLoading = false;
        _locationText = 'שירותי המיקום כבויים';
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _isLoading = false;
          _locationText = 'הרשאת מיקום נדחתה';
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _isLoading = false;
        _locationText = 'הרשאות חסומות תמידית';
      });
      return;
    }

    // שליפת המיקום
    Position position = await Geolocator.getCurrentPosition();
    
    setState(() {
      _isLoading = false;
      _locationText = 'מיקום נקלט בהצלחה!';
    });

    // העברת הנתונים החוצה
    widget.onLocationSelected(
      LocationModel(lat: position.latitude, lng: position.longitude),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _isLoading ? null : _getCurrentLocation,
      icon: _isLoading 
          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.my_location),
      label: Text(_locationText),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}