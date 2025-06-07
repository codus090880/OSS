import pandas as pd
import joblib
from sklearn.ensemble import RandomForestRegressor, RandomForestClassifier
from sklearn.model_selection import train_test_split, GroupShuffleSplit
from sklearn.metrics import mean_absolute_error, accuracy_score
from kakaoapi.models import RunHistory
import os



BASE_DIR = os.path.dirname(os.path.abspath(__file__))
MODEL_DIR = os.path.join(BASE_DIR, 'models')


def load_runhistory_dataframe():
    queryset = RunHistory.objects.all().select_related('user')
    df = pd.DataFrame(list(queryset.values(
        'user__id', 'date', 'distance_km', 'pace', 'heart_rate', 'duration_min',
        'gap_days', 'fatigue_index', 'run_type',
        'predicted_distance', 'predicted_intensity'
    )))
    df.rename(columns={"user__id": "user_id"}, inplace=True)
    df['user_avg_distance'] = df.groupby('user_id')['distance_km'].transform('mean')
    df['pace_trend'] = df.groupby('user_id')['pace'].transform(lambda x: x.rolling(5, min_periods=1).mean())
    return df



def classify_intensity(row):
    score = 0

    # 속도 점수 (빠를수록 강도 높음)
    if row['pace'] <= 5.0:
        score += 2
    elif 5.0 < row['pace'] <= 6.2:
        score += 1

    # 심박수 점수
    if row['heart_rate'] >= 160:
        score += 2
    elif 145 <= row['heart_rate'] < 160:
        score += 1

    # 거리 점수
    if row['distance_km'] >= 9:
        score += 2
    elif 6 <= row['distance_km'] < 9:
        score += 1

    # 총점 기반 분류
    if score >= 5:
        return 'High'
    elif score >= 3:
        return 'Medium'
    else:
        return 'Low'






def train_and_predict():
    df = load_runhistory_dataframe()

    # 라벨 생성
    df['next_distance'] = df.groupby('user_id')['distance_km'].shift(-1)
    df['intensity_label'] = df.apply(classify_intensity, axis=1)
    df.dropna(subset=['next_distance', 'intensity_label'], inplace=True)

    features = ['distance_km', 'pace', 'heart_rate', 'duration_min', 'fatigue_index', 'gap_days']
    X = df[features]
    y_distance = df['next_distance']
    y_intensity = df['intensity_label']
    groups = df['user_id']

    # ✅ 사용자 기반 분할
    gss = GroupShuffleSplit(n_splits=1, test_size=0.2, random_state=42)
    train_idx, test_idx = next(gss.split(X, y_distance, groups=groups))

    X_train_d, X_test_d = X.iloc[train_idx], X.iloc[test_idx]
    y_train_d, y_test_d = y_distance.iloc[train_idx], y_distance.iloc[test_idx]

    X_train_c, X_test_c = X.iloc[train_idx], X.iloc[test_idx]
    y_train_c, y_test_c = y_intensity.iloc[train_idx], y_intensity.iloc[test_idx]

    # 거리 예측 모델 학습
    reg_model = RandomForestRegressor(n_estimators=100, max_depth=5, random_state=42)
    reg_model.fit(X_train_d, y_train_d)
    os.makedirs(MODEL_DIR, exist_ok=True)
    joblib.dump(reg_model, os.path.join(MODEL_DIR, 'global_distance_predictor.pkl'))

    # 강도 분류 모델 학습
    clf_model = RandomForestClassifier(n_estimators=100, max_depth=5,class_weight='balanced', random_state=42)
    clf_model.fit(X_train_c, y_train_c)
    joblib.dump(clf_model, os.path.join(MODEL_DIR, 'global_intensity_classifier.pkl'))

    # 테스트 예측 결과 출력
    sample = X_test_d.iloc[[0]]
    pred_distance = reg_model.predict(sample)
    pred_intensity = clf_model.predict(sample)

    mae = mean_absolute_error(y_test_d, reg_model.predict(X_test_d))
    acc = accuracy_score(y_test_c, clf_model.predict(X_test_c))

    print(f"✅ 모델 학습 완료 (사용자 기반 분할)")
    print(f"📏 거리 예측 MAE: {mae:.2f} km")
    print(f"🔥 강도 분류 정확도: {acc * 100:.2f}%")
    print(f"\n🎯 테스트 예측 (샘플):")
    print(f"- 예측 거리: {pred_distance[0]:.2f} km")
    print(f"- 예측 강도: {pred_intensity[0]}")


if __name__ == "__main__":
    train_and_predict()
