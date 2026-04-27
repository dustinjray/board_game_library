import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:url_launcher/url_launcher.dart';

class BggLinkButton extends StatelessWidget {
  const BggLinkButton({super.key});

  static final Uri _bggUri = Uri.parse('https://boardgamegeek.com/');

  Future<void> _openBgg() async {
    await launchUrl(_bggUri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Powered by BoardGameGeek',
      onPressed: _openBgg,
      icon: SvgPicture.asset(
        'assets/svg/powered-by-bgg-rgb.svg',
        width: 40,
        height: 20,
      )
    );
  }

}