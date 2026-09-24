#!/bin/bash
set -euo pipefail

# ==========================================
# Professional Headshot Generator
# ==========================================

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
if [[ "${1:-}" == --help || "${1:-}" == -h ]]; then
    echo 'Usage: ./ProfessionalPortrait.sh [PHOTO_PATH [BLAZER_COLOR]]'
    echo 'Runs Codex in Terminal without opening the desktop app.'
    exit 0
fi
if (( $# > 2 )); then echo 'Expected a photo path and optional blazer color.' >&2; exit 1; fi
command -v codex >/dev/null || { echo 'Codex CLI is missing. Install it and run codex login first.' >&2; exit 1; }

IMAGE_PATH="${1:-}"
if [[ -z "$IMAGE_PATH" ]]; then
    read -r -p 'Enter the full path to your photo: ' IMAGE_PATH
fi
# Accept surrounding quotes pasted into the prompt without evaluating shell code.
if [[ "$IMAGE_PATH" == \"*\" || "$IMAGE_PATH" == \'*\' ]]; then
    IMAGE_PATH="${IMAGE_PATH:1:${#IMAGE_PATH}-2}"
fi
if [[ "$IMAGE_PATH" == '~/'* ]]; then IMAGE_PATH="$HOME/${IMAGE_PATH:2}"; fi

# Make sure the image exists
if [ ! -f "$IMAGE_PATH" ] || [ ! -r "$IMAGE_PATH" ]; then
    echo "Error: I can't find that image."
    exit 1
fi

IMAGE_PATH="$(cd -- "$(dirname -- "$IMAGE_PATH")" && pwd)/$(basename -- "$IMAGE_PATH")"
BLAZER_COLOR="${2:-}"
while [[ -z "${BLAZER_COLOR//[[:space:]]/}" ]]; do
    read -r -p 'What color would you like the blazer to be? ' BLAZER_COLOR
done

WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/professional-portrait.XXXXXX")"
trap 'rm -rf -- "$WORK_DIR"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
case "$IMAGE_PATH" in
    *.[hH][eE][iI][cC]|*.[hH][eE][iI][fF])
        echo 'Converting HEIC photo for Codex...'
        sips -s format png "$IMAGE_PATH" --out "$WORK_DIR/source.png" >/dev/null
        IMAGE_PATH="$WORK_DIR/source.png" ;;
esac
OUTPUT_PATH="$SCRIPT_DIR/professional-headshot-$(date +%Y%m%d-%H%M%S)-${WORK_DIR##*.}.png"

PROMPT="
Use the provided photo as the reference image.

Transform it into a polished professional portrait/headshot suitable for:
- LinkedIn
- job applications
- company profiles
- professional biographies

Requirements:
- Keep the person clearly recognizable.
- Preserve their real facial features and identity.
- Preserve natural skin tone, eye color, and hair.
- Do not substantially change facial proportions.
- Frame the portrait approximately from the chest/shoulders up.
- Give the subject an upright, professional posture.
- Have the subject look directly at the camera.
- Use a natural, confident, professional expression.
- Use realistic professional studio lighting.
- Use a clean, neutral professional background.
- Dress the subject in realistic business-professional clothing.
- Use a well-fitted $BLAZER_COLOR blazer over an understated professional top.
- Keep the head straight, shoulders level, and both eyes looking into the camera lens.
- Preserve natural skin texture and hair texture, with only subtle retouching.
- Avoid excessive skin smoothing or artificial retouching.
- Make the result look like a professional corporate photograph.

The user has already chosen the blazer color: $BLAZER_COLOR. Do not ask again.
Use the professional-headshot and imagegen skills if available.
Generate the image with the built-in image generation tool.
Do not open the Codex desktop app or launch another Codex session.
If image generation is unavailable in this CLI session, report that limitation clearly;
do not silently switch to a paid API workflow or claim an image was created.
Save the finished PNG at this exact path, copying the generated image there if needed:
$OUTPUT_PATH
"

echo "Creating your portrait with Codex in Terminal..."

codex exec --skip-git-repo-check --sandbox workspace-write \
    --cd "$SCRIPT_DIR" --image "$IMAGE_PATH" -- "$PROMPT

The source image is located at:
$IMAGE_PATH
" || { echo 'Codex could not finish. See the error above.' >&2; exit 1; }

if [[ -s "$OUTPUT_PATH" ]]; then
    printf '\nPortrait saved: %s\n' "$OUTPUT_PATH"
else
    echo 'Codex finished without saving the portrait. See its explanation above.' >&2
    exit 1
fi
