from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django.shortcuts import get_object_or_404
from kakaoapi.models import FriendRequest, User, UserLocation
from geopy.distance import geodesic
from django.db.models import Q

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def send_friend_request(request):
    from_user = request.user
    to_username = request.data.get('to_username')

    if not to_username:
        return Response({"error": "닉네임을 입력해주세요."}, status=400)

    to_user = get_object_or_404(User, username=to_username)

    if from_user == to_user:
        return Response({"error": "자기 자신에게 요청할 수 없습니다."}, status=400)

    friend_request, created = FriendRequest.objects.get_or_create(from_user=from_user, to_user=to_user)

    if not created:
        return Response({"message": "이미 요청을 보냈습니다."})

    return Response({"message": "친구 요청을 보냈습니다."})


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def accept_friend_request(request):
    to_user = request.user
    from_username = request.data.get('from_username')

    if not from_username:
        return Response({"error": "닉네임을 입력해주세요."}, status=400)

    from_user = get_object_or_404(User, username=from_username)
    friend_request = get_object_or_404(FriendRequest, from_user=from_user, to_user=to_user)

    if friend_request.is_accepted:
        return Response({"message": "이미 친구입니다."})

    friend_request.is_accepted = True
    friend_request.save()

    return Response({"message": "친구 요청을 수락했습니다."})


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def reject_friend_request(request):
    to_user = request.user
    from_username = request.data.get('from_username')

    if not from_username:
        return Response({"error": "닉네임을 입력해주세요."}, status=400)

    from_user = get_object_or_404(User, username=from_username)
    friend_request = FriendRequest.objects.filter(from_user=from_user, to_user=to_user, is_accepted=False).first()

    if friend_request:
        friend_request.delete()
        return Response({"message": "친구 요청을 거절했습니다."})
    else:
        return Response({"error": "대기 중인 요청이 없습니다."}, status=404)  

@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def delete_friend(request):
    user = request.user
    other_username = request.data.get('username')

    if not other_username:
        return Response({"error": "닉네임을 입력해주세요."}, status=400)

    other_user = get_object_or_404(User, username=other_username)

    deleted1 = FriendRequest.objects.filter(from_user=user, to_user=other_user, is_accepted=True).delete()
    deleted2 = FriendRequest.objects.filter(from_user=other_user, to_user=user, is_accepted=True).delete()

    if deleted1[0] or deleted2[0]:
        return Response({"message": "친구가 삭제되었습니다."})
    else:
        return Response({"error": "친구 관계가 없습니다."}, status=400)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def list_friends(request):
    user = request.user
    sent = FriendRequest.objects.filter(from_user=user, is_accepted=True)
    received = FriendRequest.objects.filter(to_user=user, is_accepted=True)

    friends = [fr.to_user for fr in sent] + [fr.from_user for fr in received]

    data = [
        {
            "username": friend.username,
            "profile_image": request.build_absolute_uri(friend.profile_image.url) if friend.profile_image else None
        }
        for friend in friends
    ]

    return Response(data)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def list_pending_requests(request):
    user = request.user
    pending_requests = FriendRequest.objects.filter(to_user=user, is_accepted=False)

    data = [
        {
            "username": fr.from_user.username,
            "profile_image": request.build_absolute_uri(fr.from_user.profile_image.url) if fr.from_user.profile_image else None
        }
        for fr in pending_requests
    ]

    return Response(data)


from geopy.distance import geodesic

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def suggest_mates(request):
    user = request.user

    try:
        my_location = UserLocation.objects.get(user=user)
    except UserLocation.DoesNotExist:
        return Response({"error": "위치 정보가 없습니다."}, status=400)

    # 이미 친구 관계 또는 요청한 사람 제외
    friends = FriendRequest.objects.filter(
        Q(from_user=user) | Q(to_user=user),
        is_accepted=True
    ).values_list('from_user', 'to_user')
    flat_friend_ids = set(sum(friends, ()))
    flat_friend_ids.discard(user.id)

    requested_ids = FriendRequest.objects.filter(from_user=user).values_list('to_user', flat=True)

    # 추천 후보 필터링
    candidates = User.objects.exclude(
        id__in=flat_friend_ids.union(requested_ids)
    ).exclude(id=user.id).filter(
        userlocation__isnull=False
    )

    suggestions = []
    for candidate in candidates:
        try:
            candidate_loc = UserLocation.objects.get(user=candidate)
            distance = geodesic(
                (my_location.latitude, my_location.longitude),
                (candidate_loc.latitude, candidate_loc.longitude)
            ).km
        except:
            continue

        if distance <= 10:  # 추천 반경: 10km 이내
            suggestions.append({
                "nickname": candidate.username,
                "imageUrl": request.build_absolute_uri(candidate.profile_image.url) if candidate.profile_image else None,
                "temperature": candidate.temperature,
                "distance_km": round(distance, 2)
            })

    # 온도 높은 순 정렬
    sorted_suggestions = sorted(suggestions, key=lambda x: (-x["temperature"], x["distance_km"]))

    return Response(sorted_suggestions[:10])  # 상위 10명 추천


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def search_mates(request):
    query = request.GET.get('q', '').strip()
    user = request.user

    print(f"[DEBUG] query: '{query}'")

    if not query:
        return Response({"error": "검색어를 입력해주세요."}, status=400)

    users = User.objects.filter(username__icontains=query).exclude(id=user.id)
    print(f"[DEBUG] 검색 결과 수: {users.count()}")

    results = [
        {
            "nickname": u.username,
            "imageUrl": request.build_absolute_uri(u.profile_image.url) if u.profile_image else None,
            "temperature": u.temperature
        }
        for u in users
    ]

    return Response(results)
