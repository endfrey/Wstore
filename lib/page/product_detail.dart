import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:wstore/services/constant.dart';
import 'package:wstore/services/database.dart';
import 'package:wstore/services/shared_pref.dart';
import 'package:wstore/widget/support_widget.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProductDetail extends StatefulWidget {
  final String image, name, price, detail;
  ProductDetail({
    required this.image,
    required this.name,
    required this.price,
    required this.detail,
  });

  @override
  State<ProductDetail> createState() => _ProductDetailState();
}

class _ProductDetailState extends State<ProductDetail> {

  String? name, mail,image;

  getthesharedpref()async{
    name = await SharedPreferenceHelper().getUserName();
    mail = await SharedPreferenceHelper().getUserEmail();
    image = await SharedPreferenceHelper().getUserImage();
    setState(() {

    });
  }
  ontheload()async{
    await getthesharedpref();
    setState(() {
      
    });
  }

  @override
    void initState() {
    super.initState();
    ontheload();
  }

  Map<String, dynamic>? paymentIntent;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFfef5f1),
      body: Container(
        padding: const EdgeInsets.only(top: 50),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(left: 20.0),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_outlined),
                  ),
                ),
                Center(child: Image.network(widget.image, height: 320)),
              ],
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.only(top: 20, left: 20, right: 20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(20)),
                ),
                width: MediaQuery.of(context).size.width,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(widget.name, style: AppWidget.boldTextStyle()),
                        Text(
                          "\$" + widget.price,
                          style: const TextStyle(
                            color: Color(0xFFfd6f3e),
                            fontSize: 23.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5.0),
                    Text("Details", style: AppWidget.semiBoldTextStyle()),
                    const SizedBox(height: 10.0),
                    Text(
                      widget.detail,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 16.0,
                      ),
                    ),
                    const SizedBox(height: 40.0),
                    GestureDetector(
                      onTap: () async {
                        await makePayment(widget.price);
                      },
                      child: GestureDetector(
                        onTap: () {
                          makePayment(widget.price);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          decoration: BoxDecoration(
                            color: const Color(0xFFfd6f3e),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          width: MediaQuery.of(context).size.width,
                          child: const Center(
                            child: Text(
                              "Buy Now",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> makePayment(String amount) async {
    try {
      paymentIntent = await createPaymentIntent(amount, 'USD');
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntent?['client_secret'],
          style: ThemeMode.dark,
          merchantDisplayName: 'WStore',
        ),
      );

      await displayPaymentSheet();
    } catch (e, s) {
      print('exception: $e $s');
    }
  }

  displayPaymentSheet() async {
    try {
      await Stripe.instance
          .presentPaymentSheet()
          .then((value) async {
            Map<String, dynamic> orderInfoMap = {
              "Product": widget.name,
              "Price": widget.price,
              "Name": name,
              "Email": mail,
              "Image": image,
              "ProductImage": widget.image,
              "Status": "On the way"
            };
            await DatabaseMethods().orderDetails(orderInfoMap);
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 10),
                        Text("Payment Successful"),
                      ],
                    ),
                  ],
                ),
              ),
            );
            paymentIntent = null;
          })
          .onError((error, stackTrace) {
            print('Exception/DISPLAYPAYMENTSHEET==> $error $stackTrace');
          });
    } on StripeException catch (e) {
      print('Exception/DISPLAYPAYMENTSHEET==> $e');
      showDialog(
        context: context,
        builder: (_) => const AlertDialog(content: Text("Cancelled ")),
      );
    } catch (e) {
      print('$e');
    }
  }

  createPaymentIntent(String amount, String currency) async {
    try {
      Map<String, dynamic> body = {
        'amount': calculateAmount(amount),
        'currency': currency,
        'payment_method_types[]': 'card',
      };

      var response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization': 'Bearer $secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
      );
      return jsonDecode(response.body);
    } catch (err) {
      print('err charging user: ${err.toString()}');
    }
  }

  calculateAmount(String amount) {
    final calculatedAmount = (int.parse(amount)) * 100;
    return calculatedAmount.toString();
  }
}
