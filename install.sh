
#!/bin/bash
set -e

PLUGIN="workflow_visualization"
REDMINE_DIR=${1:-/opt/redmine}

echo "Installing plugin into $REDMINE_DIR"

cd $REDMINE_DIR/plugins

if [ -d "$PLUGIN" ]; then
  echo "Updating existing plugin..."
  cd $PLUGIN && git pull
else
  git clone https://github.com/ecomen90/workflow_visualization.git
fi

cd $REDMINE_DIR

bundle install
bundle exec rake redmine:plugins:migrate RAILS_ENV=production

touch tmp/restart.txt

echo "✅ Installation complete!"
