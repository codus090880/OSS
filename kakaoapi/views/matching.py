from rest_framework.decorators import api_view
from rest_framework.response import Response
from kakaoapi.models import MatchRequest, MatchPreference, UserLocation, User
from geopy.distance import geodesic
from rest_framework.permissions import AllowAny
from rest_framework.decorators import permission_classes

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


@api_view(['POST'])
@permission_classes([AllowAny])  # 인증 없이 접근 허용
def start_one_to_one_match(request):
    # 로그인 안 했을 때는 임시 유저로 지정
    from kakaoapi.models import User  # 순환참조 방지용 내부 import
    user = User.objects.get(id="6")  # 또는 특정 테스트 유저로 지정
    
    from .matching import find_one_to_one_match  # 이거도 여기서 import
    match = find_one_to_one_match(user)

    if match:
        return Response({
            "status": "waiting_for_response",
            "match_id": match.id,
            "to_user": match.to_user.username,
            "distance_km": match.distance_km
        })
    return Response({"status": "no_match_found"})