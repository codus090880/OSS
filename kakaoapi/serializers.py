# kakaoapi/serializers.py
from rest_framework import serializers
from .models import User, CourseInfo, CourseReview, RunHistory

from rest_framework_simplejwt.serializers import TokenObtainPairSerializer

class UserSignupSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['email', 'password']
        extra_kwargs = {'password': {'write_only': True}}

    def create(self, validated_data):
        return User.objects.create_user(**validated_data)  # 여기 쉼표(,) 제거 필요

class MyTokenObtainPairSerializer(TokenObtainPairSerializer):
    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)
        token['email'] = user.email  # 원하는 정보 추가 가능
        token['username'] = user.username
        return token

class CourseInfoSerializer(serializers.ModelSerializer):
    course_id = serializers.IntegerField(source='id')
    title = serializers.CharField(source='name')
    distance = serializers.SerializerMethodField()
    
    class Meta:
        model = CourseInfo
        fields = [
            'course_id', 'title', 'distance', 'location',
            'image_url', 'tags'
        ]

    def get_distance(self, obj):
        return f"{obj.distance_km} km"

class CourseReviewCreateSerializer(serializers.ModelSerializer):
    nickname = serializers.SerializerMethodField()
    images = serializers.ImageField(
        write_only=True, required=False, source='course_photo'
    )
    course_id = serializers.PrimaryKeyRelatedField(
        queryset=CourseInfo.objects.all(),
        source='course',
        write_only=True
    )
    content = serializers.CharField(source='comment', write_only=True)

    class Meta:
        model = CourseReview
        fields = ['nickname', 'course_id', 'rating', 'content', 'images']
        extra_kwargs = {
            'course': {'write_only': True},  # course_id는 요청에서만 필요
        }

    def get_nickname(self, obj):
        return obj.user.username

    def create(self, validated_data):
        user = self.context['request'].user
        return CourseReview.objects.create(user=user, **validated_data)

class CourseReviewListSerializer(serializers.ModelSerializer):
    nickname = serializers.CharField(source='user.username')
    images = serializers.SerializerMethodField()
    date = serializers.DateTimeField(source='created_at')

    class Meta:
        model = CourseReview
        fields = ['nickname', 'rating', 'comment', 'images', 'date']

    def get_images(self, obj):
        request = self.context.get('request')
        if obj.course_photo and request:
            return [request.build_absolute_uri(obj.course_photo.url)]
        elif obj.course_photo:
            return [obj.course_photo.url]
        return None
    
class RunHistorySerializer(serializers.ModelSerializer):
    class Meta:
        model = RunHistory
        fields = ['distanceKm', 'elapsedTime', 'calories', 'averageSpeedKmh', 'cadenceSpm', 'route', 'dateTime']
