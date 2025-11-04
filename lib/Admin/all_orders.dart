import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:wstore/services/database.dart';
import 'package:wstore/widget/support_widget.dart';

class AllOrders extends StatefulWidget {
  const AllOrders({super.key});

  @override
  State<AllOrders> createState() => _AllOrdersState();
}

class _AllOrdersState extends State<AllOrders> {
  Stream? orderStream;

  getontheload() async {
    orderStream = await DatabaseMethods().allOrder();
    setState(() {});
  }

  @override
  void initState() {
    getontheload();
    super.initState();
  }

  Widget allOrder() {
    return StreamBuilder(
      stream: orderStream,
      builder: (context, AsyncSnapshot snapshot) {
        return snapshot.hasData
            ? ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: snapshot.data.docs.length,
                itemBuilder: (context, index) {
                  DocumentSnapshot ds = snapshot.data.docs[index];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    child: Material(
                      elevation: 6,
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.network(
                                  ds["Image"],
                                  height: 120,
                                  width: 120,
                                  fit: BoxFit.cover,
                                ),
                              ),

                              const SizedBox(width: 12),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Name: ${ds["Name"]}",
                                      style: AppWidget.semiBoldTextStyle(),
                                    ),

                                    const SizedBox(height: 4),

                                    Text(
                                      "Email: ${ds["Email"]}",
                                      style: AppWidget.lightTextFieldStyle(),
                                    ),

                                    const SizedBox(height: 4),

                                    Text(
                                      ds["Product"],
                                      style: AppWidget.semiBoldTextStyle(),
                                    ),

                                    const SizedBox(height: 6),

                                    Text(
                                      "\$${ds["Price"]}",
                                      style: const TextStyle(
                                        color: Color(0xFF0096C7),
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                    const SizedBox(height: 16),

                                    GestureDetector(
                                      onTap: () async {
                                        await DatabaseMethods().updateStatus(
                                          ds.id,
                                        );
                                        setState(() {});
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 6,
                                          horizontal: 14,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF00B4D8),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Colors.black12,
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          "Done",
                                          style: AppWidget.semiBoldTextStyle()
                                              .copyWith(color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              )
            : const Center(
                child: CircularProgressIndicator(color: Color(0xFF0096C7)),
              );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ พื้นหลัง Gradient เหมือนหน้าอื่น
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF7AD7F0), Color(0xFF46C5D3)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ✅ AppBar แบบ Custom
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  "All Orders",
                  style: AppWidget.boldTextStyle().copyWith(
                    fontSize: 26,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        offset: Offset(1, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),

              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: allOrder(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
