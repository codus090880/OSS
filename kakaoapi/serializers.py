from rest_framework import serializers
from .models import User, CourseInfo, CourseReview, RunHistory
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from .utils import calculate_distance

class UserSignupSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['email', 'password']
        extra_kwargs = {'password': {'write_only': True}}

    def create(self, validated_data):
        return User.objects.create_user(**validated_data)

class MyTokenObtainPairSerializer(TokenObtainPairSerializer):
    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)
        token['email'] = user.email
        token['username'] = user.username
        return token

class CourseInfoSerializer(serializers.ModelSerializer):
    course_id = serializers.IntegerField(source='id')
    title = serializers.CharField(source='name')
    distance = serializers.SerializerMethodField()
    
    class Meta:
        model = CourseInfo
        fields = [
            'course_id', 'title', 'distance',
            'location', 'image_url', 'tags'
        ]

    def get_distance(self, obj):
        user_lat = self.context.get('user_lat')
        user_lon = self.context.get('user_lon')

        if user_lat is None or user_lon is None:
            return None

        return round(calculate_distance(
            user_lat, user_lon,
            obj.latitude, obj.longitude
        ), 2)

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
            'course': {'write_only': True},
        }

    def get_nickname(self, obj):
        return obj.user.username

    def create(self, validated_data):
        user = self.context['request'].user
        return CourseReview.objects.create(user=user, **validated_data)

class CourseReviewListSerializer(serializers.ModelSerializer):
    nickname = serializers.CharField(source='user.username')
    images = serializers.SerializerMethodField()
    date = serializers.DateTimeField(source='created_at', format="%Y-%m-%d")

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
        fields = [
            'distanceKm', 'elapsedTime', 'cadenceSpm', 'heart_rate',
            'dateTime', 'course'
        ]
