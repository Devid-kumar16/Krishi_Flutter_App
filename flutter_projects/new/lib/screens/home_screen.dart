import 'package:flutter/material.dart';
import '../widgets/bottom_nav.dart';
import '../routes.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text(
          "Krishi",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
          const CircleAvatar(
            radius: 18,
            backgroundColor: Color(0xFFE8F5E9),
            child: Icon(Icons.person, color: Colors.green),
          ),
          const SizedBox(width: 16),
        ],
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// 🔹 Welcome Section
              const Text(
                "Welcome 👋",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                "Manage your farm smartly",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 24),

              /// 🔹 Feature Grid
              GridView.count(
                crossAxisCount: size.width > 900
                    ? 4
                    : size.width > 600
                        ? 3
                        : 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.1,
                children: [
                  _buildCard(
                    context,
                    icon: Icons.camera_alt_outlined,
                    title: "Disease Detection",
                    color: const Color(0xFF2E7D32),
                    route: AppRoutes.disease,
                  ),
                  _buildCard(
                    context,
                    icon: Icons.smart_toy_outlined,
                    title: "AI Advisory",
                    color: const Color(0xFF1565C0),
                    route: AppRoutes.advisory,
                  ),
                  _buildCard(
                    context,
                    icon: Icons.storefront_outlined,
                    title: "Market Prices",
                    color: const Color(0xFFF57C00),
                    route: AppRoutes.market,
                  ),
                  _buildCard(
                    context,
                    icon: Icons.person_outline,
                    title: "Profile",
                    color: const Color(0xFF616161),
                    route: AppRoutes.profile,
                  ),
                ],
              ),

              const SizedBox(height: 30),

              /// 🔹 AI Tip Banner
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF2E7D32),
                      Color(0xFF66BB6A),
                    ],
                  ),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.eco, color: Colors.white, size: 36),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        "Get daily farming tips and AI-powered insights to improve your crop yield.",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    )
                  ],
                ),
              ),

              const SizedBox(height: 30),

              /// 🌤 Weather Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Today's Weather",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          "28°C • Sunny",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    Icon(Icons.wb_sunny,
                        color: Colors.orange, size: 36),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              /// 📊 Crop Health Summary
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "Crop Health Summary",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: 0.75,
                      minHeight: 8,
                      borderRadius:
                          BorderRadius.all(Radius.circular(20)),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Overall crop health is good (75%)",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              /// 🖼 Farming Banner Image
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.asset(
                  "assets/farm_banner.jpg",
                  height: 170,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),

      bottomNavigationBar:
          const BottomNavBar(currentIndex: 0),
    );
  }

  /// 🔹 Modern Card UI
  Widget _buildCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required String route,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => Navigator.pushNamed(context, route),
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}