# Generated by Django 5.2 on 2025-05-23 07:03

import django.db.models.deletion
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('kakaoapi', '0002_courseinfo_runhistory_coursereview'),
    ]

    operations = [
        migrations.CreateModel(
            name='ChatJoinRequest',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('status', models.CharField(choices=[('pending', '대기'), ('accepted', '수락'), ('rejected', '거절')], default='pending', max_length=10)),
                ('requested_at', models.DateTimeField(auto_now_add=True)),
                ('chat_room', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='kakaoapi.chatroom')),
                ('requester', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'unique_together': {('chat_room', 'requester')},
            },
        ),
    ]
