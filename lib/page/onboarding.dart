import 'package:flutter/material.dart';

class Onboarding extends StatefulWidget {
  const Onboarding({super.key});

  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: Container(
        margin: EdgeInsets.only(top: 50.0,),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        Image.asset('assets/images/shoe.jpg'),
      Padding(
        padding: const EdgeInsets.all(20.0),
        child: Text(
          "Explore\nThe Best\nProducts:", 
          style: TextStyle(
            color:Colors.black, 
            fontSize: 40.0, 
            fontWeight:FontWeight.bold) )


    ),
    SizedBox(height: 20.0,),
    Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
      Container(
      margin: EdgeInsets.only(right: 20.0),
      padding: EdgeInsets.all(30),
      decoration: BoxDecoration(color: Colors.black,shape: BoxShape.circle),
      child:  Text( 
          "Next",
          style: TextStyle(
            color:const Color.fromARGB(255, 255, 255, 255), 
            fontSize: 20.0, 
            fontWeight:FontWeight.bold) ),
    )
    ]
        )
    ],),),
    );
  }
}
