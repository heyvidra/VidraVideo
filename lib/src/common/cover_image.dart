import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../core/network/browser_headers.dart';

/// Every cover, backdrop and thumbnail this app draws.
///
/// It exists for the headers. Covers come from the catalogs' own CDNs, and a
/// hotlink check there would empty the grid — so an image load has to present
/// the same browser every other request does. That is one line, but it was one
/// line in seven places, and the version of it that gets forgotten is the one
/// added to the eighth.
///
/// [placeholder] and [errorWidget] are widgets rather than the package's
/// builders because not one of those seven call sites used the url or the
/// error they were handed.
class CoverImage extends StatelessWidget {
  const CoverImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.memCacheWidth,
    this.placeholder,
    this.errorWidget,
    this.fit = BoxFit.cover,
  });

  final String imageUrl;
  final double? width;
  final double? height;

  /// Decode width in PHYSICAL pixels. Load-bearing on an Intel Mac: a poster
  /// decoded at its source resolution and drawn into 168pt costs the memory
  /// and the GPU upload of an image nobody can see.
  final int? memCacheWidth;

  final Widget? placeholder;
  final Widget? errorWidget;
  final BoxFit fit;

  /// The package default keeps 200 files. A page is 35 posters, so the sixth
  /// page started evicting the first — and scrolling back up re-downloaded
  /// covers that had been on screen a minute earlier. Same store key as the
  /// default manager, so the files already on disk carry over.
  ///
  /// ponytail: a count, not a byte budget. ~1000 posters is tens of MB; put
  /// a size cap here if covers ever get large.
  static final _cache = CacheManager(
    Config(DefaultCacheManager.key, maxNrOfCacheObjects: 1000),
  );

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      cacheManager: _cache,
      httpHeaders: BrowserHeaders.forImage(Uri.parse(imageUrl)),
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: memCacheWidth,
      // The package default fades the placeholder OUT for a full second
      // before the 500ms fade-in even starts. The placeholder is a faint
      // tint, so that second is invisible — and it is a second of animation
      // frames per card, on every page of posters, while they decode.
      fadeOutDuration: Duration.zero,
      placeholder: placeholder == null ? null : (_, _) => placeholder!,
      errorWidget: errorWidget == null ? null : (_, _, _) => errorWidget!,
    );
  }
}
