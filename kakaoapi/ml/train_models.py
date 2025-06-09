import pandas as pd
import joblib
from sklearn.ensemble import RandomForestRegressor, RandomForestClassifier
from lightgbm import LGBMClassifier
from sklearn.model_selection import GroupShuffleSplit
from sklearn.metrics import mean_absolute_error, accuracy_score
from sklearn.utils import resample
import seaborn as sns
import matplotlib.pyplot as plt
from kakaoapi.models import RunHistory
from imblearn.over_sampling import SMOTE
from sklearn.model_selection import train_test_split

import os

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
MODEL_DIR = os.path.join(BASE_DIR, 'models')

def convert_elapsed_to_min(s):
    """
    문자열 형식의 elapsedTime을 분(min) 단위 정수로 변환.
    예: "45:12" → 45분, "01:30:00" → 90분
    """
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


def compute_fatigue_index(row):
    """
    피로도 계산 공식 (예시):
    - 심박수, 지속 시간, 페이스를 기준으로 단순 계산
    - 값 범위는 0.0~1.0 사이 정규화 (예시 기준)

    조정 필요: 실제 피드백 데이터가 있다면 학습 기반 회귀모델로 대체 가능
    """
    heart = row.get('heart_rate', 0) or 0
    duration = row.get('elapsedTime', 0) or 0
    pace = row.get('pace', 0) or 0

    # 피로도 = 심박수 정규화 * 시간 정규화 * 페이스 가중치
    heart_score = min(heart / 200, 1.0)
    duration_score = min(duration / 90, 1.0)
    pace_score = max(0, min((7.5 - pace) / 5, 1.0))  # 빠를수록 피로

    return round(heart_score * duration_score * pace_score, 3)


def load_runhistory_dataframe(user=None):
    queryset = RunHistory.objects.select_related('user')
    
    if user is not None:
        queryset = queryset.filter(user=user)


    df = pd.DataFrame(list(queryset.values(
        'user__email', 'dateTime', 'distanceKm', 'elapsedTime',
        'calories', 'averageSpeedKmh', 'cadenceSpm', 'route',
        'heart_rate', 'pace', 'gap_days', 'fatigue_index',
        'is_challenge', 'run_type', 'predicted_distance', 'predicted_intensity'
    )))
    df.rename(columns={"user__email": "user_email"}, inplace=True)

    # ✅ elapsedTime을 숫자형 분(min)으로 변환
    df['elapsedTime'] = df['elapsedTime'].apply(convert_elapsed_to_min)
    df['fatigue_index'] = df.apply(
    lambda row: compute_fatigue_index(row) if pd.isnull(row['fatigue_index']) else row['fatigue_index'],
    axis=1
    )
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
    if row['distanceKm'] >= 9:
        score += 2
    elif 6 <= row['distanceKm'] < 9:
        score += 1

    # 총점 기반 분류
    if score >= 5:
        return 'High'
    elif score >= 3:
        return 'Medium'
    else:
        return 'Low'


# def train_and_predict():
#     df = load_runhistory_dataframe()

#     # 라벨 생성
#     df['intensity_label'] = df.apply(classify_intensity, axis=1)
#     df['next_distance'] = df.groupby('user_id')['distance_km'].shift(-1)
#     df['next_intensity_label'] = df.groupby('user_id')['intensity_label'].shift(-1)
#     df.dropna(subset=['next_distance', 'next_intensity_label'], inplace=True)

#     # 📊 시각화 (확인용)
#     sns.boxplot(data=df, x='next_intensity_label', y='pace')
#     plt.title("pace vs intensity")
#     plt.show()

#     sns.boxplot(data=df, x='next_intensity_label', y='heart_rate')
#     plt.title("heart_rate vs intensity")
#     plt.show()

#     print("\n✅ 라벨 분포:")
#     print(df['next_intensity_label'].value_counts())

#     # ⚖️ 클래스 균형 맞추기 (최소값 기준)
#     min_size = min(
#         df['next_intensity_label'].value_counts()['High'],
#         df['next_intensity_label'].value_counts()['Low'],
#         df['next_intensity_label'].value_counts()['Medium']
#     )

#     df_balanced = pd.concat([
#         resample(df[df['next_intensity_label'] == lbl], replace=True, n_samples=min_size, random_state=42)
#         for lbl in ['High', 'Medium', 'Low']
#     ])


#     # 기존 features, X, y 정의 이후부터 수정
#     features = ['distance_km', 'pace', 'heart_rate', 'duration_min', 'fatigue_index', 'gap_days']
#     X = df[features]
#     y_distance = df['next_distance']
#     y_intensity = df['next_intensity_label']
#     groups = df['user_id']

#     # 🎯 SMOTE 적용 (강도 분류용 데이터만)
#     sm = SMOTE(random_state=42)
#     X_smote, y_smote = sm.fit_resample(X, y_intensity)

#     # 거리 예측은 SMOTE 없이 원래 데이터 사용
#     X_d = X
#     y_d = y_distance

#     # 사용자 ID에 맞춰 그룹 추출 (SMOTE 이후에는 user_id 정보가 사라지므로)
#     # 따라서 사용자 기반 분할은 여기까지만 사용하고 이후는 무작위 분할로 처리
#     gss = GroupShuffleSplit(n_splits=1, test_size=0.2, random_state=42)
#     train_idx_d, test_idx_d = next(gss.split(X_d, y_d, groups=groups))

#     X_train_d, X_test_d = X_d.iloc[train_idx_d], X_d.iloc[test_idx_d]
#     y_train_d, y_test_d = y_d.iloc[train_idx_d], y_d.iloc[test_idx_d]

#     # 🧠 SMOTE 데이터는 사용자 기반 분할 불가 → 랜덤 분할 사용
#     from sklearn.model_selection import train_test_split
#     X_train_c, X_test_c, y_train_c, y_test_c = train_test_split(
#         X_smote, y_smote, test_size=0.2, random_state=42, stratify=y_smote
#     )

#     # 거리 예측 모델 (기존과 동일)
#     reg_model = RandomForestRegressor(n_estimators=100, max_depth=5, random_state=42)
#     reg_model.fit(X_train_d, y_train_d)

#     # 강도 분류 모델 (기존과 동일)
#     clf_model = RandomForestClassifier(n_estimators=200, max_depth=10, class_weight='balanced', random_state=42)
#     clf_model.fit(X_train_c, y_train_c)

#     # 저장
#     os.makedirs(MODEL_DIR, exist_ok=True)
#     joblib.dump(reg_model, os.path.join(MODEL_DIR, 'global_distance_predictor.pkl'))
#     joblib.dump(clf_model, os.path.join(MODEL_DIR, 'global_intensity_classifier.pkl'))

#     # 예측 샘플
#     sample = X_test_d.iloc[[0]]
#     pred_distance = reg_model.predict(sample)
#     pred_intensity = clf_model.predict(sample)

#     # 평가
#     mae = mean_absolute_error(y_test_d, reg_model.predict(X_test_d))
#     acc = accuracy_score(y_test_c, clf_model.predict(X_test_c))

#     print(f"\n✅ 모델 학습 완료 (SMOTE 적용)")
#     print(f"📏 거리 예측 MAE: {mae:.2f} km")
#     print(f"🔥 강도 분류 정확도: {acc * 100:.2f}%")
#     print(f"🎯 예측 샘플:")
#     print(f"- 예측 거리: {pred_distance[0]:.2f} km")
#     print(f"- 예측 강도: {pred_intensity[0]}")



def train_and_predict():
    df = load_runhistory_dataframe()

    # 라벨 생성
    df['intensity_label'] = df.apply(classify_intensity, axis=1)
    df['next_distance'] = df.groupby('user_email')['distanceKm'].shift(-1)  # ✅ user_email 기반
    df['next_intensity_label'] = df.groupby('user_email')['intensity_label'].shift(-1)
    df.dropna(subset=['next_distance', 'next_intensity_label'], inplace=True)

    # 📊 시각화 (확인용)
    sns.boxplot(data=df, x='next_intensity_label', y='pace')
    plt.title("pace vs intensity")
    plt.show()

    sns.boxplot(data=df, x='next_intensity_label', y='heart_rate')
    plt.title("heart_rate vs intensity")
    plt.show()

    print("\n✅ 라벨 분포:")
    print(df['next_intensity_label'].value_counts())

    # ⚖️ 클래스 균형 맞추기 (최소값 기준)
    min_size = min(
        df['next_intensity_label'].value_counts()['High'],
        df['next_intensity_label'].value_counts()['Low'],
        df['next_intensity_label'].value_counts()['Medium']
    )

    df_balanced = pd.concat([
        resample(df[df['next_intensity_label'] == lbl], replace=True, n_samples=min_size, random_state=42)
        for lbl in ['High', 'Medium', 'Low']
    ])

    # Feature 정의
    features = ['distanceKm', 'pace', 'heart_rate', 'elapsedTime', 'fatigue_index', 'gap_days']
    X = df_balanced[features]
    y_distance = df_balanced['next_distance']
    y_intensity = df_balanced['next_intensity_label']
    groups = df_balanced['user_email']  # ✅ 변경됨

    # 🎯 SMOTE 적용 (강도 분류용 데이터만)
    sm = SMOTE(random_state=42)
    X_smote, y_smote = sm.fit_resample(X, y_intensity)

    # 거리 예측은 SMOTE 없이 원래 데이터 사용
    X_d = X
    y_d = y_distance

    # 사용자(email) 기반 분할 → SMOTE 이전 데이터에서만 사용 가능
    gss = GroupShuffleSplit(n_splits=1, test_size=0.2, random_state=42)
    train_idx_d, test_idx_d = next(gss.split(X_d, y_d, groups=groups))

    X_train_d, X_test_d = X_d.iloc[train_idx_d], X_d.iloc[test_idx_d]
    y_train_d, y_test_d = y_d.iloc[train_idx_d], y_d.iloc[test_idx_d]

    # 🧠 SMOTE 이후에는 사용자 정보가 없으므로 무작위 분할
    X_train_c, X_test_c, y_train_c, y_test_c = train_test_split(
        X_smote, y_smote, test_size=0.2, random_state=42, stratify=y_smote
    )

    # 모델 정의 및 학습
    reg_model = RandomForestRegressor(n_estimators=100, max_depth=5, random_state=42)
    reg_model.fit(X_train_d, y_train_d)

    clf_model = RandomForestClassifier(n_estimators=200, max_depth=10, class_weight='balanced', random_state=42)
    clf_model.fit(X_train_c, y_train_c)

    # 모델 저장
    os.makedirs(MODEL_DIR, exist_ok=True)
    joblib.dump(reg_model, os.path.join(MODEL_DIR, 'global_distance_predictor.pkl'))
    joblib.dump(clf_model, os.path.join(MODEL_DIR, 'global_intensity_classifier.pkl'))

    # 평가 및 예측 샘플
    sample = X_test_d.iloc[[0]]
    pred_distance = reg_model.predict(sample)
    pred_intensity = clf_model.predict(sample)

    mae = mean_absolute_error(y_test_d, reg_model.predict(X_test_d))
    acc = accuracy_score(y_test_c, clf_model.predict(X_test_c))

    print(f"\n✅ 모델 학습 완료 (SMOTE 적용)")
    print(f"📏 거리 예측 MAE: {mae:.2f} km")
    print(f"🔥 강도 분류 정확도: {acc * 100:.2f}%")
    print(f"🎯 예측 샘플:")
    print(f"- 예측 거리: {pred_distance[0]:.2f} km")
    print(f"- 예측 강도: {pred_intensity[0]}")

if __name__ == "__main__":
    train_and_predict()
