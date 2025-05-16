# kakaoapi/serializers.py
from rest_framework import serializers
from .models import User

# kakaoapi/serializers.py
from rest_framework import serializers
from .models import User

from rest_framework_simplejwt.serializers import TokenObtainPairSerializer

class UserSignupSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['email', 'password']
        extra_kwargs = {'password': {'write_only': True}}

    def create(self, validated_data):
        return User.objects.create_user(**validated_data)  # 여기 쉼표(,) 제거 필요

class MyTokenObtainPairSerializer(TokenObtainPairSerializer):
    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)
        token['email'] = user.email  # 원하는 정보 추가 가능
        token['username'] = user.username
        return token