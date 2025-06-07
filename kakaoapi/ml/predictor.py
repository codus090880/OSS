import joblib
import pandas as pd
from typing import Tuple
import os

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
MODEL_DIR = os.path.join(BASE_DIR, 'models')

# 러닝 유형 추천 함수 (rule-based)
def recommend_run_type(distance: float, intensity: str) -> Tuple[str, str]:
    """
    거리와 강도 예측값을 기반으로 러닝 유형을 추천하고 설명 문구를 함께 반환합니다.
    """
    if intensity == 'Low':
        if distance >= 7:
            return 'LSD', 'LSD(Long Slow Distance): 장거리 천천히 달리는 러닝으로 지구력 향상에 효과적입니다.'
        else:
            return 'Recovery', 'Recovery Run: 가볍고 짧게 회복용으로 달리는 러닝입니다.'
    elif intensity == 'Medium':
        return 'Tempo', 'Tempo Run: 중간 강도로 지속적으로 달리는 러닝으로 심폐 지구력 향상에 좋습니다.'
    elif intensity == 'High':
        if distance <= 5:
            return 'Interval', 'Interval Run: 짧은 구간을 빠르게 여러 번 반복하는 고강도 러닝입니다.'
        else:
            return 'Tempo', 'Tempo Run: 중간 강도로 지속적으로 달리는 러닝으로 심폐 지구력 향상에 좋습니다.'
    return 'Unknown', '알 수 없는 유형입니다.'

# 예측값 보정 함수
def adjust_prediction(pred: float, user_id: int, df: pd.DataFrame) -> float:
    user_avg = df[df['user_id'] == user_id]['distance_km'].tail(5).mean()
    upper = user_avg * 1.2
    lower = user_avg * 0.8
    return min(max(pred, lower), upper)

# 예측 추천 전체 파이프라인
def predict_run_recommendation(input_df: pd.DataFrame, user_id: int) -> str:
    """
    1회 실행용 전체 파이프라인: 거리 예측 → 보정 → 강도 예측 → 유형 추천
    input_df는 RunHistory 데이터프레임 전체 (load_runhistory_dataframe() 출력값)
    """
    # 최신 한 줄 (사용자)
    user_df = input_df[input_df['user_id'] == user_id].sort_values(by='date')
    if user_df.empty:
        return "해당 사용자의 러닝 데이터가 없습니다."

    features = ['distance_km', 'pace', 'heart_rate', 'duration_min', 'fatigue_index', 'gap_days']
    recent_avg = user_df.tail(5)[features].mean()

    
    x_input = recent_avg.values.reshape(1, -1)

    # 모델 로딩
    reg = joblib.load(os.path.join(MODEL_DIR, 'global_distance_predictor.pkl'))
    clf = joblib.load(os.path.join(MODEL_DIR,'global_intensity_classifier.pkl'))

    # 예측
    raw_pred_distance = reg.predict(x_input)[0]
    adjusted_distance = adjust_prediction(raw_pred_distance, user_id, input_df)
    pred_intensity = clf.predict(x_input)[0]

    # 유형 추천
    run_type, explanation = recommend_run_type(adjusted_distance, pred_intensity)

    # 최근 평균과 비교
    recent_runs = user_df.tail(5)
    recent_avg_pace = recent_runs['pace'].mean()
    recent_avg_distance = recent_runs['distance_km'].mean()

    pace_change = recent_avg_pace - recent_avg['pace']  # +면 느려짐, -면 향상
    distance_change = adjusted_distance - recent_avg_distance

    pace_feedback = "✨ 예전보다 더 빠르게 달렸어요!" if pace_change > 0.2 else "속도는 큰 변화가 없어요."
    distance_feedback = "💪 거리도 이전보다 길어졌네요!" if distance_change > 0.3 else "거리는 비슷한 수준이에요."

    # 최종 출력 메시지에 추가
    result = f"""🏃‍♀️ [AI 러닝 피드백 리포트]

    👟 다음 러닝 추천 정보:
    - 📏 예측 거리: {adjusted_distance:.2f} km
    - 💡 예상 강도: {pred_intensity} 등급
    - 🧭 추천 유형: {run_type}

    🧠 AI 코멘트:
    {explanation}

    📊 최근 기록과 비교한 분석:
    - {pace_feedback}
    - {distance_feedback}

    🔥 이 피드백은 최근 러닝 데이터를 기반으로 생성되었으며,
    지속적인 훈련 성과 향상과 회복의 균형을 위해 설계되었습니다.
    안전하고 꾸준한 러닝을 이어가 보세요!
    """

    return result