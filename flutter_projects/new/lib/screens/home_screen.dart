import 'package:flutter/material.dart';
import 'package:agri_advisor/l10n/app_localizations.dart';
import '../services/location_service.dart';
import '../services/weather_service.dart';
import '../widgets/bottom_nav.dart';
import '../routes.dart';
import '../main.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String temperature = "--";
  String weather = "Loading...";

  TextEditingController cityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadWeather();
  }

  void loadWeather() async {
    try {
      final position = await LocationService.getLocation();

      if (position == null) {
        setState(() {
          temperature = "--";
          weather = "Location Off";
        });
        return;
      }

      final data = await WeatherService.getWeatherByLocation(
        position.latitude,
        position.longitude,
      );

      setState(() {
        temperature = "${data['main']['temp']}°C";
        weather = data['weather'][0]['description'];
      });
    } catch (e) {
      setState(() {
        temperature = "--";
        weather = "Unavailable";
      });
    }
  }

  void searchWeather() async {
    if (cityController.text.isEmpty) return;

    try {
      final data = await WeatherService.getWeatherByCity(
        cityController.text,
      );

      setState(() {
        temperature = "${data['main']['temp']}°C";
        weather = data['weather'][0]['description'];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("City not found")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),

      /// 🔹 APP BAR
      appBar: AppBar(
        title: const Text(
          "Krishi",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),

        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.language), // 🌍 icon
            onSelected: (value) {
              if (value == 'en') {
                MyApp.setLocale(context, const Locale('en'));
              } else {
                MyApp.setLocale(context, const Locale('hi'));
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'en', child: Text("English")),
              const PopupMenuItem(value: 'hi', child: Text("हिंदी")),
            ],
          ),
        ],
      ),

      /// 🔹 BODY
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// 🔹 Welcome
              Text(
                loc.welcome ?? "Welcome",
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                loc.subtitle ?? "Manage your farm smartly",
                style: const TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 20),

              /// 🔍 Search Bar
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.green),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: TextField(
                        controller: cityController,
                        decoration: InputDecoration(
                          hintText: loc.search ?? "Search city...",
                          border: InputBorder.none,
                          icon: const Icon(Icons.search),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: searchWeather,
                    child: const Text("Go"),
                  )
                ],
              ),

              const SizedBox(height: 20),

              /// 🌤 WEATHER
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.weather ?? "Weather",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 6),
                          Text("$temperature • $weather"),
                          const SizedBox(height: 6),
                          Text(
                            weather.toLowerCase().contains("rain")
                                ? (loc.avoid ?? "Avoid spraying")
                                : (loc.good ?? "Good for farming"),
                            style: const TextStyle(color: Colors.green),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.wb_sunny, size: 36),
                  ],
                ),
              ),

              const SizedBox(height: 25),

        /// 🔹 FEATURE GRID
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildCard(context,
                icon: Icons.camera_alt_outlined,
                title: "Disease Detection",
                color: const Color(0xFF2E7D32),
                route: AppRoutes.disease),
            _buildCard(context,
                icon: Icons.smart_toy_outlined,
                title: "AI Advisory",
                color: const Color(0xFF1565C0),
                route: AppRoutes.advisory),
            _buildCard(context,
                icon: Icons.storefront_outlined,
                title: "Market Prices",
                color: const Color(0xFFF57C00),
                route: AppRoutes.market),
            _buildCard(context,
                icon: Icons.person_outline,
                title: "Profile",
                color: const Color(0xFF616161),
                route: AppRoutes.profile),
          ],
        ),

        const SizedBox(height: 30),

        /// 🔹 AI Banner
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
            ),
          ),
          child: Row(
            children: const [
              Icon(Icons.eco, color: Colors.white, size: 36),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  "Get daily farming tips and AI-powered insights to improve your crop yield.",
                  style: TextStyle(color: Colors.white),
                ),
              )
            ],
          ),
        ),

        const SizedBox(height: 20),

        /// 📊 Crop Health (RESTORED)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text("Crop Health Summary",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              LinearProgressIndicator(value: 0.75),
              SizedBox(height: 8),
              Text("Overall crop health is good (75%)"),
            ],
          ),
        ),

        const SizedBox(height: 20),

        /// 🖼 Banner (RESTORED)
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Image.asset(
            "assets/farm_banner.jpg",
            height: 170,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),

        const SizedBox(height: 80), // 🔥 IMPORTANT (prevents cut)
      ],
    ),
  ),
),

      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }

  Widget _buildCard(BuildContext context,
      {required IconData icon,
      required String title,
      required Color color,
      required String route}) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => Navigator.pushNamed(context, route),
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 10),
            Text(title),
          ],
        ),
      ),
    );
  }
}