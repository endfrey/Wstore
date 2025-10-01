import 'package:flutter/material.dart';

class AppWidget{

  static TextStyle boldTextStyle(){
    return TextStyle(
              color: Colors.black,
              fontSize: 28.0, 
              fontWeight: FontWeight.bold);
  }
  static TextStyle lightTextFieldStyle(){
    return TextStyle(color:Colors.black45,fontSize: 20.0,fontWeight: FontWeight.w500);
  }

  static TextStyle semiBoldTextStyle(){
    return TextStyle(color: Colors.black,fontSize: 20.0,fontWeight: FontWeight.bold);
  }
}