# your_app/utils.py
import requests
import math

def calculate_distance(lat1, lon1, lat2, lon2):
    """Haversine formula로 두 좌표 간 거리(km) 계산"""
    R = 6371  # 지구 반지름 (km)
    d_lat = math.radians(lat2 - lat1)
    d_lon = math.radians(lon2 - lon1)
    a = math.sin(d_lat / 2) ** 2 + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(d_lon / 2) ** 2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return R * c

def haversine_distance(p1, p2):
    """Haversine formula로 두 좌표 간 거리(km) 계산"""
    R = 6371
    lat1, lon1 = p1['lat'], p1['lng']
    lat2, lon2 = p2['lat'], p2['lng']
    d_lat = math.radians(lat2 - lat1)
    d_lon = math.radians(lon2 - lon1)
    a = math.sin(d_lat / 2) ** 2 + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(d_lon / 2) ** 2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return R * c

def dtw_distance(route1, route2):
    """DTW 거리 계산"""
    n, m = len(route1), len(route2)
    dtw = [[float('inf')] * (m + 1) for _ in range(n + 1)]
    dtw[0][0] = 0

    for i in range(1, n + 1):
        for j in range(1, m + 1):
            cost = haversine_distance(route1[i - 1], route2[j - 1])
            dtw[i][j] = cost + min(
                dtw[i - 1][j],    # 삽입
                dtw[i][j - 1],    # 삭제
                dtw[i - 1][j - 1] # 일치
            )
    return dtw[n][m]

def is_similar_route(route1, route2, threshold_km=0.5):
    """
    DTW 기반 유사도 판단.
    threshold_km: 경로 전체 거리 차이의 허용 한계
    """
    distance = dtw_distance(route1, route2)
    return distance < threshold_km

def generate_static_map_url(polyline_points, api_key):
    base_url = "https://maps.googleapis.com/maps/api/staticmap"
    size = "600x400"
    path = "color:0xff0000ff|weight:5"

    for point in polyline_points:
        path += f"|{point['lat']},{point['lng']}"

    # center와 zoom을 생략하면 자동으로 경로 전체를 포함한 뷰 생성
    url = f"{base_url}?size={size}&path={path}&key={api_key}"
    return url

