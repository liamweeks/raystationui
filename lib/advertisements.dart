import 'package:flutter/material.dart';

class AdvertisementsCarousel extends StatefulWidget {
  const AdvertisementsCarousel({super.key});

  @override
  State<AdvertisementsCarousel> createState() => _AdvertisementsCarouselState();
}

class _AdvertisementsCarouselState extends State<AdvertisementsCarousel> {
  // Adjust this list to match the actual files in your /assets folder.
  final List<String> _adImages = const [
    'assets/badminton.png',
    'assets/townhall.png',
    'assets/movienight.png',
  ];

  late final PageController _pageController;
  double _currentPage = 0.0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.7);

    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page ?? 0.0;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Height of the whole carousel area
    return SizedBox(
      height: 300,
      child: PageView.builder(
        controller: _pageController,
        itemCount: _adImages.length,
        itemBuilder: (context, index) {
          final distance = (_currentPage - index).abs();

          // 1.0 for the centered (main) item, smaller for side items
          final double scale = (1.0 - (distance * 0.25)).clamp(
            0.75,
            1.0,
          ); // main > others

          // Slight fade on side items
          final double opacity = (1.0 - (distance * 0.4)).clamp(0.6, 1.0);

          return Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              width: 320 * scale,
              height: 320 * scale,
              child: Opacity(
                opacity: opacity,
                child: Image.asset(
                  _adImages[index],
                  fit: BoxFit.fill),
              ),
            ),
          );
        },
      ),
    );
  }
}
