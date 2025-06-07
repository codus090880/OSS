@echo off
REM ⚠️ 이 파일은 템플릿입니다. 본인 경로에 맞게 복사해서 사용하세요.

call <your-conda-path>\activate.bat <your-conda-env>
cd <your-project-path>
python manage.py retrain_models
