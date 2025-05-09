from django.db import models
from django.contrib.gis.db import models as gis_models

# 코스 정보
class CourseInfo(gis_models.Model):
    name = models.CharField(max_length=50)
    distance_km = models.FloatField()
    popularity = models.IntegerField(default=0) # 인기도(달린 횟수)

    # GeoDjango 이용한 지리적 데이터
    start_point = gis_models.PointField()
    end_point = gis_models.PointField()
    route = gis_models.LineStringField()

    def __str__(self):
        return f"{self.name} ({self.distance_km}km)"
    
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
