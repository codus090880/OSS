from django.contrib.auth.models import AbstractBaseUser, BaseUserManager, PermissionsMixin
from django.db import models
from .utils import generate_static_map_url, calculate_distance
from django.conf import settings

# 사용자 관리자 클래스
class UserManager(BaseUserManager):
    def create_user(self, email, password=None, **extra_fields):
        if not email:
            raise ValueError('이메일은 필수입니다.')
        email = self.normalize_email(email)
        user = self.model(email=email, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, email, password=None, **extra_fields):
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        return self.create_user(email, password, **extra_fields)

# 사용자 모델
class User(AbstractBaseUser, PermissionsMixin):
    GENDER_CHOICES = [
        ('male', 'Male'),
        ('female', 'Female'),
    ]
    GRADE_CHOICES = [
        ('Starter', 'Starter'),
        ('Beginner', 'Beginner'),
        ('Intermediate', 'Intermediate'),
        ('Advanced', 'Advanced'),
    ]

    email = models.EmailField(unique=True)
    age = models.PositiveIntegerField(null=True, blank=True)
    height = models.FloatField(null=True, blank=True)
    weight = models.FloatField(null=True, blank=True)
    username = models.CharField(max_length=50)
    gender = models.CharField(max_length=10, choices=GENDER_CHOICES)
    grade_level = models.CharField(max_length=20, choices=GRADE_CHOICES)
    location_consent = models.BooleanField(default=False)
    temperature = models.DecimalField(max_digits=4, decimal_places=2, default=36.5)
    profile_image = models.ImageField(upload_to='profiles/', null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)

    objects = UserManager()

    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['username', 'gender', 'grade_level']

    def __str__(self):
        return self.email

class FriendRequest(models.Model):
    from_user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='friend_requests_sent')
    to_user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='friend_requests_received')
    is_accepted = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('from_user', 'to_user')

class FriendChatRoom(models.Model):
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"FriendChatRoom #{self.id}"

class FriendChatParticipant(models.Model):
    chat_room = models.ForeignKey(FriendChatRoom, on_delete=models.CASCADE)
    user = models.ForeignKey(User, on_delete=models.CASCADE)

    class Meta:
        unique_together = ('chat_room', 'user')

class FriendChatMessage(models.Model):
    room = models.ForeignKey(FriendChatRoom, on_delete=models.CASCADE)
    sender = models.ForeignKey(User, on_delete=models.CASCADE)
    message = models.TextField(blank=True)
    image = models.ImageField(upload_to='chat_images/', null=True, blank=True)
    sent_at = models.DateTimeField(auto_now_add=True)

class UserLocation(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    latitude = models.FloatField()
    longitude = models.FloatField()
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.user.username} 위치"

class MatchRequest(models.Model):
    from_user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='sent_requests')
    to_user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='received_requests')
    distance_km = models.FloatField()
    created_at = models.DateTimeField(auto_now_add=True)
    accepted = models.BooleanField(null=True)
    is_finalized = models.BooleanField(default=False)

    def __str__(self):
        return f"{self.from_user} → {self.to_user}"

class MatchPreference(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    preferred_gender = models.CharField(max_length=10, choices=User.GENDER_CHOICES, default='any')
    preferred_distance_range = models.CharField(
        max_length=10,
        choices=[
            ("3-5", "3~5km"),
            ("5-7", "5~7km"),
            ("7-10", "7~10km"),
            ("10+", "10km 이상")
        ],
        default="5-7"
    )
    preferred_time = models.TimeField(null=True, blank=True)
    allow_push = models.BooleanField(default=True)

    def __str__(self):
        return f"{self.user.username}의 매칭 선호"

class MatchQueue(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    latitude = models.FloatField()
    longitude = models.FloatField()
    preferred_gender = models.CharField(max_length=10, choices=User.GENDER_CHOICES, default='any')
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.user.username} 매칭 대기 중"

class ChatRoom(models.Model):
    creator = models.ForeignKey(User, on_delete=models.CASCADE, related_name='created_chatrooms')
    is_locked = models.BooleanField(default=False)
    title = models.CharField(max_length=100, default='러닝 채팅방')
    created_at = models.DateTimeField(auto_now_add=True)
    scheduled_time = models.DateTimeField(null=True, blank=True)
    expected_distance_km = models.FloatField(null=True, blank=True)
    latitude = models.FloatField(null=True, blank=True)
    longitude = models.FloatField(null=True, blank=True)

    def __str__(self):
        return f"ChatRoom #{self.id}"

class ChatRoomParticipant(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    chat_room = models.ForeignKey(ChatRoom, on_delete=models.CASCADE, related_name='participants')
    joined_at = models.DateTimeField(auto_now_add=True)
    is_approved = models.BooleanField(default=False)

    class Meta:
        unique_together = ('user', 'chat_room')

class ChatMessage(models.Model):
    room = models.ForeignKey(ChatRoom, on_delete=models.CASCADE)
    sender = models.ForeignKey(User, on_delete=models.CASCADE)
    message = models.TextField()
    sent_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.sender.username}: {self.message[:20]}"

class ChatJoinRequest(models.Model):
    chat_room = models.ForeignKey(ChatRoom, on_delete=models.CASCADE)
    requester = models.ForeignKey(User, on_delete=models.CASCADE)
    status = models.CharField(max_length=10, choices=[
        ("pending", "대기"),
        ("accepted", "수락"),
        ("rejected", "거절")
    ], default="pending")
    requested_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('chat_room', 'requester')

class Report(models.Model):
    reporter = models.ForeignKey(User, on_delete=models.CASCADE, related_name='reports_made')
    reported_user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='reports_received')
    chat_room = models.ForeignKey(ChatRoom, on_delete=models.SET_NULL, null=True)
    reason = models.TextField()
    reported_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Report: {self.reporter} → {self.reported_user}"

class MateReport(models.Model):
    reporter = models.ForeignKey(User, on_delete=models.CASCADE, related_name='mate_reports_made')
    target = models.ForeignKey(User, on_delete=models.CASCADE, related_name='mate_reports_received')
    room = models.ForeignKey(ChatRoom, on_delete=models.CASCADE)
    content = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.reporter.username} → {self.target.username} 신고"

class RunningSession(models.Model):
    chat_room = models.OneToOneField(ChatRoom, on_delete=models.CASCADE)
    date = models.DateField()
    total_distance_km = models.FloatField()
    total_duration_min = models.IntegerField()
    ended = models.BooleanField(default=False)

    def __str__(self):
        return f"{self.chat_room.id} 러닝 세션"

class RunningFeedback(models.Model):
    session = models.ForeignKey(RunningSession, on_delete=models.CASCADE)
    evaluator = models.ForeignKey(User, on_delete=models.CASCADE, related_name='given_feedbacks')
    target = models.ForeignKey(User, on_delete=models.CASCADE, related_name='received_feedbacks')
    rating = models.IntegerField()
    comment = models.TextField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('session', 'evaluator', 'target')

    def __str__(self):
        return f"{self.evaluator} → {self.target} 평가"

# 코스 정보
class CourseInfo(models.Model):
    name = models.CharField(max_length=50)
    distance_km = models.FloatField(blank=True)
    popularity = models.IntegerField(default=0) # 인기도(달린 횟수)

    latitude = models.FloatField(blank=True,null=True)
    longitude = models.FloatField(blank=True,null=True)
    location = models.CharField(max_length=255, blank=True,null=True)
    polyline_points = models.JSONField(default=list)
    tags = models.JSONField(default=list)
    image_url = models.URLField(blank=True, null=True)

    def __str__(self):
        return f"{self.name} ({self.distance_km}km)"
    
    def add_polyline_point(self, latitude, longitude):
        if not self.polyline_points:
            self.polyline_points = []
        self.polyline_points.append({"lat": latitude, "lng": longitude})
        self.save()
    
    def set_polyline_from_coordinates(self, coordinates_list):
        self.polyline_points = [
            {"lat": coord[0], "lng": coord[1]} for coord in coordinates_list
        ]
        self.save()

    def get_polyline_points(self):
        return self.polyline_points

    def update_popularity(self):
        self.popularity = self.runs.count()
        self.save()

    def save(self, *args, **kwargs):
        if (not self.latitude or not self.longitude) and self.polyline_points:
            first_point = self.polyline_points[0]
            self.latitude = self.latitude or first_point.get("lat")
            self.longitude = self.longitude or first_point.get("lng")
        if self.polyline_points and not self.image_url:
            self.image_url = generate_static_map_url(self.polyline_points, settings.GOOGLE_MAPS_API_KEY)
        if self.polyline_points and (not self.distance_km or self.distance_km == 0):
            total_distance = 0.0
            for i in range(len(self.polyline_points) - 1):
                p1 = self.polyline_points[i]
                p2 = self.polyline_points[i + 1]
                total_distance += calculate_distance(p1['lat'], p1['lng'], p2['lat'], p2['lng'])
            self.distance_km = round(total_distance, 2)
        super().save(*args, **kwargs)

# 코스 리뷰
class CourseReview(models.Model):
    course = models.ForeignKey(CourseInfo, on_delete=models.CASCADE, related_name='reviews')
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='course_reviews')
    
    created_at = models.DateTimeField(auto_now_add=True,null=True)
    rating = models.IntegerField() # 1~5점 사이의 평점
    comment = models.TextField(blank=True)
    course_photo = models.ImageField(upload_to='review_images/', null=True, blank=True)

    class Meta:
        unique_together = ('user', 'course') # 한 사용자가 특정 코스에 대해 하나의 리뷰만 작성
        ordering = ['-created_at'] # 최신순으로 정렬

    def __str__(self):
        return f"{self.user.username}의 {self.course.name} 리뷰 ({self.rating}점)"
    
class RunHistory(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='run_histories')
    course = models.ForeignKey(CourseInfo, on_delete=models.SET_NULL, null=True, blank=True, related_name='runs')
    
    # 기준 필드 (첫 번째 모델 기준)
    distanceKm = models.FloatField(blank=True, null=True)
    elapsedTime = models.CharField(max_length=50, blank=True, null=True)
    calories = models.FloatField(blank=True, null=True)
    averageSpeedKmh = models.FloatField(blank=True, null=True)
    cadenceSpm = models.FloatField(blank=True, null=True)
    route = models.JSONField(default=list, blank=True, null=True)
    dateTime = models.DateTimeField(auto_now_add=True,null=True,blank= True)

    # 추가된 분석/예측 관련 필드 (두 번째 모델에서 가져옴)
    heart_rate = models.IntegerField(null=True, blank=True, help_text="평균 심박수 (bpm)")
    pace = models.FloatField(default=6.0, help_text="분/km")
    gap_days = models.IntegerField(null=True, blank=True, help_text="이전 러닝과의 간격 일 수")
    fatigue_index = models.FloatField(null=True, blank=True, help_text="피로도 추정치")
    is_challenge = models.BooleanField(default=False, help_text="챌린지 참여 여부")
    run_type = models.CharField(
        max_length=20,
        choices=[
            ('LSD', 'LSD'),
            ('Tempo', 'Tempo'),
            ('Interval', 'Interval'),
            ('Recovery', 'Recovery'),
        ],
        null=True,
        blank=True,
        help_text="러닝 유형 (Optional)"
    )
    predicted_distance = models.FloatField(null=True, blank=True)
    predicted_intensity = models.CharField(max_length=10, null=True, blank=True)

    class Meta:
        ordering = ['-dateTime']  # 최신순 정렬

    def __str__(self):
        return f"{self.user.username}의 러닝 ({self.dateTime}, {self.distanceKm}km)"