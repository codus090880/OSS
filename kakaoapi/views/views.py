from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from kakaoapi.models import User
from kakaoapi.serializers import UserSignupSerializer
from django.http import JsonResponse
from rest_framework.decorators import api_view, permission_classes,parser_classes
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.response import Response
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework.parsers import MultiPartParser, FormParser,JSONParser
from django.core.files.storage import default_storage
from django.core.cache import cache
from django.utils.crypto import get_random_string
from django.contrib.auth.hashers import make_password
from kakaoapi.models import MatchPreference,MateReport,ChatRoom,UserLocation,RunningFeedback,RunningSession,ChatRoomParticipant
from django.shortcuts import get_object_or_404
from decimal import Decimal
from datetime import date
from django.views.decorators.csrf import csrf_exempt
from kakaoapi.ml.predictor import predict_run_recommendation
from kakaoapi.ml.train_models import load_runhistory_dataframe


@api_view(['POST', 'OPTIONS'])
def user_signup(request): #회원가입입
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

@csrf_exempt
@api_view(['POST', 'OPTIONS'])
def user_login(request): #로그인인
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
    
@api_view(['PUT'])
@permission_classes([IsAuthenticated])
@parser_classes([MultiPartParser, FormParser,JSONParser])
def update_profile(request): #프로필 업데이트트
    user = request.user
    data = request.data

    # 일반 정보
    user.username = data.get('username', user.username)
    user.age = data.get('age', user.age)
    user.height = data.get('height', user.height)
    user.weight = data.get('weight', user.weight)
    user.gender = data.get('gender', user.gender)  # 예: 'male', 'female'
    user.grade_level = data.get('grade_level', user.grade_level)

    # 프로필 사진 (선택적)
    if 'profile_image' in request.FILES:
        user.profile_image = request.FILES['profile_image']

    user.save()
    print(request.FILES)  # 아무것도 안 나오면 Dio에서 안 보낸 거
    print(request.data)   # 여기에 이미지가 있어도 안 됨, FILES여야 저장 가능

    return Response({"message": "프로필이 업데이트되었습니다."})



# --- 비밀번호 재설정용 인증번호 요청/검증/초기화 API ---

@api_view(['POST'])
@permission_classes([AllowAny])
def send_verification_code(request):
    email = request.data.get('email')
    if not email:
        return Response({"success": False, "error": "이메일을 입력해주세요."}, status=400)

    code = get_random_string(6, allowed_chars='0123456789')
    cache.set(f'verify:{email}', code, timeout=300)  # 5분 유효

    # 실제 서비스에서는 이메일 전송 로직 필요
    print(f"[DEBUG] {email} → 인증번호: {code}")

    return Response({"success": True})


@api_view(['POST'])
@permission_classes([AllowAny])
def verify_code(request):
    email = request.data.get('email')
    code = request.data.get('code')
    saved_code = cache.get(f'verify:{email}')

    if saved_code and saved_code == code:
        return Response({"success": True})
    return Response({"success": False})


@api_view(['POST'])
@permission_classes([AllowAny])
def reset_password(request):
    email = request.data.get('email')
    code = request.data.get('code')
    new_password = request.data.get('new_password')
    saved_code = cache.get(f'verify:{email}')

    if saved_code and saved_code == code:
        try:
            user = User.objects.get(email=email)
            user.password = make_password(new_password)
            user.save()
            cache.delete(f'verify:{email}')
            return Response({"success": True})
        except User.DoesNotExist:
            return Response({"success": False, "error": "사용자를 찾을 수 없습니다."})
    return Response({"success": False, "error": "인증번호가 일치하지 않습니다."})


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def change_password(request):
    user = request.user
    data = request.data

    current_password = data.get("current_password")
    new_password = data.get("new_password")

    if not current_password or not new_password:
        return Response({"error": "비밀번호를 모두 입력해주세요."}, status=400)

    if not user.check_password(current_password):
        return Response({"error": "현재 비밀번호가 일치하지 않습니다."}, status=403)

    try:
        user.set_password(new_password)
        user.save()
        return Response({"success": True}, status=200)
    except Exception as e:
        return Response({"error": "서버 오류로 비밀번호 변경에 실패했습니다."}, status=500)
    

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def withdraw_account(request):
    user = request.user
    password = request.data.get("password")

    if not password:
        return Response({"error": "비밀번호가 필요합니다."}, status=400)

    if not user.check_password(password):
        return Response({"error": "비밀번호가 일치하지 않습니다."}, status=400)

    try:
        user.is_active = False
        user.save()
        return Response({"success": True}, status=200)
    except Exception as e:
        return Response({"error": "서버 오류로 탈퇴에 실패했습니다."}, status=500)
    

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def update_location(request):
    user = request.user
    latitude = request.data.get("latitude")
    longitude = request.data.get("longitude")

    if latitude is None or longitude is None:
        return Response({"error": "위도와 경도를 입력해주세요."}, status=400)

    location, created = UserLocation.objects.update_or_create(
        user=user,
        defaults={"latitude": latitude, "longitude": longitude}
    )

    return Response({"status": "updated" if not created else "created"})

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def update_match_preference(request):
    user = request.user
    preferred_distance_range = request.data.get("preferred_distance_range")
    preferred_gender = request.data.get("preferred_gender")
    allow_push = request.data.get("allow_push", True)

    if preferred_distance_range is None or preferred_gender is None:
        return Response({"error": "모든 필드를 입력해주세요."}, status=400)

    pref, created = MatchPreference.objects.update_or_create(
        user=user,
        defaults={
            "preferred_distance_range": preferred_distance_range,
            "preferred_gender": preferred_gender,
            "allow_push": allow_push
        }
    )

    return Response({"status": "updated" if not created else "created"})

def get_evaluable_targets(request_user, session_id):
    session = get_object_or_404(RunningSession, id=session_id, ended=True)
    room = session.chat_room

    # 같은 채팅방에 참가했던 다른 유저들
    participants = ChatRoomParticipant.objects.filter(
        chat_room=room,
        is_approved=True
    ).exclude(user=request_user).values_list('user', flat=True)

    # 이미 평가한 유저들 제외
    already_evaluated = RunningFeedback.objects.filter(
        session=session,
        evaluator=request_user
    ).values_list('target', flat=True)

    return User.objects.filter(id__in=participants).exclude(id__in=already_evaluated)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def submit_feedback(request):
    print("🔥 submit_feedback 호출됨")
    print(f"request.data: {request.data}")

    evaluator = request.user
    target_username = request.data.get("target")
    session_id = request.data.get("session_id")  # ✅ 수정됨
    reasons = request.data.get("reasons", [])
    score = request.data.get("score")

    print(f"evaluator: {evaluator.username}")
    print(f"target_username: {target_username}, session_id: {session_id}, reasons: {reasons}, score: {score}")

    # 필수값 검증
    if not (target_username and session_id and reasons and score in [1, -1]):
        print("❌ 필수값 누락")
        return Response({"error": "필수값 누락"}, status=400)

    target = get_object_or_404(User, username=target_username)
    session = get_object_or_404(RunningSession, id=session_id, ended=True)

    print(f"session found: id={session.id}, chat_room={session.chat_room.id}")

    participants = ChatRoomParticipant.objects.filter(chat_room=session.chat_room).values_list('user', flat=True)
    print(f"참가자 목록: {list(participants)}")

    if evaluator.id not in participants or target.id not in participants:
        print("❌ 참가자가 아님")
        return Response({"error": "해당 세션 참가자가 아닙니다."}, status=403)

    if RunningFeedback.objects.filter(session=session, evaluator=evaluator, target=target).exists():
        print("❌ 이미 평가함")
        return Response({"error": "이미 평가한 유저입니다."}, status=400)

    comment_str = ",".join(reasons)
    feedback = RunningFeedback.objects.create(
        session=session,
        evaluator=evaluator,
        target=target,
        rating=score,
        comment=comment_str
    )
    print("✅ 평가 저장 완료")

    try:
        profile = target
        reason_count = len(reasons)
        delta = Decimal(str(reason_count * 0.1)) if score == 1 else Decimal(str(reason_count * -0.15))

        old_temp = profile.temperature
        profile.temperature += delta
        profile.temperature = max(Decimal("34.0"), min(Decimal("40.0"), profile.temperature))
        profile.save()
        print(f"🔥 매너 온도 변경: {old_temp} → {profile.temperature} (delta={delta})")

    except Exception as e:
        print(f"❌ 매너 온도 업데이트 실패: {e}")
        return Response({"error": f"매너 온도 업데이트 실패: {str(e)}"}, status=500)

    return Response({"success": True})

@api_view(['POST']) 
@permission_classes([IsAuthenticated])
def mate_notify(request):
    reporter_username = request.data.get("reporter")
    target_username = request.data.get("target")
    room_id = request.data.get("room_id")
    content = request.data.get("content")

    if not (reporter_username and target_username and room_id and content):
        return Response({"error": "필수값 누락"}, status=400)

    reporter = get_object_or_404(User, username=reporter_username)
    target = get_object_or_404(User, username=target_username)
    room = get_object_or_404(ChatRoom, id=room_id)

    participants = ChatRoomParticipant.objects.filter(chat_room=room).values_list('user', flat=True)
    if reporter.id not in participants or target.id not in participants:
        return Response({"error": "해당 채팅방 참가자가 아닙니다."}, status=403)

    MateReport.objects.create(
        reporter=reporter,
        target=target,
        room=room,
        content=content
    )

    return Response({"success": True, "message": "신고가 접수되었습니다."})  # ✅ 응답 추가!

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def get_manner_temp(request):
    username = request.data.get("username")
    if not username:
        return Response({"error": "username 필드가 필요합니다."}, status=400)

    username = username.strip()  # 줄바꿈이나 공백 제거

    user = get_object_or_404(User, username=username)

    return Response({
        "username": user.username,
        "manner_temp": float(user.temperature)
    })

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def get_chatroom_user(request):
    room_id = request.data.get("room_id")
    if not room_id:
        return Response({"error": "room_id가 필요합니다."}, status=400)

    chat_room = get_object_or_404(ChatRoom, id=room_id)

    participants = ChatRoomParticipant.objects.filter(
        chat_room=chat_room,
        is_approved=True
    ).select_related("user")

    data = []
    for participant in participants:
        user = participant.user
        data.append({
            "username": user.username,
            "gender": user.gender,
            "temperature": float(user.temperature),
            "grade_level": user.grade_level
        })

    return Response(data)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def end_running_session(request):
    try:
        room_id = request.data.get("room_id")
        if not room_id:
            return Response({"error": "room_id가 필요합니다."}, status=400)

        chat_room = get_object_or_404(ChatRoom, id=room_id)

        # 🔒 이미 종료된 세션 있는지 먼저 확인
        existing_session = RunningSession.objects.filter(chat_room=chat_room).first()
        if existing_session:
            return Response({
                "success": True,
                "session_id": existing_session.id
            })

        # 세션 생성
        session = RunningSession.objects.create(
            chat_room=chat_room,
            date=date.today(),
            total_distance_km=0.0,
            total_duration_min=0,
            ended=True
        )

        return Response({"success": True, "session_id": session.id})

    except Exception as e:
        import traceback
        traceback.print_exc()
        return Response({"error": f"서버 내부 오류: {str(e)}"}, status=500)
    
@api_view(['GET'])  # ✅ HTTP 메서드 지정
@permission_classes([IsAuthenticated])  # 로그인한 사용자만 허용
def ai_feedback_view(request):
    user_id = int(request.GET.get("user_id"))  # ✅ 강제 정수화
    df = load_runhistory_dataframe()
    result = predict_run_recommendation(df, user_id)
    return Response({'feedback': result})