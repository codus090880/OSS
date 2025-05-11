# kakaoapi/serializers.py
from rest_framework import serializers
from .models import User

# kakaoapi/serializers.py
from rest_framework import serializers
from .models import User

class UserSignupSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['email', 'password']
        extra_kwargs = {'password': {'write_only': True}}

    def create(self, validated_data):
        return User.objects.create_user(**validated_data)  # 여기 쉼표(,) 제거 필요
