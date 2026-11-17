import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/constants/asset_constants.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.showWordmark = false,
    this.width = 28,
    this.height,
  });

  final bool showWordmark;
  final double width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final asset = switch ((showWordmark, isDark)) {
      (true, true) => AssetConstants.appLogoHorizontalWhite,
      (true, false) => AssetConstants.appLogoHorizontal,
      (false, true) => AssetConstants.appLogoSymbolWhite,
      (false, false) => AssetConstants.appLogoSymbol,
    };

    return SvgPicture.asset(
      asset,
      width: width,
      height: height,
      semanticsLabel: 'EcoVision',
    );
  }
}
