from django.core.management.base import BaseCommand
from django.utils.timezone import now
from datetime import timedelta
from kakaoapi.models import ChatRoom, ChatMessage

class Command(BaseCommand):
    help = '마지막 메시지 이후 1시간 이상 활동 없는 채팅방을 잠금 해제합니다.'

    def handle(self, *args, **options):
        cutoff_time = now() - timedelta(hours=1)

        rooms = ChatRoom.objects.filter(is_locked=True)
        count = 0

        for room in rooms:
            last_msg = ChatMessage.objects.filter(room=room).order_by('-sent_at').first()

            if not last_msg or last_msg.sent_at < cutoff_time:
                room.is_locked = False
                room.save()
                count += 1
                self.stdout.write(self.style.SUCCESS(
                    f"[AUTO-LOCK] Room {room.id} 잠금 해제됨 (마지막 활동: {last_msg.sent_at if last_msg else '없음'})"
                ))

        if count == 0:
            self.stdout.write("⏱ 처리할 방 없음.")
        else:
            self.stdout.write(self.style.SUCCESS(f"✅ 총 {count}개 방 처리 완료"))
