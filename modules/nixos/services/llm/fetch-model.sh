# Usage: llm-fetch-model PATH  (env: MODEL_URL, MODEL_SHA256)
model=$1
[ -e "$model" ] && exit 0
curl -fL --retry 5 -C - -o "$model.part" "$MODEL_URL"
if ! echo "$MODEL_SHA256  $model.part" | sha256sum -c -; then
  rm -f "$model.part"
  exit 1
fi
mv "$model.part" "$model"
