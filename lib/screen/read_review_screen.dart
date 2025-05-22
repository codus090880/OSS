import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:prunners/screen/course_notify_screen.dart';
import 'package:prunners/widget/top_bar.dart';
import 'package:prunners/widget/bottom_bar.dart';
import 'package:intl/intl.dart';

class Review {
  final String nickname;
  final int rating;
  final String comment;
  final List<String> imgs;
  final DateTime date;

  Review({
    required this.nickname,
    required this.rating,
    required this.comment,
    required this.imgs,
    required this.date,
  });
}

class ReadReviewScreen extends StatefulWidget {
  const ReadReviewScreen({super.key});

  @override
  State<ReadReviewScreen> createState() => _ReadReviewScreenState();
}

class _ReadReviewScreenState extends State<ReadReviewScreen> {
  List<Review> reviews = [];
  String sortType = '최신순';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // reviews = getMockData();
    fetchReviews();
  }

  Future<void> fetchReviews() async {
    final dio = Dio();
    setState(() {
      isLoading = true;
    });
    try {
      final response = await dio.get('http://127.0.0.1:8000/course/1/reviews/');
      if(response.statusCode == 200) {
        final List<dynamic> jsonData = response.data;
        setState(() {
          reviews = jsonData.map((e) => Review(
            nickname: e['nickname'] ?? '알 수 없음',
            rating: e['rating'] ?? 0,
            comment: e['comment'] ?? '',
            imgs: List<String>.from(e['images'] ?? []),
            date: DateTime.parse(e['date']),
          )).toList();
        });
      }
    } catch(e) {
      print('리뷰 불러오기 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('리뷰 불러오기에 실패했어요. 잠시 후 다시 시도해주세요.')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  /*
  List<Review> getMockData() {
    return [
      Review(
        nickname: '홍길동',
        rating: 5,
        comment: '사람도 별로 없고 경치가 이쁘네요 추천합니다',
        imgs: ['img1.png', 'img2.png', 'img3.png'],
        date: DateTime(2025, 5, 7),
      ),
      Review(
        nickname: '김철수',
        rating: 1,
        comment: '별로네요',
        imgs: [],
        date: DateTime(2025, 5, 8),
      ),
    ];
  }
   */

  void sortReviews(String type) {
    setState(() {
      sortType = type;
      if(type == '별점 높은순') {
        reviews.sort((a, b) => b.rating.compareTo(a.rating));
      } else if(type == '별점 낮은순') {
        reviews.sort((a, b) => a.rating.compareTo(b.rating));
      } else {
        reviews.sort((a, b) => b.date.compareTo(a.date));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: CustomTopBar(title: '코스 리뷰'),
      ),
      body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(30, 15, 20, 5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    DropdownButton<String>(
                      value: sortType,
                      items: ['최신순', '별점 높은순', '별점 낮은순'].map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) sortReviews(value);
                      },
                    )
                  ],
                ),
              ),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator()) : reviews.isEmpty
                    ? const Center(
                  child: Text(
                    '아직 등록된 리뷰가 없습니다.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ): ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: reviews.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 30),
                  itemBuilder: (context, index) {
                    final review = reviews[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.account_circle, size: 80, color: Color(0xFFE0E0E0)),
                            const SizedBox(width: 10),
                            Padding(
                              padding: const EdgeInsets.only(left: 5.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    review.nickname,
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                  ),
                                  Row(
                                    children: [
                                      ...List.generate(
                                        review.rating,
                                            (i) => const Icon(Icons.star, color: Colors.amber, size: 20),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        DateFormat('yy.MM.dd').format(review.date),
                                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => CourseNotifyScreen()),
                                );
                              },
                              child: const Text(
                                '신고하기',
                                style: TextStyle(
                                  color: Color(0xFF424242),
                                  decoration: TextDecoration.underline,
                                  decorationColor: Color(0xFF424242),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Padding(
                          padding: const EdgeInsets.only(left: 10.0),
                          child: Text(
                            review.comment,
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.only(left: 10.0),
                          child: Row(
                            children: review.imgs.map((img) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 5),
                                child: Image.network(
                                  img,
                                  width: 70,
                                  height: 70,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          )
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: BottomNavBar(
          currentIndex: 2,
          onTap: (index) {
            Navigator.pushReplacementNamed(
              context,
              ['/home', '/running', '/course', '/profile'][index],
            );
          },
        ),
      ),
    );
  }
}