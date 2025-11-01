import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:wstore/page/product_detail.dart';
import 'package:wstore/services/database.dart';
import '../widget/support_widget.dart';

class CategoryProduct extends StatefulWidget {
  String category;
  CategoryProduct({required this.category});

  @override
  State<CategoryProduct> createState() => _CategoryProductState();
}

class _CategoryProductState extends State<CategoryProduct> {
  Stream? CategoryStream;

  getontheload() async {
    CategoryStream = await DatabaseMethods().getProducts(widget.category);
    setState(() {});
  }

  @override
  void initState() {
    getontheload();
    super.initState();
  }

  Widget allProduct() {
    return StreamBuilder(
      stream: CategoryStream,
      builder: (context, AsyncSnapshot snapshot) {
        return snapshot.hasData
            ? GridView.builder(
                padding: EdgeInsets.zero,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.6,
                  mainAxisSpacing: 10.0,
                  crossAxisSpacing: 10.0,
                ),
                itemCount: snapshot.data.docs.length,
                itemBuilder: (context, index) {
                  DocumentSnapshot ds = snapshot.data.docs[index];

                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 20.0,vertical: 10.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        SizedBox(height: 10.0),
                        Image.network(
                          ds["Image"],
                          height: 150,
                          width: 150,
                          fit: BoxFit.cover,
                        ),
                        SizedBox(height: 10.0),
                        Text(ds["Name"], style: AppWidget.semiBoldTextStyle()),
                        Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "\$" + ds["Price"],
                              style: TextStyle(
                                color: Color(0xFFfd6f3e),
                                fontSize: 22.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 30.0),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context)=> ProductDetail(image: ds["Image"], name: ds["Name"], price: ds["Price"], detail: ds["Detail"],)));
                              },
                              child: Container(
                                padding: EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(7.0),
                                  color: Color(0xFFfd6f3e),
                                ),
                                child: Icon(Icons.add, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ],
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
      backgroundColor: Color(0xfff2f2f2),
      appBar: AppBar(backgroundColor: Color(0xfff2f2f2)),
      body: Container(
        margin: EdgeInsets.only(left: 20.0, right: 20.0),
        child: Column(children: [Expanded(child: allProduct())]),
      ),
    );
  }
}
