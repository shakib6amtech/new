#!/bin/bash
source ./config.conf

cd "$PROJECT_PATH" || exit

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
LOGFILE="$LOG_DIR/auto_git_backup.log"

# Stash changes
git stash push -u -m "TempAutoBackup" > /dev/null 2>&1

# Check backup branch
if ! git show-ref --verify --quiet refs/heads/$BACKUP_BRANCH; then
    git branch $BACKUP_BRANCH $CURRENT_BRANCH
    echo "$TIMESTAMP: Backup branch '$BACKUP_BRANCH' created from '$CURRENT_BRANCH'." >> "$LOGFILE"
fi

# Worktree
git worktree add "$TEMP_WORKTREE" "$BACKUP_BRANCH" > /dev/null 2>&1
cd "$TEMP_WORKTREE" || exit
git stash apply > /dev/null 2>&1

# Commit if changes
CHANGES=$(git status --porcelain)
if [ -n "$CHANGES" ]; then
    git add -A
    FILE_COUNT=$(echo "$CHANGES" | wc -l)
    git commit -m "Auto backup from '$CURRENT_BRANCH' at $TIMESTAMP (files: $FILE_COUNT)"
    
    # Retry push
    ATTEMPT=1
    while [ $ATTEMPT -le $MAX_RETRY ]; do
        if git push origin "$BACKUP_BRANCH"; then
            echo "$TIMESTAMP: Backup pushed successfully (files: $FILE_COUNT)." >> "$LOGFILE"
            break
        else
            echo "$TIMESTAMP: Push failed (attempt $ATTEMPT). Retrying in $RETRY_INTERVAL sec..." >> "$LOGFILE"
            sleep $RETRY_INTERVAL
            ATTEMPT=$((ATTEMPT+1))
        fi
        if [ $ATTEMPT -gt $MAX_RETRY ]; then
            echo "$TIMESTAMP: ERROR! Backup failed after $MAX_RETRY attempts." >> "$LOGFILE"
        fi
    done
else
    echo "$TIMESTAMP: No changes to backup from '$CURRENT_BRANCH'." >> "$LOGFILE"
fi

# Cleanup
git stash drop > /dev/null 2>&1
cd "$PROJECT_PATH" || exit
rm -rf "$TEMP_WORKTREE"
git stash pop > /dev/null 2>&1