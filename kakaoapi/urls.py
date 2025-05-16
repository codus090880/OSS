from django.urls import path
from .views.views import user_login, user_signup  # 👈 user_signup도 import 필요
from . import views
from kakaoapi.views.token_view import MyTokenObtainPairView

urlpatterns = [
    path('login/', user_login, name='user_login'),
    path('signup/', user_signup, name='user_signup'),
    path('start/one-to-one/', views.start_one_to_one_match), # 👈 이 라인 추가
    path("api/token/", MyTokenObtainPairView.as_view(), name='token_obtain_pair'),
]
