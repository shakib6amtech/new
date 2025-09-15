#!/bin/bash
# -----------------------------
# Installer: Sets up auto backup
# -----------------------------
source ./config.conf

# Create log directory if not exists
mkdir -p "$LOG_DIR"

# Create backup branch if not exists
cd "$PROJECT_PATH" || exit
if ! git show-ref --verify --quiet refs/heads/$BACKUP_BRANCH; then
    git branch $BACKUP_BRANCH $(git rev-parse --abbrev-ref HEAD)
    echo "$(date +"%Y-%m-%d %H:%M:%S"): Backup branch '$BACKUP_BRANCH' created." >> "$LOG_DIR/auto_git_backup.log"
fi

# Setup cron job
(crontab -l 2>/dev/null; echo "*/$INTERVAL * * * * $PWD/auto_backup.sh") | crontab -
echo "Auto backup setup complete! Cron job scheduled every $INTERVAL minutes."