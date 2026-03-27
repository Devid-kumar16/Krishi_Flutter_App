import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:fl_chart/fl_chart.dart';
import '../services/market_services.dart';
import 'package:flutter_tts/flutter_tts.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
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

  // ================= FETCH DATA =================
  Future<void> fetchMarketData({String crop = "Tomato"}) async {
    setState(() => isLoading = true);

    final data = await MarketService.searchCrop(crop);

    setState(() {
      marketData = data;
      isLoading = false;

      // ✅ FIX: update graph data
      futurePrices = MarketService.getPriceHistory(crop);
    });
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

    String result = speech.lastRecognizedWords;
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
        builder: (context) => MarketDetailScreen(data: item),
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
                        hintText: isHindi
                            ? "फसल खोजें..."
                            : "Search crop...",
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
                          child: Text(
                              isHindi
                                  ? "कोई डेटा नहीं मिला"
                                  : "No market data found"),
                        )
                      : ListView.builder(
                          itemCount: marketData.length,
                          itemBuilder: (context, index) {

                            final item = marketData[index];

                            return InkWell(
                              onTap: () => openDetails(item),
                              child: Card(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 3,
                                child: ListTile(
                                  leading: const Icon(
                                      Icons.agriculture,
                                      color: Colors.green),
                                  title: Text(
                                    item["crop"] ?? "",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                      "${item["market"]}, ${item["state"]}"),
                                  trailing: Text(
                                    "₹${item["price"]}",
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
            ),
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

  const MarketDetailScreen({super.key, required this.data});

  @override
  State<MarketDetailScreen> createState() => _MarketDetailScreenState();
}

class _MarketDetailScreenState extends State<MarketDetailScreen> {

  bool isHindi = false;
  final FlutterTts tts = FlutterTts();

  Future<List<double>>? futurePrices;

  @override
  void initState() {
    super.initState();

    // ✅ REAL GRAPH DATA
    futurePrices =
        MarketService.getPriceHistory(widget.data["crop"]);
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
    String text = isHindi
        ? "फसल ${getValue("crop")} कीमत ${getValue("price")} रुपए"
        : "Crop ${getValue("crop")} price ${getValue("price")} rupees";

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
              setState(() => isHindi = !isHindi);
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
                  const Icon(Icons.agriculture,
                      color: Colors.white, size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      getValue("crop"),
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
buildTile(Icons.calendar_today, "Date", getValue("date")),

// 🔥 NEW (if available)
buildTile(Icons.trending_up, "Min Price", getValue("min_price")),
buildTile(Icons.trending_down, "Max Price", getValue("max_price")),
          ],
        ),
      ),
    );
  }

  Widget buildTile(IconData icon, String label, String value) {
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
          Expanded(child: Text("$label: $value")),
        ],
      ),
    );
  }
}