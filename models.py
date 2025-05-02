from django.db import models

# 사용자 정보
class User(models.Model):
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

    username = models.CharField(max_length=50)
    gender = models.CharField(max_length=10, choices=GENDER_CHOICES)
    grade_level = models.CharField(max_length=20, choices=GRADE_CHOICES)
    location_consent = models.BooleanField(default=False)
    temperature = models.DecimalField(max_digits=4, decimal_places=2, default=36.5)
    profile_image = models.ImageField(upload_to='profiles/', null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.username


# 사용자 위치 정보 (거리 기반 매칭용)
class UserLocation(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    latitude = models.FloatField()
    longitude = models.FloatField()
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.user.username} 위치"


# 1:1 매칭 요청 (수락 시 채팅방 생성)
class MatchRequest(models.Model):
    from_user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='sent_requests')
    to_user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='received_requests')
    distance_km = models.FloatField()
    created_at = models.DateTimeField(auto_now_add=True)
    accepted = models.BooleanField(null=True)  # None=대기, True=수락, False=거절

    def __str__(self):
        return f"{self.from_user} → {self.to_user}"


# 채팅방
class ChatRoom(models.Model):
    creator = models.ForeignKey(User, on_delete=models.CASCADE, related_name='created_chatrooms')
    is_locked = models.BooleanField(default=False)  # 잠금 시 입장 제한
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"ChatRoom #{self.id}"


# 채팅방 참가자
class ChatRoomParticipant(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    chat_room = models.ForeignKey(ChatRoom, on_delete=models.CASCADE)
    joined_at = models.DateTimeField(auto_now_add=True)
    is_approved = models.BooleanField(default=False)  # 초대 요청 수락 여부

    class Meta:
        unique_together = ('user', 'chat_room')  # 중복 참가 방지


# 채팅 메시지
class ChatMessage(models.Model):
    room = models.ForeignKey(ChatRoom, on_delete=models.CASCADE)
    sender = models.ForeignKey(User, on_delete=models.CASCADE)
    message = models.TextField()
    sent_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.sender.username}: {self.message[:20]}"


# 신고 기능
class Report(models.Model):
    reporter = models.ForeignKey(User, on_delete=models.CASCADE, related_name='reports_made')
    reported_user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='reports_received')
    chat_room = models.ForeignKey(ChatRoom, on_delete=models.SET_NULL, null=True)
    reason = models.TextField()
    reported_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Report: {self.reporter} → {self.reported_user}"
