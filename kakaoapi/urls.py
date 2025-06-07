from django.urls import path
from .views.views import user_login, user_signup  # 👈 user_signup도 import 필요
from . import views
from kakaoapi.views.token_view import MyTokenObtainPairView
from kakaoapi.views.matching import respond_to_match
from kakaoapi.views.chatting import send_chat_message, get_chat_messages
from kakaoapi.views.chatting import (
    request_join_chatroom,
    get_join_requests,
    accept_join_request,
)
from kakaoapi.views.views import ai_feedback_view
from .views.course_view import (
    get_course_detail, write_review, read_reviews,
    record, upload_course, get_nearby_courses, get_popular_courses,
)

urlpatterns = [
    path('login/', user_login, name='user_login'),
    path('signup/', user_signup, name='user_signup'),
    path('start/one-to-one/', views.start_one_to_one_match), # 👈 이 라인 추가
    path("api/token/", MyTokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('match/response/', respond_to_match), 
    path('chatroom/<int:room_id>/messages/', get_chat_messages, name='get_messages'),
    path('chatroom/<int:room_id>/messages/send/', send_chat_message, name='send_message'),
    path('chatroom/<int:room_id>/join-request/', request_join_chatroom),
    path('chatroom/<int:room_id>/join-requests/', get_join_requests),
    path('chatroom/join-request/<int:request_id>/accept/', accept_join_request),
    path('api/ai_feedback/', ai_feedback_view, name='ai_feedback'),
    path('courses/<int:course_id>/', get_course_detail, name='course'),
    path('courses/nearby/', get_nearby_courses, name='nearby_course'),
    path('courses/popular/', get_popular_courses, name='popular_course'),
    path('reviews/', write_review, name='course_review_create'),
    path('course/<int:course_id>/reviews/', read_reviews, name='course_review'),
    path('record/', record, name='history'),
    path('upload_course/', upload_course, name='upload_history'),
]
