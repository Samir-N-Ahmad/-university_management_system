import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:university_management_system/common/settings.dart'
    as app_settings;
import 'package:university_management_system/view/widgets/chip_widget.dart';
import 'package:university_management_system/view/widgets/lecture_widget.dart';

class LecturesScreen extends StatefulWidget {
  _LecturesScreenState createState() => _LecturesScreenState();
}

class _LecturesScreenState extends State<LecturesScreen> {
  @override
  Widget build(BuildContext context) {
    return Material(
      child: NestedScrollView(
        reverse: false,
        headerSliverBuilder: (context, innerBoxScrolled) => [
          SliverAppBar(
            floating: true,
            pinned: true,
            backgroundColor: Colors.white,
            leading: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () {
                  Navigator.of(context).pop();
                }),
            centerTitle: true,
            title: Text(
              "Electronic Lectures",
              style: app_settings.TextStyles.TEXT_LARGE_BOLD_DARK,
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.all(5),
              height: 45,
              color: Colors.white,
              child: ListView(
                children: [
                  ChipWidget(
                      onPress: () {},
                      label: "Scholar Year",
                      icon: Icons.add_circle),
                  ChipWidget(
                      onPress: () {}, label: "Year", icon: Icons.add_circle),
                  ChipWidget(
                      onPress: () {},
                      label: "Semester",
                      icon: Icons.add_circle),
                  ChipWidget(
                      onPress: () {}, label: "Subject", icon: Icons.add_circle)
                ],
                scrollDirection: Axis.horizontal,
              ),
            ),
          )
        ],
        body: Container(
          child: GridView.builder(
              padding: EdgeInsets.all(10),
              itemCount: _mainSections.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.of(context).orientation ==
                          Orientation.landscape
                      ? 4
                      : 2,
                  crossAxisSpacing: MediaQuery.of(context).orientation ==
                          Orientation.landscape
                      ? 10
                      : 20,
                  childAspectRatio: 1,
                  mainAxisSpacing: MediaQuery.of(context).orientation ==
                          Orientation.landscape
                      ? 10
                      : 20),
              itemBuilder: (context, index) => _mainSections[index]),
          color: Color(0xFFEEEEEE),
        ),
      ),
    );
  }

  List<Widget> _mainSections = [
    LectureWidget(
      title: "Lecture1",
      onDownload: () {},
      downloading: true,
    ),
    LectureWidget(title: "Lecture2", onDownload: () {}),
    LectureWidget(title: "Lecture3", onDownload: () {}),
    LectureWidget(title: "Lecture3", onDownload: () {}),
    LectureWidget(title: "Lecture3", onDownload: () {}),
    LectureWidget(title: "Lecture3", onDownload: () {}),
    LectureWidget(title: "Lecture3", onDownload: () {}),
  ];
}
