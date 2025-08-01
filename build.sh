#!/bin/bash
set -e

echo "=== DevKit Lambda Packaging Script ==="

# 1️⃣ Locate devkit.yaml or .yml (case-insensitive)
DEVKIT_FILE=$(find . -type f \( -iname "devkit.yaml" -o -iname "devkit.yml" \) | head -n 1)
if [[ -z "$DEVKIT_FILE" ]]; then
  echo "❌ Error: devkit.yaml or devkit.yml not found!"
  exit 1
fi
echo "✅ Found DevKit file: $DEVKIT_FILE"

# Ensure yq is installed (for parsing YAML)
if ! command -v yq &> /dev/null; then
  echo "Installing yq..."
  curl -sL https://github.com/mikefarah/yq/releases/download/v4.43.1/yq_linux_amd64 -o /usr/local/bin/yq
  chmod +x /usr/local/bin/yq
fi

# 2️⃣ Detect branch (target of PR or current branch in pipeline)
BRANCH_NAME=${CODEBUILD_SOURCE_VERSION:-$(git rev-parse --abbrev-ref HEAD)}
if [[ "$BRANCH_NAME" == "refs/heads/"* ]]; then
  BRANCH_NAME=${BRANCH_NAME#refs/heads/}
fi
echo "✅ Detected branch: $BRANCH_NAME"

# 3️⃣ Get all Lambda names from devkit.yaml
LAMBDA_NAMES=$(yq e '.lambdas | keys | .[]' "$DEVKIT_FILE")

for LAMBDA in $LAMBDA_NAMES; do
  ARN=$(yq e ".lambdas.$LAMBDA.${BRANCH_NAME}" "$DEVKIT_FILE")
  if [[ "$ARN" == "null" ]]; then
    echo "⚠️ No ARN found for $LAMBDA in branch $BRANCH_NAME, skipping..."
    continue
  fi

  echo "📦 Processing Lambda: $LAMBDA ($ARN)"

  # Lambda type (zip/code/container)
  LAMBDA_TYPE=$(yq e ".lambdas.$LAMBDA.type" "$DEVKIT_FILE")
  if [[ "$LAMBDA_TYPE" == "null" ]]; then
    LAMBDA_TYPE="zip"
  fi
  echo "   → Lambda type: $LAMBDA_TYPE"

  # Requirements file
  REQ_PATH=$(yq e ".lambdas.$LAMBDA.requirementsPath" "$DEVKIT_FILE")
  if [[ "$REQ_PATH" != "null" && -f "$REQ_PATH" ]]; then
    echo "   → Installing dependencies from $REQ_PATH"
    mkdir -p "./lambda/$LAMBDA/package"
    pip install -r "$REQ_PATH" -t "./lambda/$LAMBDA/package"
  fi

  # Extra dependencies
  DEPENDENCIES=$(yq e ".lambdas.$LAMBDA.dependencies[]" "$DEVKIT_FILE" 2>/dev/null || true)
  if [[ ! -z "$DEPENDENCIES" ]]; then
    echo "   → Installing extra dependencies"
    mkdir -p "./lambda/$LAMBDA/package"
    for DEP in $DEPENDENCIES; do
      pip install "$DEP" -t "./lambda/$LAMBDA/package"
    done
  fi

  # Package Lambda
  case "$LAMBDA_TYPE" in
    zip|code)
      echo "   → Creating ZIP for $LAMBDA"
      cd "./lambda/$LAMBDA"
      zip -r "../../${LAMBDA}.zip" . > /dev/null
      cd - > /dev/null
      ;;
    container)
      echo "   → Building container image for $LAMBDA"
      IMAGE_NAME="${LAMBDA}:${BRANCH_NAME}"
      docker build -t "$IMAGE_NAME" "./lambda/$LAMBDA"
      docker save "$IMAGE_NAME" -o "${LAMBDA}.tar"
      ;;
    *)
      echo "❌ Unknown Lambda type: $LAMBDA_TYPE"
      exit 1
      ;;
  esac

  echo "✅ $LAMBDA packaged successfully"
done

echo "=== Packaging complete ==="
