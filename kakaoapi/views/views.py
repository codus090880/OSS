from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from kakaoapi.models import User
from kakaoapi.serializers import UserSignupSerializer
from django.http import JsonResponse
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from kakaoapi.views.matching import find_one_to_one_match
from kakaoapi.views.matching import start_one_to_one_match
from rest_framework_simplejwt.tokens import RefreshToken

from kakaoapi.ml.predictor import predict_run_recommendation
from kakaoapi.ml.train_models import load_runhistory_dataframe


@api_view(['POST', 'OPTIONS'])
def user_signup(request):
    if request.method == 'OPTIONS':
        response = JsonResponse({"detail": "preflight ok"})
        response["Access-Control-Allow-Origin"] = "*"
        response["Access-Control-Allow-Methods"] = "POST, OPTIONS"
        response["Access-Control-Allow-Headers"] = "Content-Type"
        return response # ✅ Preflight 대응

    serializer = UserSignupSerializer(data=request.data)
    if serializer.is_valid():
        serializer.save()
        return Response({"message": "회원가입 성공!"})
    return Response(serializer.errors, status=400)


@api_view(['POST', 'OPTIONS'])
def user_login(request):
    if request.method == 'OPTIONS':
        return Response(status=200)

    email = request.data.get('email')
    password = request.data.get('password')

    try:
        user = User.objects.get(email=email)
        if user.check_password(password):
            # ✅ 토큰 생성
            refresh = RefreshToken.for_user(user)
            return Response({
                "message": "로그인 성공!",
                "user_id": user.id,
                "access": str(refresh.access_token),
                "refresh": str(refresh),
            })
        else:
            return Response({"message": "비밀번호가 틀렸습니다"}, status=400)
    except User.DoesNotExist:
        return Response({"message": "이메일이 존재하지 않습니다"}, status=404)
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def start_one_to_one_match(request):
    match = find_one_to_one_match(request.user)
    if match:
        return Response({
            "status": "waiting_for_response",
            "match_id": match.id,
            "to_user": match.to_user.username,
            "distance_km": match.distance_km,
        })
    return Response({"status": "no_match_found"})

@api_view(['GET'])  # ✅ HTTP 메서드 지정
@permission_classes([IsAuthenticated])  # 로그인한 사용자만 허용
def ai_feedback_view(request):
    user_id = int(request.GET.get("user_id"))  # ✅ 강제 정수화
    df = load_runhistory_dataframe()
    result = predict_run_recommendation(df, user_id)
    return Response({'feedback': result})