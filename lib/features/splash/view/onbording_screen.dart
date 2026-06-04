// not in use

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:soya_app/features/splash/controller/on_bording_controller.dart';
import 'package:soya_app/routes/app_routes.dart';
import 'package:soya_app/util/colors.dart';
import 'package:soya_app/util/font_family.dart';

class OnBoardingScreen extends StatefulWidget {
  const OnBoardingScreen({super.key});

  @override
  State<OnBoardingScreen> createState() => _OnBoardingScreenState();
}

class _OnBoardingScreenState extends State<OnBoardingScreen> {
  @override
  void initState() {
    super.initState();
    setScreen();
  }

  setScreen() async {
    Timer(
      const Duration(seconds: 0),
      () => Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const BoardingPage()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Ensure ScreenUtil.init(...) is called in your app entry (main) before using .w/.h/.sp
    return Scaffold(
      backgroundColor: lightGreenColor,
      body: Container(
        decoration: BoxDecoration(
          color: whiteColor,
          gradient: GradientColors.btnGradient,
        ),
        padding: EdgeInsets.only(top: 50.h),
        child: Center(
          child: Image.asset(
            "assets/logo.png",
            height: 200.h,
            width: 200.w,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

class BoardingPage extends StatefulWidget {
  const BoardingPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _BoardingScreenState createState() => _BoardingScreenState();
}

class _BoardingScreenState extends State<BoardingPage> {
  // creating all the widget before making our home screeen
  OnBoardingController controller = OnBoardingController();

  @override
  void initState() {
    super.initState();

    _currentPage = 0;

    _slides = [
      Slide(
          controller.onBoardingList[0].image,
          controller.onBoardingList[0].heading,
          controller.onBoardingList[0].subtext),
      Slide(
          controller.onBoardingList[1].image,
          controller.onBoardingList[1].heading,
          controller.onBoardingList[1].subtext),
      Slide(
          controller.onBoardingList[2].image,
          controller.onBoardingList[2].heading,
          controller.onBoardingList[2].subtext),
    ];
    _pageController = PageController(initialPage: _currentPage);
    super.initState();
  }

  int _currentPage = 0;
  List<Slide> _slides = [];
  PageController _pageController = PageController();

  // the list which contain the build slides
  List<Widget> _buildSlides() {
    return _slides.map(_buildSlide).toList();
  }

  Widget _buildSlide(Slide slide) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: whiteColor,
      body: Column(
        children: <Widget>[
          // ignore: sized_box_for_whitespace
          Container(
            height: 0.70.sh, //imagee size
            width: 1.sw,
            alignment: Alignment.center,
            margin: EdgeInsets.only(top: 0.1.sh),
            padding: EdgeInsets.all(10.w),

            // decoration: BoxDecoration(
            //   image: DecorationImage(
            //       image: AssetImage(slide.image), fit: BoxFit.cover),
            // ),
            //child: Image.asset("assets/logo.png", fit: BoxFit.cover),
            child: Image.asset(slide.image, fit: BoxFit.cover),
          ),
        ],
      ),
    );
  }

  // handling the on page changed
  void _handlingOnPageChanged(int page) {
    setState(() => _currentPage = page);
  }

  // building page indicator
  Widget _buildPageIndicator() {
    Row row =
        const Row(mainAxisAlignment: MainAxisAlignment.center, children: []);
    for (int i = 0; i < _slides.length; i++) {
      row.children.add(_buildPageIndicatorItem(i));
      if (i != _slides.length - 1)
        // ignore: curly_braces_in_flow_control_structures
        row.children.add(SizedBox(width: 12.w));
    }
    return row;
  }

  Widget _buildPageIndicatorItem(int index) {
    return Container(
      width: index == _currentPage ? 10.w : 6.w,
      height: index == _currentPage ? 10.w : 6.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: index == _currentPage
            ? GradientColors.primeryColor
            : GradientColors.primeryColor.withOpacity(0.5),
      ),
    );
  }

  sliderText() {
    return Column(
      children: [
        SizedBox(height: 0.05.sh),
        SizedBox(
          width: 0.70.sw,
          child: Text(
            controller.onBoardingList[_currentPage].heading,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20.sp,
              fontFamily: FontFamily.openSans,
              fontWeight: FontWeight.w700,
              color: blackColor,
            ), //heding Text
          ),
        ),
        SizedBox(height: 0.02.sh),
        SizedBox(
          width: 0.70.sw,
          child: Text(
            controller.onBoardingList[_currentPage].subtext,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              color: greyColor,
              fontFamily: FontFamily.openSans,
            ), //subtext
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: GradientColors.primeryColor,
      body: Stack(
        children: <Widget>[
          PageView(
            controller: _pageController,
            onPageChanged: _handlingOnPageChanged,
            physics: const BouncingScrollPhysics(),
            children: _buildSlides(),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 0.35.sh,
              width: 1.sw,
              margin: EdgeInsets.all(10.w),
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              decoration: BoxDecoration(
                color: whiteColor,
                borderRadius: BorderRadius.circular(25.r),
              ),
              child: Column(
                children: <Widget>[
                  //slider text content
                  sliderText(),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, AppRoutes.login);
                          // StorageService.save("isBack", true);
                          // Get.toNamed(Routes.loginScreen);
                          // save("isBack", true);
                        },
                        child: Text(
                          "Skip",
                          style: TextStyle(
                            fontFamily: FontFamily.openSans,
                            fontSize: 17.sp,
                            color: primeryColor.withOpacity(0.5),
                          ),
                        ),
                      ),
                      //indicator set screen
                      _buildPageIndicator(),
                      TextButton(
                        onPressed: () {
                          _currentPage == controller.onBoardingList.length - 1
                              ? Navigator.pushNamed(context, AppRoutes.login)
                              : _pageController.nextPage(
                                  duration: const Duration(milliseconds: 500),
                                  curve: Curves.easeIn,
                                );
                        },
                        child: Text(
                          "Next",
                          style: TextStyle(
                            fontFamily: FontFamily.openSans,
                            fontSize: 17.sp,
                            color: primeryColor,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 30.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Slide {
  String image;
  String heading;
  String subtext;

  Slide(this.image, this.heading, this.subtext);
}
