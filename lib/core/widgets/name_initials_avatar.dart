import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soya_app/core/constants/api_constants.dart';
import 'package:soya_app/util/colors.dart';

class NameInitialsAvatar extends StatefulWidget {
  final String name;
  final String? profileUrl;
  final double radius;
  final double? fontSize;
  final Color? backgroundColor;
  final Color? textColor;
  final String? fontFamily;

  const NameInitialsAvatar({
    super.key,
    required this.name,
    this.profileUrl,
    required this.radius,
    this.fontSize,
    this.backgroundColor,
    this.textColor,
    this.fontFamily,
  });

  @override
  State<NameInitialsAvatar> createState() => _NameInitialsAvatarState();
}

class _NameInitialsAvatarState extends State<NameInitialsAvatar> {
  String? _authToken;
  bool _imageError = false;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _authToken = prefs.getString('token');
      });
    }
  }

  String get _initials {
    if (widget.name.isEmpty) return "?";
    return widget.name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveBackgroundColor =
        widget.backgroundColor ?? appColor.withOpacity(0.1);
    final effectiveTextColor = widget.textColor ?? appColor;

    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: effectiveBackgroundColor,
      child: ClipOval(
        child: _buildContent(effectiveTextColor),
      ),
    );
  }

  Widget _buildContent(Color textColor) {
    if (widget.profileUrl != null &&
        widget.profileUrl!.isNotEmpty &&
        !_imageError) {
      final String fullUrl = widget.profileUrl!.startsWith('http')
          ? widget.profileUrl!
          : "${ApiConstants.imageBaseUrl}${widget.profileUrl!.startsWith('/') ? '' : '/'}${widget.profileUrl}";

      return Image.network(
        fullUrl,
        headers:
            _authToken != null ? {'Authorization': 'Bearer $_authToken'} : null,
        width: widget.radius * 2,
        height: widget.radius * 2,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_imageError) {
              setState(() {
                _imageError = true;
              });
            }
          });
          return _buildInitials(textColor);
        },
      );
    }

    return _buildInitials(textColor);
  }

  Widget _buildInitials(Color textColor) {
    return Center(
      child: Text(
        _initials,
        style: TextStyle(
          fontSize: widget.fontSize ?? (widget.radius * 0.8),
          color: textColor,
          fontWeight: FontWeight.bold,
          fontFamily: widget.fontFamily,
        ),
      ),
    );
  }
}
