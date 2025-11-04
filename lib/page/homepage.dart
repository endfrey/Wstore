import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:wstore/page/category_product.dart';
import 'package:wstore/page/product_detail.dart';
import 'package:wstore/services/database.dart';
import 'package:wstore/services/shared_pref.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool searching = false;
  List queryResultSet = [];
  List tempSearchStore = [];
  TextEditingController searchController = TextEditingController();
  String? name, image;

  final List categories = [
    {"img": "assets/images/headphone_icon.png", "name": "Headphone"},
    {"img": "assets/images/laptop.png", "name": "Laptop"},
    {"img": "assets/images/watch.png", "name": "Watch"},
    {"img": "assets/images/TV.png", "name": "TV"},
  ];

  void initiateSearch(String value) async {
    if (value.isEmpty) {
      setState(() {
        searching = false;
        tempSearchStore.clear();
        queryResultSet.clear();
      });
      return;
    }

    setState(() => searching = true);

    var capitalized =
        value.substring(0, 1).toUpperCase() + value.substring(1);
    if (queryResultSet.isEmpty && value.length == 1) {
      var result = await DatabaseMethods().search(capitalized);
      setState(() {
        queryResultSet = result.docs.map((e) => e.data()).toList();
      });
    } else {
      tempSearchStore = queryResultSet
          .where((element) =>
              element['UpdatedName'].startsWith(capitalized))
          .toList();
      setState(() {});
    }
  }

  getUserData() async {
    name = await SharedPreferenceHelper().getUserName();
    image = await SharedPreferenceHelper().getUserImage();
    setState(() {});
  }

  @override
  void initState() {
    getUserData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F9FF),
      body: SafeArea(
        child: (name == null)
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8)))
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Hey, ${name ?? 'User'} ",
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0C4A6E),
                                )),
                            const SizedBox(height: 4),
                            const Text("Let’s find something cool today!",
                                style: TextStyle(
                                    fontSize: 14, color: Colors.black54)),
                          ],
                        ),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: (image != null && image!.isNotEmpty)
                              ? Image.network(image!,
                                  height: 55, width: 55, fit: BoxFit.cover)
                              : Container(
                                  height: 55,
                                  width: 55,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF38BDF8),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: const Icon(Icons.person,
                                      color: Colors.white, size: 30),
                                ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 25),

                    // Search bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.shade100.withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: searchController,
                        onChanged: initiateSearch,
                        decoration: InputDecoration(
                          hintText: "Search product...",
                          hintStyle: const TextStyle(color: Colors.grey),
                          border: InputBorder.none,
                          prefixIcon: const Icon(Icons.search,
                              color: Color(0xFF38BDF8)),
                          suffixIcon: searching
                              ? IconButton(
                                  icon: const Icon(Icons.close,
                                      color: Color(0xFF38BDF8)),
                                  onPressed: () {
                                    searchController.clear();
                                    searching = false;
                                    tempSearchStore.clear();
                                    queryResultSet.clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    // Search results or normal content
                    if (searching)
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: tempSearchStore.length,
                        itemBuilder: (context, index) =>
                            buildResultCard(tempSearchStore[index]),
                      )
                    else ...[
                      sectionHeader("Categories"),
                      const SizedBox(height: 12),
                      buildCategoryList(),
                      const SizedBox(height: 25),
                      sectionHeader("Popular Products"),
                      const SizedBox(height: 12),
                      buildProductList(),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget sectionHeader(String text) => Text(
        text,
        style: const TextStyle(
          color: Color(0xFF0C4A6E),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      );

  Widget buildCategoryList() {
    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => CategoryProduct(category: cat["name"])),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              width: 100,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFBAE6FD), Color(0xFF7DD3FC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                      color: Colors.blue.shade100.withOpacity(0.5),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(cat["img"], height: 50, width: 50),
                  const SizedBox(height: 8),
                  Text(cat["name"],
                      style: const TextStyle(
                          color: Color(0xFF0C4A6E),
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildProductList() {
    final products = [
      ["assets/images/headphone2.png", "Headphone", "1000"],
      ["assets/images/watch2.png", "Smart Watch", "3000"],
      ["assets/images/laptop2.png", "Laptop", "25000"],
    ];

    return SizedBox(
      height: 270,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        itemBuilder: (context, i) {
          return buildProductCard(products[i][0], products[i][1], products[i][2]);
        },
      ),
    );
  }

  Widget buildProductCard(String img, String title, String price) {
    return Container(
      margin: const EdgeInsets.only(right: 18),
      width: 180,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade100.withOpacity(0.5),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(18)),
            child: Image.asset(img,
                height: 130, width: double.infinity, fit: BoxFit.cover),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Color(0xFF0C4A6E))),
                const SizedBox(height: 4),
                Text("฿$price",
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0284C7))),
                const SizedBox(height: 6),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF38BDF8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {},
                  child: const Text("Add to Cart",
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildResultCard(data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade100.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              data['Image'],
              height: 70,
              width: 70,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              data['Name'],
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0C4A6E)),
            ),
          ),
          Icon(Icons.arrow_forward_ios,
              size: 16, color: Colors.blue.shade400),
        ],
      ),
    );
  }
}
