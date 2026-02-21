
# 🔍 Redmine 워크플로우 시각화 + GitHub 연동 플러그인

Redmine 6.1.1 전용 워크플로우 그래프 시각화 및 GitHub 연동 플러그인입니다.

---

## 주요 기능

- 워크플로우 상태 그래프 (SVG/PNG)
- GitHub Webhook 연동
- 커밋 → 이슈 자동 연결 (#123)
- 역할 기반 권한

---

## 스크린샷

![Workflow](docs/screenshots/workflow.png)
![GitHub Sync](docs/screenshots/github-sync.png)

---

## 빠른 설치

```bash
curl -fsSL https://raw.githubusercontent.com/ecomen90/workflow_visualization/main/install.sh | bash
```

---

## 수동 설치

```bash
cd redmine/plugins
git clone https://github.com/ecomen90/workflow_visualization.git
cd ..
bundle install
bundle exec rake redmine:plugins:migrate RAILS_ENV=production
touch tmp/restart.txt
```

---

## 권한 설정

관리 → 역할 및 권한 → view_workflow_graph 체크

---

## 라이선스
MIT
