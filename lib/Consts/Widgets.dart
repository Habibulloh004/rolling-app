import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
    // Handle empty or null image names
    if (name.isEmpty || name == " ") {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          Icons.image_not_supported,
          color: Colors.grey[600],
          size: 40,
        ),
      );
    }

    // Use CachedNetworkImage for better performance and caching
    return CachedNetworkImage(
      imageUrl: name,
      width: width,
      height: height,
      fit: BoxFit.cover,
      placeholder: (context, url) => Shimmer.fromColors(
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
      errorWidget: (context, url, error) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(10),
        ),
        child: SvgPicture.asset(
          "assets/images/вектор.svg",
          fit: BoxFit.contain,
        ),
      ),
    );

    /* Original implementation kept as fallback
    return Image.network(
      name,
      width: width,
      height: height,
      fit: BoxFit.cover,
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
    */
  }
}

void claunchURL(String url) async {
  final Uri uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  } else {
    throw 'Could not launch $url';
  }
}