import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

import '../../Backend/Api.dart';
import '../../LocalMemory/Language.dart';
import 'NewsScreen.dart';

class MailingListScreen extends StatefulWidget {
  @override
  _MailingListScreenState createState() => _MailingListScreenState();
}

class _MailingListScreenState extends State<MailingListScreen> {
  late Future<List> _newsFuture;

  @override
  void initState() {
    super.initState();
    _newsFuture = Api.getMailingList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('News')),
      body: FutureBuilder<List>(
        future: _newsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Show shimmer loading
            return ListView.builder(
              itemCount: 10,
              itemBuilder: (context, index) => ShimmerLoadingItem(),
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final news = snapshot.data!;
            return ListView.builder(
              itemCount: news.length,
              itemBuilder: (context, index) {
                final item = news[index];

                String language = Language.getLanguage();
                Map correctLang = {};

                if (language == "en") {
                  correctLang = item['en'];
                } else if (language == "ru") {
                  correctLang = item['ru'];
                } else if (language == "uz") {
                  correctLang = item['uz'];
                }

                // return Text("Hello");
                return ListTile(
                  leading: Container(
                    child: Image.asset('assets/louncher/appstore.png'),
                  ),
                  title: Text(correctLang['title']),
                  subtitle: Text(" "),
                  onTap: () {
                    Get.to(SecondScreen(), arguments: correctLang['body']);
                  },
                );
              },
            );
          } else {
            return Center(child: Text('No data available'));
          }
        },
      ),
    );
  }
}

class ShimmerLoadingItem extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 200,
                  height: 16,
                  color: Colors.grey,
                ),
                SizedBox(height: 8),
                Container(
                  width: 150,
                  height: 12,
                  color: Colors.grey,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
