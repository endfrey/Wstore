import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:wstore/page/category_product.dart';
import 'package:wstore/page/product_detail.dart';
import 'package:wstore/services/database.dart';
import 'package:wstore/services/shared_pref.dart';
import 'package:wstore/widget/support_widget.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool search = false;
  List categories = [
    "assets/images/headphone_icon.png",
    "assets/images/laptop.png",
    "assets/images/watch.png",
    "assets/images/TV.png",
  ];

  List Categoryname = ["Headphone", "Laptop", "Watch", "TV"];

  var queryResultSet = [];
  var tempSearchStore = [];
  TextEditingController searchController = new TextEditingController();

  initiateSearch(value) {
    if (value.length == 0) {
      setState(() {
        queryResultSet = [];
        tempSearchStore = [];
      });
    }
    setState(() {
      search = true;
    });

    var capitalizedValue =
        value.substring(0, 1).toUpperCase() + value.substring(1);
    if (queryResultSet.isEmpty && value.length == 1) {
      DatabaseMethods().search(value).then((QuerySnapshot docs) {
        for (int i = 0; i < docs.docs.length; ++i) {
          queryResultSet.add(docs.docs[i].data());
        }
      });
    } else {
      tempSearchStore = [];
      queryResultSet.forEach((element) {
        if (element['UpdatedName'].startsWith(capitalizedValue)) {
          setState(() {
            tempSearchStore.add(element);
          });
        }
      });
    }
  }

  String? name, image;

  getthesharedpref() async {
    name = await SharedPreferenceHelper().getUserName();
    image = await SharedPreferenceHelper().getUserImage();

    // Debug log
    print("DEBUG name = $name");
    print("DEBUG image = $image");

    setState(() {});
  }

  ontheload() async {
    await getthesharedpref();
  }

  @override
  void initState() {
    ontheload();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xfff2f2f2),
      body: (name == null || name!.isEmpty)
          ? Center(child: CircularProgressIndicator())
          : Container(
              margin: EdgeInsets.only(top: 50.0, left: 20.0, right: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Hey ${name ?? 'User'}",
                            style: AppWidget.boldTextStyle(),
                          ),
                          Text(
                            "Good Morning",
                            style: AppWidget.lightTextFieldStyle(),
                          ),
                        ],
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20.0),
                        child: (image != null && image!.isNotEmpty)
                            ? Image.network(
                                image!,
                                height: 70,
                                width: 70,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                height: 70,
                                width: 70,
                                color: Colors.grey[300],
                                child: Icon(Icons.person, size: 40),
                              ),
                      ),
                    ],
                  ),
                  SizedBox(height: 30.0),

                  // Search box
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    width: MediaQuery.of(context).size.width,
                    child: TextField(
                      controller: searchController,
                      onChanged: (value) {
                        initiateSearch(value.toLowerCase());
                      },
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: "search Products",
                        hintStyle: AppWidget.lightTextFieldStyle(),
                        prefixIcon: search? GestureDetector(
                          onTap: () {
                            search = false;
                            tempSearchStore = [];
                            queryResultSet = [];
                            searchController.text="";
                            setState(() {
                              
                            });
                          },
                          child: Icon(Icons.close)): Icon(Icons.search, color: Colors.black),
                      ),
                    ),
                  ),
                  SizedBox(height: 20.0),

                  // Categories header
                 search? ListView(
                  padding: EdgeInsets.only(left: 10.0, right: 10.0),
                  primary: false,
                  shrinkWrap: true,
                  children: tempSearchStore.map((element) {
                    return buildResultCard(element);
                  }).toList(),
                 ): Column(
                   children: [
                     Padding(
                        padding: const EdgeInsets.only(right: 20.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Categories", style: AppWidget.semiBoldTextStyle()),
                            Text(
                              " See All",
                              style: TextStyle(
                                color: Color(0xFFfd6f3e),
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                   
                  SizedBox(height: 20.0),

                  // Categories list
                  Row(
                    children: [
                      Container(
                        height: 130,
                        padding: EdgeInsets.all(20.0),
                        margin: EdgeInsets.only(right: 20.0),
                        decoration: BoxDecoration(
                          color: Color(0xFFfd6f3e),
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: Center(
                          child: Text(
                            "All",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: SizedBox(
                          height: 130,
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: categories.length,
                            shrinkWrap: true,
                            scrollDirection: Axis.horizontal,
                            itemBuilder: (context, index) {
                              return CategoryTile(
                                image: categories[index],
                                name: Categoryname[index],
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.0),

                  // All Products header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "All Products",
                        style: AppWidget.semiBoldTextStyle(),
                      ),
                      Text(
                        " See All",
                        style: TextStyle(
                          color: Color(0xFFfd6f3e),
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.0),

                  // All Products list
                  SizedBox(
                    height: 240,
                    child: ListView(
                      shrinkWrap: true,
                      scrollDirection: Axis.horizontal,
                      children: [
                        productCard(
                          "assets/images/headphone2.png",
                          "Headphone",
                          "\$100",
                        ),
                        productCard(
                          "assets/images/watch2.png",
                          "Apple Watch",
                          "\$300",
                        ),
                        productCard(
                          "assets/images/laptop2.png",
                          "Laptop",
                          "\$1000",
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              ],
                 ),
            ),
    );
  }
  Widget buildResultCard(data){
    return GestureDetector(
      onTap: (){
        Navigator.push(context, MaterialPageRoute(builder: (context)=>ProductDetail(image: data["Image"], name: data["Name"], price: data["Price"], detail: data["Detail"],)));
      },
      child: Container(
        padding: EdgeInsets.only(left: 20.0),
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.0),
          
        ),
        height: 100,
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10.0),
            child: Image.network(data['Image'],height: 70,width: 70,fit: BoxFit.cover,)),
          SizedBox(width: 20.0),
          Text( data['Name'],style: AppWidget.semiBoldTextStyle(),)
        ],),
      ),
    );
  }

  Widget productCard(String img, String title, String price) {
    return Container(
      margin: EdgeInsets.only(right: 20.0),
      padding: EdgeInsets.symmetric(horizontal: 20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Image.asset(img, height: 150, width: 150, fit: BoxFit.cover),
          Text(title, style: AppWidget.semiBoldTextStyle()),
          SizedBox(height: 10.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                price,
                style: TextStyle(
                  color: Color(0xFFfd6f3e),
                  fontSize: 22.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 40.0),
              Container(
                padding: EdgeInsets.all(5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(7.0),
                  color: Color(0xFFfd6f3e),
                ),
                child: Icon(Icons.add, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CategoryTile extends StatelessWidget {
  String image, name;
  CategoryTile({super.key, required this.image, required this.name});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryProduct(category: name),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(20.0),
        margin: EdgeInsets.only(right: 20.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.0),
        ),
        height: 90,
        width: 90,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Image.asset(image, height: 50, width: 50, fit: BoxFit.cover),
            Icon(Icons.arrow_forward),
          ],
        ),
      ),
    );
  }
}
