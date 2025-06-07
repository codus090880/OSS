from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from kakaoapi.models import CourseInfo, CourseReview, RunHistory
from kakaoapi.serializers import (
    CourseInfoSerializer, CourseReviewListSerializer, 
    RunHistorySerializer, CourseReviewCreateSerializer,
)
from django.shortcuts import get_object_or_404
from kakaoapi.utils import calculate_distance, is_similar_route

#주변 코스 리스트
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_nearby_courses(request):
    try:
        lat = float(request.query_params.get("lat"))
        lon = float(request.query_params.get("lon"))
    except (TypeError, ValueError):
        return Response({"error": "유효한 위도(lat)와 경도(lon)를 제공해주세요."}, status=400)

    nearby_courses = []
    for course in CourseInfo.objects.all():
        distance = calculate_distance(lat, lon, course.latitude, course.longitude)
        if distance <= 3.0:
            nearby_courses.append(course)

    # 인기도 순 정렬
    nearby_courses.sort(key=lambda c: c.popularity, reverse=True)

    serializer = CourseInfoSerializer(nearby_courses, many=True)
    return Response(serializer.data)

#인기 코스 리스트
@api_view(['GET'])
def get_popular_courses(request):
    courses = CourseInfo.objects.all().order_by('-popularity')  # 인기도순
    serializer = CourseInfoSerializer(courses, many=True)
    return Response(serializer.data)

#코스 세부 정보
@api_view(['GET'])
def get_course_detail(request, course_id):
    course = get_object_or_404(CourseInfo, id=course_id)
    serializer = CourseInfoSerializer(course)
    return Response(serializer.data)

#코스 리뷰 작성
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def write_review(request):
    serializer = CourseReviewCreateSerializer(data=request.data, context={'request': request})
    if serializer.is_valid():
        review = serializer.save()
        return Response({"success": True, "review_id": review.id}, status=201)
    return Response(serializer.errors, status=400)

#코스별 리뷰 리스트
@api_view(['GET'])
def read_reviews(request, course_id):
    course = get_object_or_404(CourseInfo, id=course_id)
    reviews = CourseReview.objects.filter(course=course)
    serializer = CourseReviewListSerializer(reviews, many=True, context={'request': request})
    return Response(serializer.data)

#내 러닝기록들 리스트
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def record(request):
    user = request.user
    run_records = RunHistory.objects.filter(user=user).order_by('-dateTime')
    serializer = RunHistorySerializer(run_records, many=True)
    return Response(serializer.data)

#러닝기록 업로드
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def upload_course(request):
    serializer = RunHistorySerializer(data=request.data)
    if serializer.is_valid():
        runhistory = serializer.save(user=request.user)
        route = runhistory.route  # 경로 정보 (list of {"lat": ..., "lng": ...})

        matched_course = None

        # 모든 코스들과 비교
        for course in CourseInfo.objects.all():
            if is_similar_route(route, course.polyline_points):
                matched_course = course
                break

        # 유사한 코스가 없으면 새 코스를 생성
        if not matched_course:
            distance_km = runhistory.distanceKm
            matched_course = CourseInfo.objects.create(
                name=f"{request.user.username}의 새로운 코스",
                polyline_points=route,
                distance_km=distance_km,
                latitude=route[0]['lat'] if route else 0,
                longitude=route[0]['lng'] if route else 0,
            )

        # RunHistory와 연결
        runhistory.course = matched_course
        runhistory.save()

        matched_course.update_popularity()

        return Response({
            "success": True,
            "run_id": runhistory.id,
            "course_id": matched_course.id,
            "matched": matched_course.name != f"{request.user.username}의 새로운 코스"
        }, status=201)

    return Response(serializer.errors, status=400)
