from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from .models import User
from .serializers import UserSignupSerializer
from django.http import JsonResponse

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
        return Response(status=200)  # ✅ Preflight 대응

    email = request.data.get('email')
    password = request.data.get('password')

    try:
        user = User.objects.get(email=email)
        if user.check_password(password):
            return Response({"message": "로그인 성공!", "user_id": user.id})
        else:
            return Response({"message": "비밀번호가 틀렸습니다"}, status=400)
    except User.DoesNotExist:
        return Response({"message": "이메일이 존재하지 않습니다"}, status=404)
