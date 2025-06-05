import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:prunners/widget/top_bar.dart';
import 'package:prunners/widget/outlined_button_box.dart';
import 'package:prunners/widget/bottom_bar.dart';
import 'package:prunners/model/auth_service.dart';

class WriteReviewScreen extends StatefulWidget {
  final int courseId;
  final String courseTitle;

  const WriteReviewScreen({super.key, required this.courseId, required this.courseTitle});

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  @override
  int rating = 0;
  List<XFile> selectedImages = [];
  final TextEditingController reviewController = TextEditingController();
  final ImagePicker picker = ImagePicker(); // 이미지 선택 기능 제공

  Future<void> pickImages() async {
    final List<XFile> picked = await picker.pickMultiImage(); // 갤러리에서 여러 장 선택
    if (picked.isNotEmpty) {
      setState(() {
        selectedImages = picked;
      });
    }
  }

  Future<void> submitReview() async {
    final String content = reviewController.text.trim();

    if(rating == 0 || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('별점과 리뷰 내용을 모두 입력해주세요')),
      );
      return;
    }

    final dio = AuthService.dio;
    try {
      final imageFiles = await Future.wait(
        // 실제 파일 경로를 읽어 multipart 파일 생성(서버 전송 위함)
        selectedImages.map(
              (img) => MultipartFile.fromFile(img.path, filename: img.name),
        ),
      );

      // FormData는 multipart/form-data HTTP 요청에 사용되는 형식
      final formData = FormData.fromMap({
        'course_id': widget.courseId,
        'rating': rating,
        'content': content,
        'images': imageFiles,
      });

      final response = await dio.post(
        '/reviews/',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('리뷰가 등록되었습니다')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('등록 실패: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류 발생: $e')),
      );
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: CustomTopBar(title: '코스 리뷰 작성'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                '오늘 코스 어떠셨나요?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.courseTitle,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Column(
                    children: [
                      const Icon(
                        Icons.camera_alt_outlined,
                        size: 28,
                        color: Colors.black,
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: pickImages,
                        child: const Text(
                          '사진 첨부',
                          style: TextStyle(fontSize: 12, color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (selectedImages.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: selectedImages.map((img) {
                    return Image.file(
                      File(img.path),
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    );
                  }).toList(),
                ),
              const SizedBox(height: 10),
              Row(
                children: List.generate(5, (index) {
                  return IconButton(
                    onPressed: () {
                      setState(() {
                        rating = index + 1;
                      });
                    },
                    icon: Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              Container(
                height: 150,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: TextField(
                  controller: reviewController,
                  maxLines: null, // 줄 수 제한 X
                  expands: true, // TextField 가능한 모든 공간 채움
                  keyboardType: TextInputType.multiline, // 키보드 엔터 -> 다음 줄
                  decoration: InputDecoration(
                    hintText: '경로, 난이도, 경치 등 느낀 점을 자유롭게 적어주세요.',
                    hintStyle: TextStyle(fontSize: 15, color: Colors.grey),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              OutlinedButtonBox(
                text: '등록하기',
                onPressed: submitReview,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: BottomNavBar(
          currentIndex: 2,
          onTap: (index) {
            if (index == 2) return;
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