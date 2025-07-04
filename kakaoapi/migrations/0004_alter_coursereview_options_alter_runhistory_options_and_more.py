# Generated by Django 5.2.1 on 2025-06-08 01:49

import django.utils.timezone
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('kakaoapi', '0003_chatjoinrequest'),
    ]

    operations = [
        migrations.AlterModelOptions(
            name='coursereview',
            options={'ordering': ['-created_at']},
        ),
        migrations.AlterModelOptions(
            name='runhistory',
            options={'ordering': ['-dateTime']},
        ),
        migrations.RemoveField(
            model_name='courseinfo',
            name='end_lat',
        ),
        migrations.RemoveField(
            model_name='courseinfo',
            name='end_lon',
        ),
        migrations.RemoveField(
            model_name='courseinfo',
            name='start_lat',
        ),
        migrations.RemoveField(
            model_name='courseinfo',
            name='start_lon',
        ),
        migrations.RemoveField(
            model_name='coursereview',
            name='date',
        ),
        migrations.RemoveField(
            model_name='runhistory',
            name='cadence',
        ),
        migrations.RemoveField(
            model_name='runhistory',
            name='date',
        ),
        migrations.RemoveField(
            model_name='runhistory',
            name='distance_km',
        ),
        migrations.RemoveField(
            model_name='runhistory',
            name='duration_min',
        ),
        migrations.RemoveField(
            model_name='runhistory',
            name='heart_rate',
        ),
        migrations.RemoveField(
            model_name='runhistory',
            name='start_time',
        ),
        migrations.AddField(
            model_name='courseinfo',
            name='image_url',
            field=models.URLField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name='courseinfo',
            name='latitude',
            field=models.FloatField(blank=True, default=0.0),
            preserve_default=False,
        ),
        migrations.AddField(
            model_name='courseinfo',
            name='location',
            field=models.CharField(blank=True, max_length=255),
        ),
        migrations.AddField(
            model_name='courseinfo',
            name='longitude',
            field=models.FloatField(blank=True, default=0.0),
            preserve_default=False,
        ),
        migrations.AddField(
            model_name='courseinfo',
            name='polyline_points',
            field=models.JSONField(default=list),
        ),
        migrations.AddField(
            model_name='courseinfo',
            name='tags',
            field=models.JSONField(default=list),
        ),
        migrations.AddField(
            model_name='coursereview',
            name='created_at',
            field=models.DateTimeField(auto_now_add=True, default=django.utils.timezone.now),
            preserve_default=False,
        ),
        migrations.AddField(
            model_name='runhistory',
            name='averageSpeedKmh',
            field=models.FloatField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name='runhistory',
            name='cadenceSpm',
            field=models.FloatField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name='runhistory',
            name='calories',
            field=models.FloatField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name='runhistory',
            name='dateTime',
            field=models.DateTimeField(auto_now_add=True, default=django.utils.timezone.now),
            preserve_default=False,
        ),
        migrations.AddField(
            model_name='runhistory',
            name='distanceKm',
            field=models.FloatField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name='runhistory',
            name='elapsedTime',
            field=models.CharField(blank=True, max_length=50, null=True),
        ),
        migrations.AddField(
            model_name='runhistory',
            name='route',
            field=models.JSONField(blank=True, default=list, null=True),
        ),
        migrations.AlterField(
            model_name='courseinfo',
            name='distance_km',
            field=models.FloatField(blank=True),
        ),
    ]
