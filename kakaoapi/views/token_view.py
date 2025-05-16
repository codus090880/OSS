from rest_framework_simplejwt.views import TokenObtainPairView
from kakaoapi.serializers import MyTokenObtainPairSerializer

class MyTokenObtainPairView(TokenObtainPairView):
    serializer_class = MyTokenObtainPairSerializer
