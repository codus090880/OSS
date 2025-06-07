from django.core.management.base import BaseCommand
import pandas as pd
from kakaoapi.models import RunHistory
from django.contrib.auth import get_user_model
from datetime import time

User = get_user_model()


class Command(BaseCommand):
    help = 'CSV 파일에서 RunHistory 모델로 데이터 삽입'

    def add_arguments(self, parser):
        parser.add_argument('csv_path', type=str)

    def handle(self, *args, **options):
        df = pd.read_csv(options['csv_path'])
        inserted = 0

        for _, row in df.iterrows():
            user, _ = User.objects.get_or_create(email=row['user_id'])

            RunHistory.objects.create(
                user=user,
                date=pd.to_datetime(row['date']).date(),
                start_time=pd.to_datetime(row.get('start_time', '06:00:00')).time(),
                distance_km=row['distance_km'],
                duration_min=int(row['duration_min']),
                cadence=int(row.get('cadence', 170)),
                heart_rate=row.get('heart_rate') if not pd.isna(row.get('heart_rate')) else None,
                pace=row.get('pace', 6.0),
                fatigue_index=row.get('fatigue_index') if not pd.isna(row.get('fatigue_index')) else None,
                gap_days=int(row['gap_days']) if not pd.isna(row['gap_days']) else None,
                is_challenge=bool(row.get('is_challenge', False)),
                run_type=row.get('run_type') if not pd.isna(row.get('run_type')) else None,
                predicted_distance=row.get('predicted_distance') if not pd.isna(row.get('predicted_distance')) else None,
                predicted_intensity=row.get('predicted_intensity') if not pd.isna(row.get('predicted_intensity')) else None,
            )
            inserted += 1

        self.stdout.write(self.style.SUCCESS(f"✅ 총 {inserted}개의 RunHistory가 저장되었습니다."))
