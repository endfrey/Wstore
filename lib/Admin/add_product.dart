import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:random_string/random_string.dart';
import 'package:wstore/services/database.dart';
import 'package:wstore/widget/support_widget.dart';

class AddProduct extends StatefulWidget {
  const AddProduct({super.key});

  @override
  State<AddProduct> createState() => _AddProductState();
}

class _AddProductState extends State<AddProduct> {
  final ImagePicker _picker = ImagePicker();
  File? selectedImage;
  TextEditingController namecontroller = TextEditingController();
  TextEditingController pricecontroller = TextEditingController();
  TextEditingController detailcontroller = TextEditingController();

  Future getImage() async {
    var image = await _picker.pickImage(source: ImageSource.gallery);
    selectedImage = File(image!.path);
    setState(() {});
  }

  String? value;

  final List<String> categoryitem = ['Watch', 'Laptop', 'TV', 'Headphone'];

  uploadItem() async {
    if (selectedImage != null && namecontroller.text != "") {
      String addId = randomAlphaNumeric(10);
      Reference firebaseStorageRef =
          FirebaseStorage.instance.ref().child("blogImage").child(addId);

      final UploadTask task = firebaseStorageRef.putFile(selectedImage!);
      var downloadUrl = await (await task).ref.getDownloadURL();
      String firstletter = namecontroller.text.substring(0, 1).toUpperCase();

      Map<String, dynamic> addProduct = {
        "Name": namecontroller.text,
        "Image": downloadUrl,
        "SearchKey": firstletter,
        "UpdatedName": namecontroller.text.toUpperCase(),
        "Price": pricecontroller.text,
        "Detail": detailcontroller.text,
      };

      await DatabaseMethods().addProduct(addProduct, value!).then((value) async {
        await DatabaseMethods().addAllProducts(addProduct);
      });

      selectedImage = null;
      namecontroller.text = "";

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text("✅ Product Uploaded Successfully", style: TextStyle(fontSize: 18)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ พื้นหลัง Gradient เต็มจอ
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF7AD7F0),
              Color(0xFF46C5D3),
              
            ],
          ),
        ),

        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ AppBar Custom (โปร หน้าสวยขึ้น)
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 26),
                      ),
                      Spacer(),
                      Text(
                        "Add Product",
                        style: AppWidget.boldTextStyle().copyWith(
                          fontSize: 26,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              blurRadius: 4,
                              color: Colors.black26,
                              offset: Offset(1, 2),
                            ),
                          ],
                        ),
                      ),
                      Spacer(),
                    ],
                  ),

                  const SizedBox(height: 35),

                  // ✅ Title
                  Text(
                    "Upload Product Image",
                    style: AppWidget.semiBoldTextStyle()
                        .copyWith(color: Colors.white, fontSize: 18),
                  ),

                  const SizedBox(height: 20),

                  // ✅ Image Upload Box (ตกแต่งใหม่)
                  Center(
                    child: GestureDetector(
                      onTap: getImage,
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 250),
                        curve: Curves.easeOut,

                        height: 160,
                        width: 160,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),

                        child: selectedImage == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.camera_alt_outlined,
                                      size: 50, color: Color(0xFF0096C7)),
                                  SizedBox(height: 8),
                                  Text("Tap to Upload",
                                      style: TextStyle(color: Colors.grey)),
                                ],
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.file(
                                  selectedImage!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  buildLabel("Product Name"),
                  buildTextField(controller: namecontroller),

                  const SizedBox(height: 20),

                  buildLabel("Product Price"),
                  buildTextField(controller: pricecontroller),

                  const SizedBox(height: 20),

                  buildLabel("Product Detail"),
                  buildTextField(
                    controller: detailcontroller,
                    maxLines: 6,
                  ),

                  const SizedBox(height: 20),

                  buildLabel("Product Category"),
                  buildDropdown(),

                  const SizedBox(height: 35),

                  // ✅ ปุ่ม Add Product สวย ๆ
                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0096C7),
                        padding: EdgeInsets.symmetric(horizontal: 45, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 5,
                      ),
                      onPressed: uploadItem,
                      child: Text("Add Product",
                          style: TextStyle(fontSize: 22, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ✅ LABEL STYLE
  Widget buildLabel(String text) {
    return Text(
      text,
      style: AppWidget.semiBoldTextStyle().copyWith(
        color: Colors.white,
        fontSize: 17,
      ),
    );
  }

  // ✅ TEXTFIELD STYLE (ใหม่ สะอาด โปร)
  Widget buildTextField({required TextEditingController controller, int maxLines = 1}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.88),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          border: InputBorder.none,
        ),
      ),
    );
  }

  // ✅ CATEGORY DROPDOWN สวย ๆ
  Widget buildDropdown() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.88),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),

      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          items: categoryitem.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(item, style: AppWidget.semiBoldTextStyle()),
            );
          }).toList(),
          onChanged: (value) => setState(() => this.value = value),
          value: value,
          hint: Text("Select Category"),
          icon: Icon(Icons.arrow_drop_down, color: Color(0xFF0077B6)),
          dropdownColor: Colors.white,
        ),
      ),
    );
  }
}
