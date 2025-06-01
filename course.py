from django.db import models

# 코스 정보
class CourseInfo(models.Model):
    name = models.CharField(max_length=50)
    distance_km = models.FloatField()
    popularity = models.IntegerField(default=0) # 인기도(달린 횟수)

    latitude = models.FloatField()
    longitude = models.FloatField()
    polyline_points = models.JSONField(default=list)

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

# 코스 리뷰
class CourseReview(models.Model):
    course = models.ForeignKey(CourseInfo, on_delete=models.CASCADE, related_name='reviews')
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='course_reviews')
    
    date = models.DateField()
    rating = models.IntegerField() # 1~5점 사이의 평점
    comment = models.TextField(blank=True)
    course_photo = models.ImageField(upload_to='review_images/', null=True, blank=True)

    class Meta:
        unique_together = ('user', 'course') # 한 사용자가 특정 코스에 대해 하나의 리뷰만 작성
        ordering = ['-date'] # 최신순으로 정렬

    def __str__(self):
        return f"{self.user.username}의 {self.course.name} 리뷰 ({self.rating}점)"
    
# 러닝 기록
class RunHistory(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='run_histories')
    course = models.ForeignKey(CourseInfo, on_delete=models.SET_NULL, null=True, blank=True, related_name='runs')
    date = models.DateField() # 달린 날짜
    start_time = models.TimeField() # 시작 시간
    distance_km = models.FloatField()
    duration_min = models.IntegerField()
    cadence = models.IntegerField()
    heart_rate = models.IntegerField()

    class Meta:
        ordering = ['-date', '-start_time'] # 최신순으로 정렬

    def __str__(self):
        return f"{self.user.username}의 러닝 ({self.date}, {self.distance_km}km)"
    
    def save(self, *args, **kwargs):
        super().save(*args, **kwargs)
        if self.course:
            self.course.update_popularity()  # 코스 인기도 업데이트

# 러닝 트래킹 포인트
class RunTrackPoint(models.Model):
    run_history = models.ForeignKey(RunHistory, on_delete=models.CASCADE, related_name='track_points')
    timestamp = models.DateTimeField()
    latitude = models.FloatField()
    longitude = models.FloatField()
    cadence = models.IntegerField(null=True, blank=True)
    heart_rate = models.IntegerField(null=True, blank=True)
    pace = models.FloatField(null=True, blank=True)

    class Meta:
        ordering = ['timestamp']
        
    def __str__(self):
        return f"Track point at {self.timestamp}"
    
    def to_dict(self):
        """플러터에서 사용할 딕셔너리 형태로 변환"""
        return {
            'timestamp': self.timestamp.isoformat(),
            'latitude': self.latitude,
            'longitude': self.longitude,
            'heart_rate': self.heart_rate,
            'cadence': self.cadence,
            'pace': self.pace
        }

# 사용자 경로를 코스로 변환
class RunToCourseConversion(models.Model):
    run_history = models.OneToOneField(RunHistory, on_delete=models.CASCADE, related_name='course_conversion')
    course = models.ForeignKey(CourseInfo, on_delete=models.CASCADE, related_name='converted_from_runs')
    def __str__(self):
        return f"Conversion: {self.run_history} to {self.course.name}"
