import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get_connect/http/src/utils/utils.dart';
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
                    margin: EdgeInsets.only(bottom: 20.0),
                    child: Material(
                      elevation: 3.0,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: EdgeInsets.only(
                          left: 20.0,
                          top: 10.0,
                          bottom: 10.0,
                        ),
                        width: MediaQuery.of(context).size.width,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Image.network(
                              ds["Image"],
                              height: 120,
                              width: 120,
                              fit: BoxFit.cover,
                            ),
                            Spacer(),
                            Padding(
                              padding: const EdgeInsets.only(right: 10.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Name :" + ds["Name"],
                                    style: AppWidget.semiBoldTextStyle(),
                                  ),
                                  SizedBox(height: 3.0),
                                  Container(
                                    width:
                                        MediaQuery.of(context).size.width / 2,
                                    child: Text(
                                      "Email :" + ds["Email"],
                                      style: AppWidget.lightTextFieldStyle(),
                                    ),
                                  ),
                                  SizedBox(height: 3.0),
                                  Text(
                                    ds["Product"],
                                    style: AppWidget.semiBoldTextStyle(),
                                  ),
                                  Text(
                                    "\$" + ds["Price"],
                                    style: const TextStyle(
                                      color: Color(0xFFfd6f3e),
                                      fontSize: 23.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 10.0),
                                   GestureDetector(
                                    onTap: ()async {
                                      await DatabaseMethods().updateStatus(ds.id);
                                      setState(() {
                                        
                                      });

                                    },
                                     child: Container(
                                      padding: EdgeInsets.symmetric(vertical: 5.0),
                                      decoration: BoxDecoration(color: Color(0xFFfd6f3e),borderRadius: BorderRadius.circular(10)),
                                      child: Center(child: Text("Done",style: AppWidget.semiBoldTextStyle(),)),
                                     ),
                                   )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              )
            : Container();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("All Orders", style: AppWidget.boldTextStyle()),
      ),
      body: Container(
        margin: EdgeInsets.only(left: 20.0, right: 20.0),
        child: Column(children: [Expanded(child: allOrder())]),
      ),
    );
  }
}
