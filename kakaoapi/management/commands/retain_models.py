from django.core.management.base import BaseCommand
from kakaoapi.ml import train_models

class Command(BaseCommand):
    help = "AI 피드백 모델을 재학습시킵니다."

    def handle(self, *args, **kwargs):
        self.stdout.write("🚀 모델 재학습 시작...")
        train_models.train_and_predict()
        self.stdout.write(self.style.SUCCESS("✅ 모델 재학습 완료"))