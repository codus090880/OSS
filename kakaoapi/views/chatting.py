from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django.shortcuts import get_object_or_404
from kakaoapi.models import ChatRoom, UserLocation,ChatRoomParticipant, ChatMessage, ChatJoinRequest
from geopy.distance import geodesic
from django.db.models import Count

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def send_chat_message(request, room_id):
    room = get_object_or_404(ChatRoom, id=room_id)
    if not ChatRoomParticipant.objects.filter(user=request.user, chat_room=room, is_approved=True).exists():
        return Response({"error": "이 채팅방의 참여자가 아닙니다."}, status=403)

    content = request.data.get("message")
    if not content:
        return Response({"error": "메시지를 입력해주세요."}, status=400)

    ChatMessage.objects.create(room=room, sender=request.user, message=content)
    return Response({"message": "메시지 전송 완료"})

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_chat_messages(request, room_id):
    room = get_object_or_404(ChatRoom, id=room_id)
    if not ChatRoomParticipant.objects.filter(user=request.user, chat_room=room, is_approved=True).exists():
        return Response({"error": "이 채팅방의 참여자가 아닙니다."}, status=403)

    messages = ChatMessage.objects.filter(room=room).order_by('sent_at')
    return Response([
        {
            "sender": m.sender.username,
            "message": m.message,
            "sent_at": m.sent_at
        } for m in messages
    ])

# (1) 참가 요청
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def request_join_chatroom(request, room_id):
    room = get_object_or_404(ChatRoom, id=room_id)

    if ChatJoinRequest.objects.filter(chat_room=room, requester=request.user).exists():
        return Response({"message": "이미 참가 요청을 보냈습니다."}, status=400)

    ChatJoinRequest.objects.create(chat_room=room, requester=request.user)
    return Response({"message": "참가 요청 완료"})

# (2) 요청 목록 조회
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_join_requests(request, room_id):
    room = get_object_or_404(ChatRoom, id=room_id)

    if not ChatRoomParticipant.objects.filter(chat_room=room, user=request.user).exists():
        return Response({"error": "권한 없음"}, status=403)

    requests = ChatJoinRequest.objects.filter(chat_room=room, status="pending")
    return Response([
        {
            "request_id": r.id,
            "requester_id": r.requester.id,
            "requester_username": r.requester.username,
            "requested_at": r.requested_at
        } for r in requests
    ])

# (3) 요청 수락
@api_view(['PATCH'])
@permission_classes([IsAuthenticated])
def accept_join_request(request, request_id):
    join_req = get_object_or_404(ChatJoinRequest, id=request_id)
    room = join_req.chat_room

    if not ChatRoomParticipant.objects.filter(chat_room=room, user=request.user).exists():
        return Response({"error": "권한 없음"}, status=403)

    if join_req.status != "pending":
        return Response({"message": "이미 처리된 요청입니다."}, status=400)

    join_req.status = "accepted"
    join_req.save()

    ChatRoomParticipant.objects.create(
        user=join_req.requester,
        chat_room=room,
        is_approved=True
    )

    return Response({"message": f"{join_req.requester.username} 님 참가 수락됨"})
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_my_running_chatrooms(request):
    user = request.user

    # 내가 승인된 채팅방 참가자일 때의 ChatRoom 리스트
    rooms = ChatRoom.objects.filter(
        participants__user=user,
        participants__is_approved=True
    ).distinct()

    result = []
    for room in rooms:
        # 나 외 다른 참가자들 정보 가져오기
        participants = ChatRoomParticipant.objects.filter(
            chat_room=room
        ).exclude(user=user)

        member_list = [
            {
                "username": p.user.username,
                "grade_level": p.user.grade_level,
                "temperature": str(p.user.temperature),
                "profile_image_url": request.build_absolute_uri(p.user.profile_image.url)
                if p.user.profile_image else None
            } for p in participants
        ]

        result.append({
            "room_id": room.id,
            "creator": room.creator.username,
            "scheduled_time": room.scheduled_time,
            "expected_distance_km": room.expected_distance_km,
            "is_locked": room.is_locked,
            "title": room.title,
            "created_at": room.created_at,
            "members": member_list
        })

    return Response(result)

from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django.shortcuts import get_object_or_404
from kakaoapi.models import ChatRoom, ChatRoomParticipant

@api_view(['PUT'])
@permission_classes([IsAuthenticated])
def update_chatroom_title(request, room_id):
    room = get_object_or_404(ChatRoom, id=room_id)

    # 방 참가자만 수정 가능
    if not ChatRoomParticipant.objects.filter(user=request.user, chat_room=room, is_approved=True).exists():
        return Response({"error": "이 채팅방의 참여자가 아닙니다."}, status=403)

    title = request.data.get('title')
    if not title:
        return Response({"error": "제목을 입력해주세요."}, status=400)

    room.title = title
    room.save()

    return Response({"message": "채팅방 제목이 업데이트되었습니다.", "new_title": title})

@api_view(['PUT'])
@permission_classes([IsAuthenticated])
def update_room_visibility(request, room_id):
    room = get_object_or_404(ChatRoom, id=room_id)

    # 방 참가자만 잠금 설정 가능
    if not ChatRoomParticipant.objects.filter(user=request.user, chat_room=room, is_approved=True).exists():
        return Response({"error": "이 채팅방의 참여자가 아닙니다."}, status=403)

    is_public = request.data.get('isPublic')
    if is_public is None:
        return Response({"error": "'isPublic' 값을 보내주세요."}, status=400)

    # isPublic → True: 공개 = 잠금 해제 → is_locked = False
    room.is_locked = not is_public
    room.save()

    return Response({
        "message": "채팅방 잠금 상태가 변경되었습니다.",
        "is_locked": room.is_locked
    })

@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def leave_chatroom(request, room_id):
    room = get_object_or_404(ChatRoom, id=room_id)

    participant = ChatRoomParticipant.objects.filter(user=request.user, chat_room=room).first()
    if not participant:
        return Response({"error": "참여 중인 채팅방이 아닙니다."}, status=403)

    participant.delete()

    # ✅ 자동 삭제 조건: 참여자 수 0명
    if not ChatRoomParticipant.objects.filter(chat_room=room).exists():
        room.delete()
        return Response({"message": "채팅방에서 나갔으며, 채팅방이 삭제되었습니다."}, status=200)

    return Response({"message": "채팅방에서 나갔습니다."}, status=200)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_chatroom_users(request, room_id):
    room = get_object_or_404(ChatRoom, id=room_id)

    if not ChatRoomParticipant.objects.filter(user=request.user, chat_room=room, is_approved=True).exists():
        return Response({"error": "이 채팅방의 참여자가 아닙니다."}, status=403)

    participants = ChatRoomParticipant.objects.filter(chat_room=room, is_approved=True)

    result = [
        {
            "nickname": p.user.username,
            "avatarUrl": request.build_absolute_uri(p.user.profile_image.url) if p.user.profile_image else None
        } for p in participants
    ]

    return Response(result)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_nearby_chatrooms(request):
    user = request.user
    try:
        my_location = UserLocation.objects.get(user=user)
    except UserLocation.DoesNotExist:
        return Response({"error": "사용자 위치 정보가 없습니다."}, status=400)

    # 🔐 is_locked=True → 공개방만 필터링
    public_rooms = ChatRoom.objects.filter(
        is_locked=True
    ).annotate(
        participant_count=Count('participants')
    ).filter(participant_count__gt=0)

    rooms_with_distance = []
    for room in public_rooms:
        if room.latitude is None or room.longitude is None:
            continue

        distance_km = geodesic(
            (my_location.latitude, my_location.longitude),
            (room.latitude, room.longitude)
        ).km

        if distance_km < 10:  # ✅ 이 조건 추가!
            rooms_with_distance.append((room, round(distance_km, 1)))

    # 가까운 순 정렬
    rooms_with_distance.sort(key=lambda x: x[1])

    response_data = []
    for room, dist in rooms_with_distance:
        response_data.append({
            "room_id": room.id,
            "title": room.title,
            "distance_km": dist,
            "expected_distance_km": room.expected_distance_km,
            "created_at": room.created_at,
        })

    return Response(response_data)
