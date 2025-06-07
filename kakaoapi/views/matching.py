from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from kakaoapi.models import MatchRequest, MatchPreference, UserLocation, User
from geopy.distance import geodesic
from rest_framework.permissions import AllowAny
from rest_framework.decorators import permission_classes
from kakaoapi.models import MatchRequest, ChatRoom, ChatRoomParticipant
from django.shortcuts import get_object_or_404
from rest_framework.permissions import IsAuthenticated

def is_gender_compatible(preferred, candidate_gender):
    return preferred == 'any' or preferred == candidate_gender

def find_one_to_one_match(user):
    prefs = MatchPreference.objects.get(user=user)
    user_loc = UserLocation.objects.get(user=user)

    for radius in [5, 10, 15]:
        candidates = User.objects.filter(
            is_active=True, location_consent=True
        ).exclude(id=user.id)

        for candidate in candidates:
            try:
                if not is_gender_compatible(prefs.preferred_gender, candidate.gender):
                    continue

                candidate_loc = UserLocation.objects.get(user=candidate)
                distance = geodesic(
                    (user_loc.latitude, user_loc.longitude),
                    (candidate_loc.latitude, candidate_loc.longitude)
                ).km

                if distance > radius:
                    continue

                if MatchRequest.objects.filter(
                    from_user=user, to_user=candidate, is_finalized=False
                ).exists():
                    continue

                return MatchRequest.objects.create(
                    from_user=user,
                    to_user=candidate,
                    distance_km=round(distance, 2)
                )

            except UserLocation.DoesNotExist:
                continue

    return None

from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django.shortcuts import get_object_or_404
from kakaoapi.models import MatchRequest, User
from .matching import find_one_to_one_match  # 매칭 로직 import

@api_view(['POST'])
@permission_classes([IsAuthenticated])  # 로그인된 유저만 접근 가능
def start_one_to_one_match(request):
    user = request.user  # 현재 로그인된 유저

    match = find_one_to_one_match(user)

    if match:
        to_user = match.to_user
        return Response({
            "status": "waiting_for_response",
            "match_id": match.id,
            "distance_km": match.distance_km,
            "matched_user": {
                "email": to_user.email,
                "username": to_user.username,
                "gender": to_user.gender,
                "grade_level": to_user.grade_level,
                "temperature": str(to_user.temperature),
                "profile_image_url": request.build_absolute_uri(to_user.profile_image.url) if to_user.profile_image else None
            }
        })
    return Response({"status": "no_match_found"})


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def respond_to_match(request):
    match_id = request.data.get("match_id")
    response = request.data.get("response")  # "accept" or "reject"

    match = get_object_or_404(MatchRequest, id=match_id, to_user=request.user)

    if match.is_finalized:
        return Response({"message": "이미 처리된 매칭입니다."}, status=400)

    if response == "accept":
        match.accepted = True
        match.is_finalized = True
        match.save()

        # 채팅방 생성
        room = ChatRoom.objects.create(creator=match.from_user)
        ChatRoomParticipant.objects.create(user=match.from_user, chat_room=room, is_approved=True)
        ChatRoomParticipant.objects.create(user=request.user, chat_room=room, is_approved=True)

        return Response({
            "message": "매칭 수락 및 채팅방 생성 완료",
            "chat_room_id": room.id
        })

    elif response == "reject":
        match.accepted = False
        match.is_finalized = True
        match.save()
        return Response({"message": "매칭 거절 처리 완료"})

    else:
        return Response({"message": "response 값은 'accept' 또는 'reject'여야 합니다."}, status=400)