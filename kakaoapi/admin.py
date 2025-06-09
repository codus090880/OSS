from django.contrib import admin
from .models import MatchRequest,RunHistory, MatchPreference, UserLocation, User , CourseInfo

@admin.register(User)
class UserAdmin(admin.ModelAdmin):
    list_display = ('id', 'email', 'username', 'gender', 'grade_level', 'is_active')
    search_fields = ('email', 'username')

@admin.register(MatchRequest)
class MatchRequestAdmin(admin.ModelAdmin):
    list_display = ('id', 'from_user', 'to_user', 'distance_km', 'accepted', 'is_finalized', 'created_at')
    list_filter = ('accepted', 'is_finalized')
    search_fields = ('from_user__email', 'to_user__email')

@admin.register(MatchPreference)
class MatchPreferenceAdmin(admin.ModelAdmin):
    list_display = ('user', 'preferred_gender', 'preferred_distance_range')  # ✅ 여기!

@admin.register(UserLocation)
class UserLocationAdmin(admin.ModelAdmin):
    list_display = ('user', 'latitude', 'longitude', 'updated_at')

admin.site.register(CourseInfo)
admin.site.register(RunHistory)