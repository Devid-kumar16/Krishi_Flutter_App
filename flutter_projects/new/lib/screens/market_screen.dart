import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:fl_chart/fl_chart.dart';
import '../services/market_services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

String translateToHindi(String text) {
  const Map<String, String> map = {
    "Tomato": "टमाटर",
    "Potato": "आलू",
    "Onion": "प्याज",
    "Maharashtra": "महाराष्ट्र",
    "APMC": "मंडी",
    "Market": "बाजार",
    "State": "राज्य",
    "District": "जिला",
    "Price": "कीमत",
    "Date": "तारीख",
    "Min Price": "न्यूनतम कीमत",
    "Max Price": "अधिकतम कीमत",
  };

  return map[text] ?? text;
}

class _MarketScreenState extends State<MarketScreen> {
  final TextEditingController searchController = TextEditingController();
  final stt.SpeechToText speech = stt.SpeechToText();

  List<dynamic> marketData = [];
  bool isLoading = true;
  bool isHindi = false;

  Future<List<double>>? futurePrices;

  @override
  void initState() {
    super.initState();

    // ✅ DEFAULT LOAD
    searchController.text = "Tomato";
    fetchMarketData(crop: "Tomato");
  }

    // ================= 🔥 AUTO TRANSLATION =================
  Future<String> translate(String text) async {
    if (!isHindi) return text;

    try {
      final url =
          "https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl=hi&dt=t&q=${Uri.encodeComponent(text)}";

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data[0][0][0];
      }
    } catch (e) {
      print("Translation error: $e");
    }

    return text;
  }

  Future<void> fetchMarketData({String crop = "Tomato"}) async {
    setState(() => isLoading = true);

    try {
      // ✅ FIX 1: Clean input BEFORE API call
      crop = crop.trim();

      if (crop.isEmpty) {
        crop = "Tomato";
      } else {
        crop = crop[0].toUpperCase() + crop.substring(1).toLowerCase();
      }

      print("SEARCHING FOR: $crop");

      // Convert Hindi → English for API search inputs
      Map<String, String> reverseMap = {
        "टमाटर": "Tomato",
        "आलू": "Potato",
        "प्याज": "Onion",
        "बैंगन": "Brinjal",
      };

      if (reverseMap.containsKey(crop)) {
        crop = reverseMap[crop]!;
      }

      final data = await MarketService.searchCrop(crop);

      print("DATA LENGTH: ${data.length}");

      setState(() {
        marketData = data;
        isLoading = false;
        futurePrices = MarketService.getPriceHistory(crop);
      });
    } catch (e) {
      print("FETCH ERROR: $e");

      if (!mounted) return;

      setState(() {
        marketData = [];
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load data")),
      );
    }
  }

  // ================= VOICE SEARCH =================
  Future<void> startVoiceSearch() async {
    bool available = await speech.initialize();
    if (!available) return;

    await speech.listen(
      localeId: isHindi ? "hi_IN" : "en_IN",
      listenFor: const Duration(seconds: 4),
    );

    await Future.delayed(const Duration(seconds: 4));
    await speech.stop();

    String result = speech.lastRecognizedWords.trim();

    // 🔥 CLEAN INPUT
    if (result.isNotEmpty) {
      result = result.split(" ").first;
    }

    print("VOICE INPUT: $result");

    searchController.text = result;
    fetchMarketData(crop: result);
  }

  // ================= GRAPH =================
  Widget buildGraph() {
    if (futurePrices == null) return const SizedBox();

    return FutureBuilder<List<double>>(
      future: futurePrices,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          );
        }

        final prices = snapshot.data!;

        if (prices.isEmpty) {
          return const Text("No price history available");
        }

        return SizedBox(
          height: 220,
          child: LineChart(
            LineChartData(
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  isCurved: true,
                  spots: List.generate(
                    prices.length,
                    (i) => FlSpot(i.toDouble(), prices[i]),
                  ),
                  dotData: FlDotData(show: true),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ================= NAVIGATE =================
  void openDetails(dynamic item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MarketDetailScreen(
          data: item,
          isHindi: isHindi,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isHindi ? "मंडी भाव" : "Market Prices"),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () {
              setState(() => isHindi = !isHindi);
            },
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => fetchMarketData(crop: searchController.text),
        child: Column(
          children: [
            // 🔍 SEARCH BAR
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: isHindi ? "फसल खोजें..." : "Search crop...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onSubmitted: (value) {
                        fetchMarketData(crop: value);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.mic),
                    onPressed: startVoiceSearch,
                  )
                ],
              ),
            ),

            // 📊 GRAPH
            if (!isLoading) buildGraph(),

            // 📋 LIST
Expanded(
  child: isLoading
      ? const Center(child: CircularProgressIndicator())
      : marketData.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off,
                      size: 60, color: Colors.grey),
                  const SizedBox(height: 10),
                  Text(
                    isHindi
                        ? "कोई डेटा नहीं मिला"
                        : "No market data found",
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      fetchMarketData(
                          crop: searchController.text);
                    },
                    child: const Text("Retry"),
                  )
                ],
              ),
            )
          : ListView.builder(
              itemCount: marketData.length,
              itemBuilder: (context, index) {
                final item = marketData[index];

                // ✅ SAFE VALUES (NO CRASH)
                final crop =
                    (item["crop"] ?? "").toString();
                final market =
                    (item["market"] ?? "").toString();
                final state =
                    (item["state"] ?? "").toString();
                final price =
                    (item["price"] ?? "").toString();

                return InkWell(
                  onTap: () => openDetails(item),
                  child: Card(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                    elevation: 3,
                    child: ListTile(
                      leading: const Icon(
                        Icons.agriculture,
                        color: Colors.green,
                      ),

                      // ✅ FIXED (NO ERROR)
title: FutureBuilder<String>(
  future: translate(crop),
  builder: (context, snapshot) {
    return Text(
      snapshot.data ?? (isHindi ? translateToHindi(crop) : crop),
      style: const TextStyle(fontWeight: FontWeight.bold),
    );
  },
),


subtitle: FutureBuilder<String>(
  future: translate("$market, $state"),
  builder: (context, snapshot) {
    return Text(
      snapshot.data ??
          (isHindi
              ? "${translateToHindi(market)}, ${translateToHindi(state)}"
              : "$market, $state"),
    );
  },
),

                      trailing: Text(
                        "₹$price",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
)
          ],
        ),
      ),
    );
  }
}

//////////////////////////////////////////////////////////////////
// 🔥 DETAIL SCREEN WITH REAL GRAPH
//////////////////////////////////////////////////////////////////

class MarketDetailScreen extends StatefulWidget {
  final dynamic data;
  final bool isHindi;

  const MarketDetailScreen({
    super.key,
    required this.data,
    required this.isHindi,
  });

  @override
  State<MarketDetailScreen> createState() => _MarketDetailScreenState();
}

String getCurrentDate() {
  final now = DateTime.now();
  return "${now.day}/${now.month}/${now.year}";
}

class _MarketDetailScreenState extends State<MarketDetailScreen> {
  late bool isHindi;
  final FlutterTts tts = FlutterTts();

  Future<List<double>>? futurePrices;

  @override
  void initState() {
    super.initState();
    isHindi = widget.isHindi;

    // ✅ REAL GRAPH DATA
    futurePrices =
        MarketService.getPriceHistory(widget.data["crop"].toString());
  }

  String getValue(String key) {
    final value = widget.data[key];

    if (value == null ||
        value.toString().trim().isEmpty ||
        value.toString().toLowerCase() == "null") {
      return "Not Available";
    }

    return value.toString();
  }

  Future<void> speak() async {
    final crop = getValue("crop");
    final displayCrop = isHindi ? translateToHindi(crop) : crop;

    String text = isHindi
        ? "फसल $displayCrop कीमत ${getValue("price")} रुपए"
        : "Crop $displayCrop price ${getValue("price")} rupees";

    await tts.setLanguage(isHindi ? "hi-IN" : "en-US");
    await tts.speak(text);
  }

  Widget buildGraph() {
    return FutureBuilder<List<double>>(
      future: futurePrices,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        final prices = snapshot.data!;

        if (prices.isEmpty) {
          return const Text("No history data");
        }

        return SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  isCurved: true,
                  spots: List.generate(
                    prices.length,
                    (i) => FlSpot(i.toDouble(), prices[i]),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isHindi ? "मंडी विवरण" : "Market Details"),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
 onPressed: () {
  setState(() {
    isHindi = !isHindi;
  });

},
          ),
          IconButton(
            icon: const Icon(Icons.volume_up),
            onPressed: speak,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // HEADER
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.green, Colors.teal],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.agriculture, color: Colors.white, size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isHindi
                          ? translateToHindi(getValue("crop"))
                          : getValue("crop"),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    "₹${getValue("price")}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // REAL GRAPH
            buildGraph(),

            const SizedBox(height: 16),

            // DETAILS
            buildTile(Icons.store, "Market", getValue("market")),
            buildTile(Icons.location_on, "State", getValue("state")),
            buildTile(Icons.map, "District", getValue("district")),
            buildTile(Icons.currency_rupee, "Price", "₹${getValue("price")}"),
            buildTile(Icons.calendar_today, "Date", getCurrentDate()),

// 🔥 NEW (if available)
            buildTile(Icons.trending_up, "Min Price", getValue("min_price")),
            buildTile(Icons.trending_down, "Max Price", getValue("max_price")),
          ],
        ),
      ),
    );
  }

Widget buildTile(IconData icon, String label, String value) {
  final displayLabel = isHindi ? translateToHindi(label) : label;
  final displayValue = isHindi ? translateToHindi(value) : value;

  return Container(
    margin: const EdgeInsets.symmetric(vertical: 6),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Icon(icon, color: Colors.green),
        const SizedBox(width: 10),
        Expanded(
          child: Text("$displayLabel: $displayValue"),
        ),
      ],
    ),
  );
}
}
