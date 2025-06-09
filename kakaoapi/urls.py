from django.urls import path
from .views.views import user_login, user_signup  # 👈 user_signup도 import 필요
from . import views
from kakaoapi.views.token_view import MyTokenObtainPairView
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
from django.conf import settings
from django.conf.urls.static import static

urlpatterns = [
    path('login/', user_login, name='user_login'),
    path('signup/', user_signup, name='user_signup'),
    path("api/token/", MyTokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('match/start/', views.start_bidirectional_match, name='start_bidirectional_match'),
    path('match/cancel/', views.cancel_matching, name='cancel_match'),
    path('match/preference/', views.update_match_preference, name='update_match_preference'),
    path('search_mates/', views.search_mates, name='search_mates'),
    path('suggest_mates/', views.suggest_mates, name='suggest_mates'),
    path('location/update/', views.update_location, name='update_location'),
    path('chat/rooms/<int:room_id>/messages/', get_chat_messages, name='get_messages'),
    path('chatroom/<int:room_id>/messages/send/', send_chat_message, name='send_message'),
    path('chatroom/<int:room_id>/join-request/', request_join_chatroom),
    path('chatroom/<int:room_id>/join-requests/', get_join_requests),
    path('chatroom/join-request/<int:request_id>/accept/', accept_join_request),
    path('rooms/<int:room_id>/title/', views.update_chatroom_title, name='update_room_title'),
    path('rooms/<int:room_id>/visibility/', views.update_room_visibility, name='update_room_visibility'),
    path('rooms/<int:room_id>/leave/', views.leave_chatroom, name='leave_chatroom'),
    path('chatrooms/my/', views.get_my_running_chatrooms, name='my_chatrooms'),
    path('rooms/<int:room_id>/user_list/', views.get_chatroom_users, name='chatroom_user_list'),
    path('chatrooms/public/nearby/', views.get_nearby_chatrooms, name='public_nearby_chatrooms'),
    path('update-profile/', views.update_profile, name='update_profile'),
    path('send_friend_request/', views.send_friend_request, name='send_friend_request'),
    path('accept_friend_request/', views.accept_friend_request, name='accept_friend_request'),
    path('reject_friend_request/', views.reject_friend_request, name='reject_friend_request'),
    path('delete_friend/', views.delete_friend, name='delete_friend'),
    path('list_friends/', views.list_friends, name='list_friends'),
    path('list_pending_requests/', views.list_pending_requests, name='list_pending_requests'),
    path('friend-chat/<str:friend_username>/', views.get_or_create_friend_chatroom, name='get_or_create_friend_chatroom'),
    path('friend-chat/messages/<int:room_id>/', views.get_friend_chat_messages, name='get_friend_chat_messages'),
    path('friend-chat/send_messages/<int:room_id>/', views.send_friend_chat_message, name='send_friend_chat_message'),
    path('send_verification_code/', views.send_verification_code, name='send_verification_code'),
    path('verify_code/', views.verify_code, name='verify_code'),
    path('reset_password/', views.reset_password, name='reset_password'),
    path('change-password/', views.change_password, name='change_password'),
    path('withdrawal/', views.withdraw_account, name='withdraw_account'),
    path("evaluate/", views.submit_feedback, name="submit_feedback"),
    path("mate_notify/", views.mate_notify, name="mate_notify"),
    path("manner_temp/", views.get_manner_temp, name="get_manner_temp"),
    path("chatroom_users/", views.get_chatroom_user, name="get_chatroom_user"),
    path("end_running/", views.end_running_session, name="end_running_session"),

    # 코스 관련
    path('courses/<int:course_id>/', get_course_detail, name='course'),
    path('courses/nearby/', get_nearby_courses, name='nearby_course'),
    path('courses/popular/', get_popular_courses, name='popular_course'),
    path('reviews/', write_review, name='course_review_create'),
    path('course/<int:course_id>/reviews/', read_reviews, name='course_review'),
    path('record/', record, name='history'),
    path('upload_course/', upload_course, name='upload_history'),

    # AI 피드백
    path('api/ai_feedback/', ai_feedback_view, name='ai_feedback'),
] + static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
