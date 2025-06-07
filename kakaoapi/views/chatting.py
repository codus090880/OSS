from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django.shortcuts import get_object_or_404
from kakaoapi.models import ChatRoom, ChatRoomParticipant, ChatMessage, ChatJoinRequest

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