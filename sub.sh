#!/bin/bash

# 获取当前最新的 tag
CURRENT_VERSION=$(git describe --tags --abbrev=0 2>/dev/null || echo "None")
echo "Current version: $CURRENT_VERSION"

# 获取 commit message
if [ -n "$1" ]; then
    MSG=$1
else
    read -p "Enter commit message: " MSG
fi

# 获取新版本号
if [ -n "$2" ]; then
    TAG=$2
else
    read -p "Enter new version tag (e.g., v1.0.10): " TAG
fi

if [ -z "$MSG" ] || [ -z "$TAG" ]; then
    echo "Commit message and tag are required."
    exit 1
fi

echo "-----------------------------------"
echo "Processing release: $TAG"
echo "Message: $MSG"
echo "-----------------------------------"

# Add
echo "1. Staging files..."
git add .

# Commit
echo "2. Committing..."
git commit -m "$MSG"

# Tag
echo "3. Creating tag $TAG..."
git tag "$TAG"

# Push
echo "4. Pushing changes and tag..."
git push
git push origin "$TAG"

echo "-----------------------------------"
echo "Done! Version $TAG released."
