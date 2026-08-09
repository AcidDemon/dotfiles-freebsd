#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

usage() {
    echo -e "${YELLOW}Usage:${NC} ${0##*/} --ebook <file> --model <piper_model> [--output <output_file>] [--output-path <output_dir>] [--format <audio_format>] [--split-minutes <min>]"
    echo -e "${YELLOW}Example:${NC} ${0##*/} --ebook book.epub --model en_US-lessac --output-path ./audiobooks --format mp3 --split-minutes 5"
    exit 1
}

for tool in ebook-convert piper; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo -e "${RED}Error:${NC} $tool is required (ebook-convert ships with Calibre)." >&2
        exit 1
    fi
done

needs_value() {
    if (($1 < 2)); then
        echo -e "${RED}Error:${NC} $2 needs a value" >&2
        usage
    fi
}

audio_format_output="mp3"
ebook_file_path=""
audio_output_path=""
audio_output_dir=""
model=""
split_minutes=0

while [[ $# -gt 0 ]]; do
    case "$1" in
    --ebook)
        needs_value $# "$1"
        ebook_file_path="$2"
        shift 2
        ;;
    --output)
        needs_value $# "$1"
        audio_output_path="$2"
        shift 2
        ;;
    --output-path)
        needs_value $# "$1"
        audio_output_dir="$2"
        shift 2
        ;;
    --format)
        needs_value $# "$1"
        audio_format_output="$2"
        shift 2
        ;;
    --model)
        needs_value $# "$1"
        model="$2"
        shift 2
        ;;
    --split-minutes)
        needs_value $# "$1"
        split_minutes="$2"
        shift 2
        ;;
    *)
        echo -e "${RED}Unknown argument:${NC} $1" >&2
        usage
        ;;
    esac
done

if [ -z "$ebook_file_path" ] || [ -z "$model" ]; then
    echo -e "${RED}Error:${NC} --ebook and --model are required." >&2
    usage
fi

if ! [[ "$split_minutes" =~ ^[0-9]+$ ]]; then
    echo -e "${RED}Error:${NC} --split-minutes wants a whole number, got '$split_minutes'." >&2
    usage
fi

ebook_file_path="$(realpath -- "$ebook_file_path")"
ebook_name="$(basename -- "$ebook_file_path")"
ebook_basename="${ebook_name%.*}"

# The converted text is cached between runs because ebook-convert is slow. It
# lives under the user's cache dir, not /tmp, where anyone could pre-create the
# path as a symlink and have ebook-convert write through it.
cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/ebook2audio"
mkdir -p -- "$cache_dir"
temp_txt_path="${cache_dir}/${ebook_basename}.txt"

chunk_dir=""
cleanup() { [[ -n "$chunk_dir" ]] && rm -rf -- "$chunk_dir"; }
trap cleanup EXIT

if [ -n "$audio_output_path" ]; then
    :
elif [ -n "$audio_output_dir" ]; then
    mkdir -p -- "$audio_output_dir"
    audio_output_path="${audio_output_dir}/${ebook_basename}-OUTPUT.${audio_format_output}"
else
    audio_output_path="$(dirname -- "$ebook_file_path")/${ebook_basename}-OUTPUT.${audio_format_output}"
fi

echo -e "${BLUE}Ebook:${NC} $ebook_file_path"
echo -e "${BLUE}Model:${NC} $model"
echo -e "${BLUE}Audio Format:${NC} $audio_format_output"
echo -e "${BLUE}Output Path:${NC} $audio_output_path"
[[ "$split_minutes" -gt 0 ]] && echo -e "${BLUE}Split every:${NC} $split_minutes minute(s)"

if [ ! -f "$temp_txt_path" ]; then
    echo -e "${YELLOW}Converting ebook to text...${NC}"
    ebook-convert "$ebook_file_path" "$temp_txt_path" || {
        echo -e "${RED}Failed to convert ebook to text.${NC}" >&2
        rm -f -- "$temp_txt_path"
        exit 1
    }
else
    echo -e "${YELLOW}Reusing cached text:${NC} $temp_txt_path"
fi

split_text_by_minutes() {
    local file="$1"
    local minutes="$2"
    local wpm=200
    local words_per_chunk=$((minutes * wpm))
    local output_dir
    output_dir="$(mktemp -d)"

    local count=1
    local buffer=""
    local word_count=0
    local line word chunk
    local -a carry

    # word splitting is wanted here, filename expansion is not
    set -f
    while IFS= read -r line || [[ -n "$line" ]]; do
        for word in $line; do
            buffer+="$word "
            word_count=$((word_count + 1))

            if ((word_count >= words_per_chunk)); then
                if [[ "$buffer" == *.* ]]; then
                    chunk="${buffer%.*}."
                    # whatever followed the last period starts the next chunk
                    buffer="${buffer##*.}"
                    buffer="${buffer# }"
                else
                    chunk="$buffer"
                    buffer=""
                fi
                printf "%s" "$chunk" >"$output_dir/part_${count}.txt"
                count=$((count + 1))
                read -ra carry <<<"$buffer"
                word_count=${#carry[@]}
            fi
        done
    done <"$file"
    set +f

    if [ -n "$buffer" ]; then
        printf "%s" "$buffer" >"$output_dir/part_${count}.txt"
    fi

    echo "$output_dir"
}

if [[ "$split_minutes" -gt 0 ]]; then
    chunk_dir="$(split_text_by_minutes "$temp_txt_path" "$split_minutes")"
    failed=0
    # process substitution, so a failure inside the loop is visible out here
    while read -r part_file; do
        part_name="$(basename -- "$part_file" .txt)"
        part_audio_output="${audio_output_path%.*}_${part_name}.${audio_format_output}"

        echo -e "${YELLOW}Generating audio for:${NC} $part_file"
        piper --model "$model" --output_file "$part_audio_output" <"$part_file" || {
            echo -e "${RED}Failed to generate audio for ${part_file}.${NC}" >&2
            failed=$((failed + 1))
        }
    done < <(find "$chunk_dir" -type f -name 'part_*.txt' | sort -V)

    if ((failed > 0)); then
        echo -e "${RED}${failed} chunk(s) failed.${NC}" >&2
        exit 1
    fi
    echo -e "${GREEN}Done. Audiobook parts saved next to:${NC} $audio_output_path"
else
    echo -e "${YELLOW}Generating full audio...${NC}"
    piper --model "$model" --output_file "$audio_output_path" <"$temp_txt_path" || {
        echo -e "${RED}Failed to generate audio.${NC}" >&2
        exit 1
    }

    echo -e "${GREEN}Done. Audiobook saved to:${NC} $audio_output_path"
    (xdg-open "$audio_output_path" >/dev/null 2>&1 || true) &
fi
