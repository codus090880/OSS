# 친구 전용 1:1 채팅방 모델 및 API 설계 (자동 채팅방 연결)
from rest_framework.decorators import api_view, permission_classes, parser_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.parsers import MultiPartParser, FormParser
from django.shortcuts import get_object_or_404
from django.db import models
from kakaoapi.models import FriendRequest, User , FriendChatRoom,FriendChatMessage,FriendChatParticipant

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_or_create_friend_chatroom(request, friend_username):
    user = request.user

    if not friend_username:
        return Response({"error": "닉네임을 입력해주세요."}, status=400)

    friend = get_object_or_404(User, username=friend_username)

    # 기존 채팅방 찾기
    existing = FriendChatRoom.objects.filter(
        friendchatparticipant__user=user
    ).filter(
        friendchatparticipant__user=friend
    ).distinct().first()

    if existing:
        return Response({"room_id": existing.id})

    # 채팅방 없으면 생성 (친구 확인은 생략: 친구 목록에서 접근 보장됨)
    room = FriendChatRoom.objects.create()
    FriendChatParticipant.objects.create(chat_room=room, user=user)
    FriendChatParticipant.objects.create(chat_room=room, user=friend)

    return Response({"room_id": room.id})


@api_view(['POST'])
@permission_classes([IsAuthenticated])
@parser_classes([MultiPartParser, FormParser])
def send_friend_chat_message(request, room_id):
    user = request.user
    message = request.data.get('message', '')
    image = request.FILES.get('image')

    room = get_object_or_404(FriendChatRoom, id=room_id)

    if not FriendChatParticipant.objects.filter(chat_room=room, user=user).exists():
        return Response({"error": "채팅방에 참여할 수 없습니다."}, status=403)

    chat_message = FriendChatMessage.objects.create(
        room=room,
        sender=user,
        message=message,
        image=image
    )

    return Response({"message": "전송 완료", "message_id": chat_message.id, "image_url": request.build_absolute_uri(chat_message.image.url) if chat_message.image else None})

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_friend_chat_messages(request, room_id):
    user = request.user
    room = get_object_or_404(FriendChatRoom, id=room_id)

    if not FriendChatParticipant.objects.filter(chat_room=room, user=user).exists():
        return Response({"error": "채팅방에 접근할 수 없습니다."}, status=403)

    messages = FriendChatMessage.objects.filter(room=room).order_by('sent_at')
    data = [
        {
            "sender": msg.sender.username,
            "message": msg.message,
            "image_url": request.build_absolute_uri(msg.image.url) if msg.image else None,
            "sent_at": msg.sent_at
        }
        for msg in messages
    ]

    return Response(data)
