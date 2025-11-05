import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class SalesAnalyticsPage extends StatefulWidget {
  const SalesAnalyticsPage({super.key});

  @override
  State<SalesAnalyticsPage> createState() => _SalesAnalyticsPageState();
}

class _SalesAnalyticsPageState extends State<SalesAnalyticsPage> {
  bool loading = true;

  double todayRevenue = 0;
  double monthRevenue = 0;
  int todayOrders = 0;
  int totalOrders = 0;

  List<FlSpot> last7DaysSpots = [];
  List<Map<String, dynamic>> bestSellers = [];

  @override
  void initState() {
    super.initState();
    loadAnalytics();
  }

  Future<void> loadAnalytics() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final monthStart = DateTime(now.year, now.month, 1);

    // ✅ ดึงทุกออเดอร์
    final ordersSnap = await FirebaseFirestore.instance
        .collection("Orders")
        .orderBy("createdAt", descending: true)
        .get();

    double todaySum = 0;
    double monthSum = 0;
    int todayCount = 0;
    int totalCount = ordersSnap.docs.length;

    Map<String, double> revenueLast7 = {};
    Map<String, int> productCount = {};

    for (var doc in ordersSnap.docs) {
      final data = doc.data();

      // ✅ ดึงวันจาก createdAt หรือ orderDate
      Timestamp? ts = data["createdAt"] ?? data["orderDate"];
      if (ts == null) continue;
      final date = ts.toDate();

      // ✅ คำนวณยอด (Price * Qty)
      double price = double.tryParse("${data["Price"] ?? 0}") ?? 0;
      int qty = int.tryParse("${data["Qty"] ?? 1}") ?? 1;
      double total = price * qty;

      // ✅ Today
      if (date.isAfter(todayStart)) {
        todaySum += total;
        todayCount++;
      }

      // ✅ Month
      if (date.isAfter(monthStart)) {
        monthSum += total;
      }

      // ✅ Last 7 days
      for (int i = 0; i < 7; i++) {
        final d = now.subtract(Duration(days: i));
        final dStart = DateTime(d.year, d.month, d.day);
        final dEnd = dStart.add(const Duration(days: 1));

        if (date.isAfter(dStart) && date.isBefore(dEnd)) {
          String key = "${d.month}/${d.day}";
          revenueLast7[key] = (revenueLast7[key] ?? 0) + total;
        }
      }

      // ✅ best seller
      final name = data["Product"] ?? "Unknown";
      productCount[name] = (productCount[name] ?? 0) + qty;
    }

    // ✅ spots
    List<FlSpot> spots = [];
    int index = 0;
    revenueLast7.entries.forEach((e) {
      spots.add(FlSpot(index.toDouble(), e.value));
      index++;
    });

    // ✅ Top 5
    List<Map<String, dynamic>> topProducts = productCount.entries
        .map((e) => {"name": e.key, "count": e.value})
        .toList();
    topProducts.sort((a, b) => b["count"].compareTo(a["count"]));
    topProducts = topProducts.take(5).toList();

    setState(() {
      todayRevenue = todaySum;
      monthRevenue = monthSum;
      todayOrders = todayCount;
      totalOrders = totalCount;
      last7DaysSpots = spots;
      bestSellers = topProducts;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0F7FA),
      appBar: AppBar(
        title: const Text("สถิติการขาย"),
        backgroundColor: const Color(0xFF00ACC1),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  buildSummaryCard(),
                  const SizedBox(height: 20),
                  buildLast7DaysChart(),
                  const SizedBox(height: 20),
                  buildBestSellers(),
                ],
              ),
            ),
    );
  }

  // --- UI ---
  Widget buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _box(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title("ภาพรวมวันนี้"),
          _row("ยอดขายวันนี้", "฿${todayRevenue.toStringAsFixed(0)}"),
          _row("จำนวนออเดอร์", "$todayOrders รายการ"),
          const Divider(),
          _title("เดือนนี้"),
          _row("ยอดขายรวม", "฿${monthRevenue.toStringAsFixed(0)}"),
          _row("จำนวนออเดอร์ทั้งหมด", "$totalOrders รายการ"),
        ],
      ),
    );
  }

  Widget buildLast7DaysChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _box(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title("ยอดขาย 7 วันล่าสุด"),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                lineBarsData: [
                  LineChartBarData(
                    spots: last7DaysSpots,
                    isCurved: true,
                    dotData: const FlDotData(show: true),
                    color: const Color(0xFF00ACC1),
                    barWidth: 3,
                  ),
                ],
                borderData: FlBorderData(show: false),
                titlesData: const FlTitlesData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildBestSellers() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _box(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title("สินค้าขายดี (Top 5)"),
          ...bestSellers.map(
            (e) => ListTile(
              title: Text(e["name"]),
              trailing: Text(
                "${e["count"]} ชิ้น",
                style: const TextStyle(
                  color: Colors.teal,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Styles ---
  BoxDecoration _box() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      );

  Widget _title(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF01579B),
        ),
      );

  Widget _row(String left, String right) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(left),
            Text(
              right,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      );
}
