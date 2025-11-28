import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Simple model for a single day's forecast.
class ForecastDay {
  final DateTime date;
  final double minTempC;
  final double maxTempC;
  final String conditionText;
  final String iconUrl; // full URL, ready to use in Image.network

  ForecastDay({
    required this.date,
    required this.minTempC,
    required this.maxTempC,
    required this.conditionText,
    required this.iconUrl,
  });

  factory ForecastDay.fromJson(Map<String, dynamic> json) {
    final day = json['day'] as Map<String, dynamic>;
    final condition = day['condition'] as Map<String, dynamic>;
    final iconPath = condition['icon'] as String? ?? '';

    return ForecastDay(
      date: DateTime.parse(json['date'] as String),
      minTempC: (day['mintemp_c'] as num).toDouble(),
      maxTempC: (day['maxtemp_c'] as num).toDouble(),
      conditionText: condition['text'] as String? ?? '',
      iconUrl: iconPath.startsWith('http')
          ? iconPath
          : 'https:$iconPath', // WeatherAPI returns URLs like //cdn...
    );
  }
}

/// Lightweight client for weatherapi.com
class WeatherApiClient {
  final String apiKey;
  final String baseUrl;

  const WeatherApiClient({
    required this.apiKey,
    this.baseUrl = 'https://api.weatherapi.com/v1',
  });

  /// Fetch a multi-day forecast for a given [location] (city name, lat/long, etc.)
  Future<List<ForecastDay>> fetchForecast({
    required String location,
    int days = 5,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/forecast.json?key=$apiKey&q=$location&days=$days&aqi=no&alerts=no',
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception(
        'Weather API error: ${response.statusCode} ${response.reasonPhrase}',
      );
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final forecast = data['forecast'] as Map<String, dynamic>;
    final forecastDays = forecast['forecastday'] as List<dynamic>;

    return forecastDays
        .map((e) => ForecastDay.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

/// A horizontal carousel of daily weather cards using WeatherAPI data.
///
/// Usage:
/// ```dart
/// WeatherCarousel(
///   apiKey: 'YOUR_API_KEY',
///   location: 'Ottawa',
///   days: 5,
/// )
/// ```

class WeatherCarousel extends StatefulWidget {
  final String apiKey;
  final String location;
  final int days;

  const WeatherCarousel({
    super.key,
    required this.apiKey,
    required this.location,
    this.days = 5,
  });

  @override
  State<WeatherCarousel> createState() => _WeatherCarouselState();
}

class _WeatherCarouselState extends State<WeatherCarousel> {
  late final PageController _controller;
  late final WeatherApiClient _client;

  @override
  void initState() {
    super.initState();
    // Smaller fraction -> cards are narrower, more than one visible.
    _controller = PageController(viewportFraction: 0.20);
    _client = WeatherApiClient(apiKey: widget.apiKey);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ForecastDay>>(
      future: _client.fetchForecast(
        location: widget.location,
        days: widget.days,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 220,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return SizedBox(
            height: 220,
            child: Center(
              child: Text(
                'Failed to load weather.\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox(
            height: 220,
            child: Center(child: Text('No forecast data')),
          );
        }

        final forecastDays = snapshot.data!;

        return SizedBox(
          height: 220,
          child: PageView.builder(
            controller: _controller,
            itemCount: forecastDays.length,
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  // Default values if page metrics aren't ready yet
                  double distanceFromCenter = 0;
                  if (_controller.position.hasContentDimensions &&
                      _controller.hasClients) {
                    final page =
                        _controller.page ?? _controller.initialPage.toDouble();
                    distanceFromCenter = (page - index).abs();
                  }

                  // Scale: 1.0 for center, ~0.75 for far sides
                  final double scale = (1 - distanceFromCenter * 0.3).clamp(
                    0.75,
                    1.0,
                  );

                  // Opacity: fade side items a bit
                  final double opacity = (1 - distanceFromCenter * 0.4).clamp(
                    0.5,
                    1.0,
                  );

                  return Center(
                    child: Opacity(
                      opacity: opacity,
                      child: Transform.scale(scale: scale, child: child),
                    ),
                  );
                },
                child: _WeatherDayCard(day: forecastDays[index]),
              );
            },
          ),
        );
      },
    );
  }
}

/// Single day card used inside the carousel.
class _WeatherDayCard extends StatelessWidget {
  final ForecastDay day;

  const _WeatherDayCard({required this.day});

  String _weekdayLabel(DateTime date) {
    const names = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return names[date.weekday % 7]; // weekday: 1..7 -> map to 0..6
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final weekday = _weekdayLabel(day.date);
    final dateLabel =
        '${day.date.year}-${day.date.month.toString().padLeft(2, '0')}-${day.date.day.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text(
                weekday,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                dateLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.network(
                    day.iconUrl,
                    width: 48,
                    height: 48,
                    errorBuilder: (context, error, stack) =>
                        const Icon(Icons.cloud),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${day.maxTempC.toStringAsFixed(0)}°C',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Min: ${day.minTempC.toStringAsFixed(0)}°C',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                day.conditionText,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
