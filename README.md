
# 🔍 Redmine Workflow Visualization + GitHub Integration

![Redmine](https://img.shields.io/badge/Redmine-6.1.1-red)
![Ruby](https://img.shields.io/badge/Ruby-3.x-green)
![License](https://img.shields.io/badge/license-MIT-blue)
![CI](https://github.com/ecomen90/workflow_visualization/actions/workflows/ci.yml/badge.svg)

Professional workflow visualization plugin for Redmine with GitHub integration.

---

## ✨ Features

- Workflow graph visualization (SVG/PNG)
- GitHub webhook integration
- Commit → Issue auto linking (#123)
- Role permissions
- Project menu integration

---

## 📸 Screenshots

### Workflow Graph
![Workflow](docs/screenshots/workflow.png)

### GitHub Sync
![GitHub Sync](docs/screenshots/github-sync.png)

---

## 🚀 Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/ecomen90/workflow_visualization/main/install.sh | bash
```

---

## 📦 Manual Install

```bash
cd redmine/plugins
git clone https://github.com/ecomen90/workflow_visualization.git
cd ..
bundle install
bundle exec rake redmine:plugins:migrate RAILS_ENV=production
touch tmp/restart.txt
```

---

## 🔧 Configuration

Administration → Plugins → Workflow Visualization

Enable permission: view_workflow_graph

---

## 📄 License
MIT
