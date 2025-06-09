# import pandas as pd
# import numpy as np
# import joblib
# from sklearn.metrics import (
#     mean_absolute_error, mean_squared_error, r2_score,
#     classification_report, confusion_matrix
# )
# from kakaoapi.ml.predictor import adjust_prediction
# from kakaoapi.ml.train_models import load_runhistory_dataframe, classify_intensity
# import os

# BASE_DIR = os.path.dirname(os.path.abspath(__file__))
# MODEL_DIR = os.path.join(BASE_DIR, 'models')

# # 🔁 점수 기반 라벨 매핑 (강도 점수가 있을 경우)
# def map_score_to_label(score):
#     if score >= 2:
#         return 'High'
#     elif score >= 1:
#         return 'Medium'
#     else:
#         return 'Low'

# # ✅ 시간 기반 분할 함수 (user_email 기준)
# def split_by_time(df, label_col):
#     features = ['distance_km', 'pace', 'heart_rate', 'elapsedTime', 'fatigue_index', 'gap_days']
#     df = df.sort_values(by=['user_email', 'date'])

#     train_idx, test_idx = [], []

#     for user_email, group in df.groupby('user_email'):
#         group = group.sort_values(by='date')
#         n = len(group)
#         split = int(n * 0.7)
#         train_idx += list(group.index[:split])
#         test_idx += list(group.index[split:])

#     return (
#         df.loc[train_idx][features],
#         df.loc[test_idx][features],
#         df.loc[train_idx][label_col],
#         df.loc[test_idx][label_col],
#         df.loc[test_idx]
#     )

# def evaluate_distance_model(df):
#     X_train, X_test, y_train, y_test, df_test = split_by_time(df, 'next_distance')
#     model = joblib.load(os.path.join(MODEL_DIR, 'global_distance_predictor.pkl'))
#     y_pred = model.predict(X_test)

#     mae = mean_absolute_error(y_test, y_pred)
#     rmse = np.sqrt(mean_squared_error(y_test, y_pred))
#     r2 = r2_score(y_test, y_pred)

#     print("\n📏 [거리 예측 모델 평가 결과]")
#     print(f"MAE:  {mae:.2f} km")
#     print(f"RMSE: {rmse:.2f} km")
#     print(f"R²:    {r2:.2f}")

# def evaluate_intensity_classifier(df):
#     X_train, X_test, y_train, y_test, df_test = split_by_time(df, 'intensity_label')
#     model = joblib.load(os.path.join(MODEL_DIR, 'global_intensity_classifier.pkl'))
#     y_pred = model.predict(X_test)

#     print("\n📊 [강도 등급 분류 평가 결과]")
#     print(classification_report(y_test, y_pred, zero_division=1))
#     print("혼동 행렬:")
#     print(confusion_matrix(y_test, y_pred))

# def evaluate_personalization_effect(df):
#     features = ['distanceKm', 'pace', 'heart_rate', 'elapsedTime', 'fatigue_index', 'gap_days']
#     model = joblib.load(os.path.join(MODEL_DIR, 'global_distance_predictor.pkl'))

#     _, X_test, _, y_true, df_test = split_by_time(df, 'next_distance')
#     raw_preds = model.predict(X_test)
#     emails = df_test['user_email'].values
#     adjusted_preds = [adjust_prediction(pred, user_email, df) for pred, user_email in zip(raw_preds, emails)]

#     raw_mae = mean_absolute_error(y_true, raw_preds)
#     adj_mae = mean_absolute_error(y_true, adjusted_preds)

#     print("\n📐 [개인화 보정 효과 분석]")
#     print(f"보정 전 MAE: {raw_mae:.2f} km")
#     print(f"보정 후 MAE: {adj_mae:.2f} km")

# def inject_label_noise(df, column='intensity_label', noise_ratio=0.05, seed=42):
#     import random
#     df = df.copy()
#     np.random.seed(seed)
#     random.seed(seed)

#     n = len(df)
#     noisy_indices = np.random.choice(df.index, size=int(n * noise_ratio), replace=False)

#     for idx in noisy_indices:
#         current = df.at[idx, column]
#         options = ['Low', 'Medium', 'High']
#         options.remove(current)
#         df.at[idx, column] = random.choice(options)

#     return df

# def run_evaluation():
#     df = load_runhistory_dataframe()

#     # 강도 점수 → 라벨 매핑
#     df['intensity_label'] = df.apply(classify_intensity, axis=1)

#     # 다음 거리 생성
#     df['next_distance'] = df.groupby('user_email')['distanceKm'].shift(-1)

#     df.dropna(subset=['intensity_label', 'next_distance'], inplace=True)
#     df = inject_label_noise(df, column='intensity_label', noise_ratio=0.05)

#     evaluate_distance_model(df)
#     evaluate_intensity_classifier(df)
#     evaluate_personalization_effect(df)

# if __name__ == "__main__":
#     run_evaluation()
import pandas as pd
import numpy as np
import joblib
from sklearn.metrics import (
    mean_absolute_error, mean_squared_error, r2_score,
    classification_report, confusion_matrix
)
from kakaoapi.ml.predictor import adjust_prediction
from kakaoapi.ml.train_models import load_runhistory_dataframe, classify_intensity, compute_fatigue_index
import os

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
MODEL_DIR = os.path.join(BASE_DIR, 'models')

# 🔁 점수 기반 라벨 매핑 (강도 점수가 있을 경우)
def map_score_to_label(score):
    if score >= 2:
        return 'High'
    elif score >= 1:
        return 'Medium'
    else:
        return 'Low'

# ✅ elapsedTime 변환 함수
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

# ✅ 시간 기반 분할 함수 (user_email 기준)
def split_by_time(df, label_col):
    features = ['distanceKm', 'pace', 'heart_rate', 'elapsedTime', 'fatigue_index', 'gap_days']
    df = df.sort_values(by=['user_email', 'dateTime'])


    train_idx, test_idx = [], []
    for user_email, group in df.groupby('user_email'):
        group = group.sort_values(by='dateTime')
        n = len(group)
        split = int(n * 0.7)
        train_idx += list(group.index[:split])
        test_idx += list(group.index[split:])

    return (
        df.loc[train_idx][features],
        df.loc[test_idx][features],
        df.loc[train_idx][label_col],
        df.loc[test_idx][label_col],
        df.loc[test_idx]
    )

def evaluate_distance_model(df):
    X_train, X_test, y_train, y_test, df_test = split_by_time(df, 'next_distance')
    model = joblib.load(os.path.join(MODEL_DIR, 'global_distance_predictor.pkl'))
    y_pred = model.predict(X_test)

    mae = mean_absolute_error(y_test, y_pred)
    rmse = np.sqrt(mean_squared_error(y_test, y_pred))
    r2 = r2_score(y_test, y_pred)

    print("\n📏 [거리 예측 모델 평가 결과]")
    print(f"MAE:  {mae:.2f} km")
    print(f"RMSE: {rmse:.2f} km")
    print(f"R²:    {r2:.2f}")

def evaluate_intensity_classifier(df):
    X_train, X_test, y_train, y_test, df_test = split_by_time(df, 'intensity_label')
    model = joblib.load(os.path.join(MODEL_DIR, 'global_intensity_classifier.pkl'))
    y_pred = model.predict(X_test)

    print("\n📊 [강도 등급 분류 평가 결과]")
    print(classification_report(y_test, y_pred, zero_division=1))
    print("혼동 행렬:")
    print(confusion_matrix(y_test, y_pred))

def evaluate_personalization_effect(df):
    features = ['distanceKm', 'pace', 'heart_rate', 'elapsedTime', 'fatigue_index', 'gap_days']
    model = joblib.load(os.path.join(MODEL_DIR, 'global_distance_predictor.pkl'))

    _, X_test, _, y_true, df_test = split_by_time(df, 'next_distance')
    raw_preds = model.predict(X_test)
    emails = df_test['user_email'].values
    adjusted_preds = [adjust_prediction(pred, user_email, df) for pred, user_email in zip(raw_preds, emails)]

    raw_mae = mean_absolute_error(y_true, raw_preds)
    adj_mae = mean_absolute_error(y_true, adjusted_preds)

    print("\n📐 [개인화 보정 효과 분석]")
    print(f"보정 전 MAE: {raw_mae:.2f} km")
    print(f"보정 후 MAE: {adj_mae:.2f} km")

def inject_label_noise(df, column='intensity_label', noise_ratio=0.05, seed=42):
    import random
    df = df.copy()
    np.random.seed(seed)
    random.seed(seed)

    n = len(df)
    noisy_indices = np.random.choice(df.index, size=int(n * noise_ratio), replace=False)

    for idx in noisy_indices:
        current = df.at[idx, column]
        options = ['Low', 'Medium', 'High']
        options.remove(current)
        df.at[idx, column] = random.choice(options)

    return df

def run_evaluation():
    df = load_runhistory_dataframe()
    df['fatigue_index'] = df.apply(
        lambda row: compute_fatigue_index(row) if pd.isnull(row['fatigue_index']) else row['fatigue_index'],
        axis=1
    )
    # ✅ elapsedTime 문자열 → 정수형 분 단위로 변환
    df['elapsedTime'] = df['elapsedTime'].apply(convert_elapsed_to_min)

    # 강도 점수 → 라벨 매핑
    df['intensity_label'] = df.apply(classify_intensity, axis=1)

    # 다음 거리 생성
    df['next_distance'] = df.groupby('user_email')['distanceKm'].shift(-1)

    df.dropna(subset=['intensity_label', 'next_distance'], inplace=True)
    df = inject_label_noise(df, column='intensity_label', noise_ratio=0.05)

    evaluate_distance_model(df)
    evaluate_intensity_classifier(df)
    evaluate_personalization_effect(df)

if __name__ == "__main__":
    run_evaluation()
