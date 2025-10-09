import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// Advanced Image Optimization and Caching System
class ImageOptimizer {
  static final ImageOptimizer _instance = ImageOptimizer._internal();
  factory ImageOptimizer() => _instance;
  ImageOptimizer._internal();

  // Cache configuration
  static const int _maxCacheSize = 100 * 1024 * 1024; // 100MB
  static const int _maxCacheEntries = 500;
  static const Duration _cacheExpiry = Duration(hours: 24);
  
  // Image cache
  final Map<String, _CacheEntry> _imageCache = {};
  final Map<String, Completer<ui.Image>> _loadingImages = {};
  
  // Memory management
  int _currentCacheSize = 0;
  final List<String> _accessOrder = [];

  /// Optimize and cache image
  Future<ui.Image> optimizeImage(
    String imageUrl, {
    int? targetWidth,
    int? targetHeight,
    ImageFormat format = ImageFormat.webp,
    int quality = 85,
    bool enableCaching = true,
  }) async {
    final cacheKey = _generateCacheKey(
      imageUrl,
      targetWidth,
      targetHeight,
      format,
      quality,
    );

    // Check cache first
    if (enableCaching && _imageCache.containsKey(cacheKey)) {
      final entry = _imageCache[cacheKey]!;
      if (!entry.isExpired) {
        _updateAccessOrder(cacheKey);
        return entry.image;
      } else {
        _removeFromCache(cacheKey);
      }
    }

    // Check if already loading
    if (_loadingImages.containsKey(cacheKey)) {
      return _loadingImages[cacheKey]!.future;
    }

    // Start loading
    final completer = Completer<ui.Image>();
    _loadingImages[cacheKey] = completer;

    try {
      final image = await _loadAndOptimizeImage(
        imageUrl,
        targetWidth: targetWidth,
        targetHeight: targetHeight,
        format: format,
        quality: quality,
      );

      if (enableCaching) {
        _addToCache(cacheKey, image);
      }

      completer.complete(image);
      return image;
    } catch (error) {
      completer.completeError(error);
      rethrow;
    } finally {
      _loadingImages.remove(cacheKey);
    }
  }

  /// Load and optimize image from URL
  Future<ui.Image> _loadAndOptimizeImage(
    String imageUrl, {
    int? targetWidth,
    int? targetHeight,
    ImageFormat format = ImageFormat.webp,
    int quality = 85,
  }) async {
    // Load image data
    final imageData = await _loadImageData(imageUrl);
    
    // Decode image
    final codec = await ui.instantiateImageCodec(
      imageData,
      targetWidth: targetWidth,
      targetHeight: targetHeight,
    );
    
    final frameInfo = await codec.getNextFrame();
    return frameInfo.image;
  }

  /// Load image data from URL
  Future<Uint8List> _loadImageData(String imageUrl) async {
    if (imageUrl.startsWith('assets/')) {
      // Load from assets
      final byteData = await rootBundle.load(imageUrl);
      return byteData.buffer.asUint8List();
    } else if (imageUrl.startsWith('http')) {
      // Load from network (simplified - in real app use http package)
      throw UnimplementedError('Network loading requires http package');
    } else {
      // Load from file system
      throw UnimplementedError('File system loading not implemented');
    }
  }

  /// Generate cache key
  String _generateCacheKey(
    String imageUrl,
    int? targetWidth,
    int? targetHeight,
    ImageFormat format,
    int quality,
  ) {
    final key = '$imageUrl:${targetWidth ?? 0}:${targetHeight ?? 0}:${format.name}:$quality';
    final bytes = utf8.encode(key);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Add image to cache
  void _addToCache(String key, ui.Image image) {
    final entry = _CacheEntry(
      image: image,
      size: _estimateImageSize(image),
      timestamp: DateTime.now(),
    );

    // Check if we need to make space
    _ensureCacheSpace(entry.size);

    _imageCache[key] = entry;
    _currentCacheSize += entry.size;
    _updateAccessOrder(key);
  }

  /// Remove image from cache
  void _removeFromCache(String key) {
    final entry = _imageCache.remove(key);
    if (entry != null) {
      _currentCacheSize -= entry.size;
      entry.image.dispose();
    }
    _accessOrder.remove(key);
  }

  /// Ensure cache has enough space
  void _ensureCacheSpace(int requiredSize) {
    while ((_currentCacheSize + requiredSize > _maxCacheSize ||
            _imageCache.length >= _maxCacheEntries) &&
           _accessOrder.isNotEmpty) {
      final oldestKey = _accessOrder.first;
      _removeFromCache(oldestKey);
    }
  }

  /// Update access order for LRU
  void _updateAccessOrder(String key) {
    _accessOrder.remove(key);
    _accessOrder.add(key);
  }

  /// Estimate image memory size
  int _estimateImageSize(ui.Image image) {
    return image.width * image.height * 4; // RGBA
  }

  /// Clear expired cache entries
  void clearExpiredCache() {
    final now = DateTime.now();
    final expiredKeys = _imageCache.entries
        .where((entry) => entry.value.isExpired)
        .map((entry) => entry.key)
        .toList();

    for (final key in expiredKeys) {
      _removeFromCache(key);
    }
  }

  /// Clear all cache
  void clearCache() {
    for (final entry in _imageCache.values) {
      entry.image.dispose();
    }
    _imageCache.clear();
    _accessOrder.clear();
    _currentCacheSize = 0;
  }

  /// Get cache statistics
  CacheStats getCacheStats() {
    return CacheStats(
      entriesCount: _imageCache.length,
      totalSizeBytes: _currentCacheSize,
      maxSizeBytes: _maxCacheSize,
      hitRate: 0.0, // Would need to track hits/misses
    );
  }
}

/// Cache entry class
class _CacheEntry {
  const _CacheEntry({
    required this.image,
    required this.size,
    required this.timestamp,
  });

  final ui.Image image;
  final int size;
  final DateTime timestamp;

  bool get isExpired => 
      DateTime.now().difference(timestamp) > ImageOptimizer._cacheExpiry;
}

/// Cache statistics
class CacheStats {
  const CacheStats({
    required this.entriesCount,
    required this.totalSizeBytes,
    required this.maxSizeBytes,
    required this.hitRate,
  });

  final int entriesCount;
  final int totalSizeBytes;
  final int maxSizeBytes;
  final double hitRate;

  double get usagePercentage => totalSizeBytes / maxSizeBytes;
}

/// Image format enumeration
enum ImageFormat {
  jpeg,
  png,
  webp,
  avif,
}

/// Optimized Image Widget
class OptimizedImage extends StatefulWidget {
  const OptimizedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.fadeInDuration = const Duration(milliseconds: 300),
    this.quality = 85,
    this.format = ImageFormat.webp,
    this.enableCaching = true,
    this.lazyLoad = true,
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Duration fadeInDuration;
  final int quality;
  final ImageFormat format;
  final bool enableCaching;
  final bool lazyLoad;

  @override
  State<OptimizedImage> createState() => _OptimizedImageState();
}

class _OptimizedImageState extends State<OptimizedImage>
    with SingleTickerProviderStateMixin {
  ui.Image? _image;
  bool _isLoading = false;
  bool _hasError = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: widget.fadeInDuration,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    if (!widget.lazyLoad) {
      _loadImage();
    }
  }

  @override
  void didUpdateWidget(OptimizedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _loadImage();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.lazyLoad && _image == null && !_isLoading) {
      return LayoutBuilder(
        builder: (context, constraints) {
          // Check if widget is visible
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _shouldLoadImage()) {
              _loadImage();
            }
          });
          
          return _buildPlaceholder();
        },
      );
    }

    if (_hasError) {
      return _buildErrorWidget();
    }

    if (_image == null) {
      return _buildPlaceholder();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: CustomPaint(
        painter: _ImagePainter(_image!),
        size: Size(
          widget.width ?? double.infinity,
          widget.height ?? double.infinity,
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return widget.placeholder ??
        Container(
          width: widget.width,
          height: widget.height,
          color: Colors.grey[300],
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        );
  }

  Widget _buildErrorWidget() {
    return widget.errorWidget ??
        Container(
          width: widget.width,
          height: widget.height,
          color: Colors.grey[300],
          child: const Icon(
            Icons.error,
            color: Colors.red,
          ),
        );
  }

  bool _shouldLoadImage() {
    // Simplified visibility check
    // In a real implementation, you would check viewport intersection
    return true;
  }

  Future<void> _loadImage() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final image = await ImageOptimizer().optimizeImage(
        widget.imageUrl,
        targetWidth: widget.width?.toInt(),
        targetHeight: widget.height?.toInt(),
        format: widget.format,
        quality: widget.quality,
        enableCaching: widget.enableCaching,
      );

      if (mounted) {
        setState(() {
          _image = image;
          _isLoading = false;
        });
        _fadeController.forward();
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }
}

/// Custom painter for optimized image rendering
class _ImagePainter extends CustomPainter {
  const _ImagePainter(this.image);

  final ui.Image image;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..filterQuality = FilterQuality.high
      ..isAntiAlias = true;

    final srcRect = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );

    final dstRect = Rect.fromLTWH(0, 0, size.width, size.height);

    canvas.drawImageRect(image, srcRect, dstRect, paint);
  }

  @override
  bool shouldRepaint(_ImagePainter oldDelegate) {
    return oldDelegate.image != image;
  }
}

/// Preload images utility
class ImagePreloader {
  static final Map<String, Future<ui.Image>> _preloadCache = {};

  /// Preload image for future use
  static Future<ui.Image> preloadImage(
    String imageUrl, {
    int? targetWidth,
    int? targetHeight,
    ImageFormat format = ImageFormat.webp,
    int quality = 85,
  }) {
    final cacheKey = '$imageUrl:${targetWidth ?? 0}:${targetHeight ?? 0}';
    
    if (_preloadCache.containsKey(cacheKey)) {
      return _preloadCache[cacheKey]!;
    }

    final future = ImageOptimizer().optimizeImage(
      imageUrl,
      targetWidth: targetWidth,
      targetHeight: targetHeight,
      format: format,
      quality: quality,
    );

    _preloadCache[cacheKey] = future;
    return future;
  }

  /// Preload multiple images
  static Future<List<ui.Image>> preloadImages(
    List<String> imageUrls, {
    int? targetWidth,
    int? targetHeight,
    ImageFormat format = ImageFormat.webp,
    int quality = 85,
  }) {
    final futures = imageUrls.map((url) => preloadImage(
          url,
          targetWidth: targetWidth,
          targetHeight: targetHeight,
          format: format,
          quality: quality,
        ));

    return Future.wait(futures);
  }

  /// Clear preload cache
  static void clearPreloadCache() {
    _preloadCache.clear();
  }
}