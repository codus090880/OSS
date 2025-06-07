from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.request import Request
from kakaoapi.models import MatchRequest, MatchPreference, UserLocation, User
from geopy.distance import geodesic
from rest_framework.permissions import AllowAny
from rest_framework.decorators import permission_classes
from kakaoapi.models import MatchQueue,MatchRequest, ChatRoom, ChatRoomParticipant
from django.shortcuts import get_object_or_404
from rest_framework.permissions import IsAuthenticated
from django.utils.timezone import now
from datetime import timedelta
import requests
def send_push_notification(user, title, message):
    if not hasattr(user, 'fcm_token') or not user.fcm_token:
        return False  # 유저에게 저장된 FCM 토큰이 없으면 패스

    server_key = "YOUR_FCM_SERVER_KEY"  # Firebase 콘솔에서 발급
    url = "https://fcm.googleapis.com/fcm/send"
    
    headers = {
        "Authorization": f"key={server_key}",
        "Content-Type": "application/json"
    }

    data = {
        "to": user.fcm_token,  # 유저가 로그인 시 서버에 저장한 FCM 토큰
        "notification": {
            "title": title,
            "body": message,
            "click_action": "FLUTTER_NOTIFICATION_CLICK"
        },
        "data": {
            "type": "match_invite"
        }
    }

    response = requests.post(url, headers=headers, json=data)
    return response.status_code == 200


def is_gender_compatible(preferred, actual):
    return preferred == 'any' or preferred == actual

from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django.shortcuts import get_object_or_404
from kakaoapi.models import MatchRequest, User
def is_running_distance_compatible(dist1, dist2):
    return dist1 == dist2

def find_bidirectional_match(user):
    print(f"[DEBUG] 매칭 시도 - user: {user.id}, {user.email}")

    try:
        my_pref = MatchPreference.objects.get(user=user)
        my_loc = UserLocation.objects.get(user=user)
        print(f"[DEBUG] 매칭 선호/위치 정보 로드 완료")
    except (MatchPreference.DoesNotExist, UserLocation.DoesNotExist) as e:
        print(f"[ERROR] MatchPreference 또는 UserLocation 없음: {e}")
        return None

    try:
        # 1. 매칭 큐에 사용자 등록 (중복 방지)
        my_queue, created = MatchQueue.objects.get_or_create(
            user=user,
            defaults={
                "latitude": my_loc.latitude,
                "longitude": my_loc.longitude,
                "preferred_gender": my_pref.preferred_gender
            }
        )
        print(f"[DEBUG] MatchQueue 저장 시도 - created: {created}")
    except Exception as e:
        print(f"[ERROR] MatchQueue 저장 중 오류: {e}")
        return None

    if not created:
        print(f"[INFO] 이미 MatchQueue에 등록된 사용자입니다.")
        return None

    # 2. 거리 반경 순회하며 매칭 시도
    candidates = MatchQueue.objects.exclude(user=user)
    print(f"[DEBUG] 후보자 수: {candidates.count()}")

    for radius in [3, 5, 10, 15]:
        print(f"[DEBUG] 반경 {radius}km 매칭 시도 중...")
        for candidate in candidates:
            cand_user = candidate.user

            try:
                cand_pref = MatchPreference.objects.get(user=cand_user)
            except MatchPreference.DoesNotExist:
                continue

            # 성별 조건 체크
            if not is_gender_compatible(my_pref.preferred_gender, cand_user.gender):
                continue
            if not is_gender_compatible(cand_pref.preferred_gender, user.gender):
                continue

            # 러닝 거리 조건 체크
            if not is_running_distance_compatible(my_pref.preferred_distance_range, cand_pref.preferred_distance_range):
                continue

            # 거리 비교
            distance = geodesic(
                (my_queue.latitude, my_queue.longitude),
                (candidate.latitude, candidate.longitude)
            ).km
            if distance > radius:
                continue

            # 매칭 성공
            print(f"[MATCH] 매칭 성공 → {user.email} ↔ {cand_user.email}")
            my_queue.delete()
            candidate.delete()

            title_str = f"{user.username}님과 {cand_user.username}님의 채팅방입니다."
            chat_room = ChatRoom.objects.create(
            creator=user,
            title=title_str,
            latitude=my_loc.latitude,
            longitude=my_loc.longitude
            )
            ChatRoomParticipant.objects.create(user=user, chat_room=chat_room, is_approved=True)
            ChatRoomParticipant.objects.create(user=cand_user, chat_room=chat_room, is_approved=True)

            return cand_user, chat_room.id

    # 3. 푸시 알림 발송 시도
    print("[DEBUG] 매칭 실패 - 푸시 알림 대상자 탐색 중...")
    all_users = User.objects.exclude(id=user.id).filter(is_active=True, location_consent=True)
    for other in all_users:
        try:
            other_pref = MatchPreference.objects.get(user=other)
            other_loc = UserLocation.objects.get(user=other)
        except:
            continue

        if not is_gender_compatible(my_pref.preferred_gender, other.gender):
            continue
        if not is_gender_compatible(other_pref.preferred_gender, user.gender):
            continue
        if not is_running_distance_compatible(my_pref.preferred_distance_range, other_pref.preferred_distance_range):
            continue

        distance = geodesic(
            (my_loc.latitude, my_loc.longitude),
            (other_loc.latitude, other_loc.longitude)
        ).km

        if distance <= 10 and other_pref.allow_push:
            print(f"[PUSH] {other.email}에게 푸시 알림 발송 예정")
            send_push_notification(
                user=other,
                title="러닝 매칭 알림",
                message=f"{user.username}님이 함께 러닝할 파트너를 찾고 있어요!"
            )

    print("[DEBUG] 매칭 실패 - 아무도 조건에 부합하지 않음")
    return None
def cleanup_expired_match_queue():
    expiration_time = now() - timedelta(minutes=10)
    MatchQueue.objects.filter(created_at__lt=expiration_time).delete()

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def start_bidirectional_match(request):
    user = request.user

    # 오래된 큐 제거
    cleanup_expired_match_queue()

    # 매칭 시도
    result = find_bidirectional_match(user)

    if result:
        matched_user, room_id = result
        return Response({
            "status": "matched",
            "chat_room_id": room_id,
            "matched_user": {
                "username": matched_user.username,
                "gender": matched_user.gender,
                "temperature": str(matched_user.temperature),
                "level": matched_user.grade_level,
                "profile_image_url": request.build_absolute_uri(matched_user.profile_image.url) if matched_user.profile_image else None
            }
        })

    return Response({"status": "waiting"})

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def cancel_matching(request: Request):
    user = request.user

    deleted, _ = MatchQueue.objects.filter(user=user).delete()

    if deleted:
        return Response({"message": "매칭 대기열에서 취소되었습니다."}, status=200)
    else:
        return Response({"message": "대기열에 등록된 정보가 없습니다."}, status=400)
