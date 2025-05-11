from django.urls import path
from .views import user_login, user_signup  # 👈 user_signup도 import 필요

urlpatterns = [
    path('login/', user_login, name='user_login'),
    path('signup/', user_signup, name='user_signup'),  # 👈 이 라인 추가
]