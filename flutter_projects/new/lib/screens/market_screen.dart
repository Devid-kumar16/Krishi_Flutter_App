import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:fl_chart/fl_chart.dart';
import '../services/market_services.dart';

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

  @override
  void initState() {
    super.initState();
    fetchMarketData();
  }

  // ================= FETCH DATA =================
  Future<void> fetchMarketData({String crop = ""}) async {

    setState(() => isLoading = true);

    final data = crop.isEmpty
        ? await MarketService.getAllMarketData()
        : await MarketService.searchCrop(crop);

    setState(() {
      marketData = data;
      isLoading = false;
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

  // ================= PRICE GRAPH =================
Widget buildGraph() {
  if (marketData.isEmpty) return const SizedBox();

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
              marketData.length,
              (index) {
                final rawPrice = marketData[index]["price_per_quintal"];

                // ✅ SAFE CONVERSION
                double price = double.tryParse(
                      rawPrice?.toString() ?? "0",
                    ) ??
                    0.0;

                return FlSpot(
                  index.toDouble(),
                  price,
                );
              },
            ),
          ),
        ],
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
        onRefresh: fetchMarketData,
        child: Column(
          children: [

            // SEARCH BAR
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

            if (!isLoading) buildGraph(),

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

                            final crop = marketData[index];

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              child: ListTile(
                                leading: const Icon(
                                    Icons.agriculture,
                                    color: Colors.green),
                                title: Text(
                                  crop["crop_name"] ?? "",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                    "Mandi: ${crop["mandi_name"] ?? ""}"),
trailing: Builder(
  builder: (context) {
    final rawPrice = crop["price_per_quintal"];
    final price =
        double.tryParse(rawPrice?.toString() ?? "0") ?? 0.0;

    return Text(
      "₹${price.toStringAsFixed(2)}/qtl",
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.green,
      ),
    );
  },
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
