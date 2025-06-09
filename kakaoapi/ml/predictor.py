import joblib
import pandas as pd
from typing import Tuple
import os
from kakaoapi.ml.train_models import compute_fatigue_index
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
MODEL_DIR = os.path.join(BASE_DIR, 'models')


def convert_elapsed_to_min(s):
    if isinstance(s, str):
        parts = s.split(':')
        try:
            if len(parts) == 2:
                return int(parts[0]) + int(parts[1]) // 60
            elif len(parts) == 3:
                return int(parts[0]) * 60 + int(parts[1])
        except:
            pass
    try:
        return int(float(s))
    except:
        return None

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
def adjust_prediction(pred: float, user_email: str, df: pd.DataFrame) -> float:
    user_avg = df[df['user_email'] == user_email]['distanceKm'].tail(5).mean()
    upper = user_avg * 1.2
    lower = user_avg * 0.8
    return min(max(pred, lower), upper)



# def predict_run_recommendation(input_df: pd.DataFrame, user) -> str:
#     user_df = input_df[input_df['user_email'] == user.email].sort_values(by='dateTime')
#     if user_df.empty:
#         return "해당 사용자의 러닝 데이터가 없습니다."
    

#     features = ['distanceKm', 'pace', 'heart_rate', 'elapsedTime', 'fatigue_index', 'gap_days']
#     recent['fatigue_index'] = recent.apply(compute_fatigue_index, axis=1)
#     recent = user_df.tail(5)

#     x_input = recent[features].mean().values.reshape(1, -1)

#     # 모델 로딩
#     reg = joblib.load(os.path.join(MODEL_DIR, 'global_distance_predictor.pkl'))
#     clf = joblib.load(os.path.join(MODEL_DIR, 'global_intensity_classifier.pkl'))

#     raw_pred_distance = reg.predict(x_input)[0]
#     adjusted_distance = adjust_prediction(raw_pred_distance, user, input_df)
#     pred_intensity = clf.predict(x_input)[0]

#     run_type, explanation = recommend_run_type(adjusted_distance, pred_intensity)

#     recent_avg_pace = recent['pace'].mean()
#     recent_avg_distance = recent['distanceKm'].mean()

#     pace_change = recent_avg_pace - recent.iloc[-1]['pace']
#     distance_change = adjusted_distance - recent_avg_distance

#     pace_feedback = "✨ 예전보다 더 빠르게 달렸어요!" if pace_change > 0.2 else "속도는 큰 변화가 없어요."
#     distance_feedback = "💪 거리도 이전보다 길어졌네요!" if distance_change > 0.3 else "거리는 비슷한 수준이에요."

#     result = f"""🏃‍♀️ [AI 러닝 피드백 리포트]

#     👟 다음 러닝 추천 정보:
#     - 📏 예측 거리: {adjusted_distance:.2f} km
#     - 💡 예상 강도: {pred_intensity} 등급
#     - 🧭 추천 유형: {run_type}

#     🧠 AI 코멘트:
#     {explanation}

#     📊 최근 기록과 비교한 분석:
#     - {pace_feedback}
#     - {distance_feedback}

#     🔥 이 피드백은 최근 러닝 데이터를 기반으로 생성되었으며,
#     지속적인 훈련 성과 향상과 회복의 균형을 위해 설계되었습니다.
#     안전하고 꾸준한 러닝을 이어가 보세요!
#     """

#     return result
def predict_run_recommendation(input_df: pd.DataFrame, user) -> str:
    user_df = input_df[input_df['user_email'] == user.email].sort_values(by='dateTime')
    if user_df.empty:
        return "해당 사용자의 러닝 데이터가 없습니다."

    # 최근 5개만 추출
    recent = user_df.tail(5)

    # 피로도 계산
    recent['fatigue_index'] = recent.apply(compute_fatigue_index, axis=1)

    features = ['distanceKm', 'pace', 'heart_rate', 'elapsedTime', 'fatigue_index', 'gap_days']
    x_input = recent[features].mean().values.reshape(1, -1)

    # 모델 로딩
    reg = joblib.load(os.path.join(MODEL_DIR, 'global_distance_predictor.pkl'))
    clf = joblib.load(os.path.join(MODEL_DIR, 'global_intensity_classifier.pkl'))

    raw_pred_distance = reg.predict(x_input)[0]
    adjusted_distance = adjust_prediction(raw_pred_distance, user, input_df)
    pred_intensity = clf.predict(x_input)[0]

    run_type, explanation = recommend_run_type(adjusted_distance, pred_intensity)

    recent_avg_pace = recent['pace'].mean()
    recent_avg_distance = recent['distanceKm'].mean()

    pace_change = recent_avg_pace - recent.iloc[-1]['pace']
    distance_change = adjusted_distance - recent_avg_distance

    pace_feedback = "✨ 예전보다 더 빠르게 달렸어요!" if pace_change > 0.2 else "속도는 큰 변화가 없어요."
    distance_feedback = "💪 거리도 이전보다 길어졌네요!" if distance_change > 0.3 else "거리는 비슷한 수준이에요."

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
