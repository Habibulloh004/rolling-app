import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

import 'Colors.dart';

class cGoBack extends StatelessWidget {
  final Function()? onPressed;
  final Color color;
  const cGoBack({super.key, required this.onPressed, required this.color});

  @override
  Widget build(BuildContext context) {
    return IconButton(
        onPressed: onPressed,
        icon: Icon(
          Icons.navigate_before,
          color: color,
          size: 30,
        ));
  }
}

class cAppBarTittle extends StatelessWidget {
  final String text;
  const cAppBarTittle({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
          fontSize: 25,
          color: cDarkGreen,
          fontWeight: FontWeight.w700,
        ));
  }
}

class cImage extends StatelessWidget {
  final String name;
  final double? width;
  final double? height;
  const cImage({super.key, required this.name, this.width, this.height});

  @override
  Widget build(BuildContext context) {
    return Image.network(
      name,
      loadingBuilder: (BuildContext context, Widget child,
          ImageChunkEvent? loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: height,
              width: width,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        );
      },
      errorBuilder:
          (BuildContext context, Object exception, StackTrace? stackTrace) {
        return SvgPicture.asset(
          "assets/images/вектор.svg",
        );
      },
    );
  }
}

void claunchURL(String url) async {
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    throw 'Could not launch $url';
  }
}
