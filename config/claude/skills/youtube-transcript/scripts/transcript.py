#!/usr/bin/env python3
"""Retrieve captions without downloading media or changing source wording."""

from __future__ import annotations

import argparse
import html
import json
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import TYPE_CHECKING
from urllib.parse import parse_qs, urlsplit

if TYPE_CHECKING:
    from collections.abc import Iterator
    from typing import Any

YTDLP_OPTIONS = [
    "--ignore-config",
    "--no-playlist",
    "--skip-download",
    "--retries",
    "0",
    "--extractor-retries",
    "0",
    "--socket-timeout",
    "30",
]


def video_url(value: str) -> tuple[str, str]:
    """Normalize inputs so playlist parameters cannot expand the download.

    Returns:
        The canonical watch URL and validated video ID.

    Raises:
        ValueError: The input does not identify a single YouTube video.

    """
    value = value.strip()
    if re.fullmatch(r"[A-Za-z0-9_-]{11}", value):
        value = f"https://www.youtube.com/watch?v={value}"
    url = urlsplit(value)
    if url.scheme not in {"http", "https"}:
        message = "Provide a YouTube video ID or an HTTP or HTTPS video URL."
        raise ValueError(message)
    if url.hostname in {"youtu.be", "www.youtu.be"}:
        video_id = url.path.removeprefix("/")
    elif url.hostname in {
        "youtube.com",
        "www.youtube.com",
        "m.youtube.com",
        "music.youtube.com",
    }:
        prefix, separator, suffix = url.path.strip("/").partition("/")
        if url.path == "/watch":
            video_id = parse_qs(url.query).get("v", [""])[0]
        elif separator and prefix in {"shorts", "live", "embed"}:
            video_id = suffix
        else:
            video_id = ""
    else:
        message = "Provide a YouTube video URL, not another website."
        raise ValueError(message)
    if not re.fullmatch(r"[A-Za-z0-9_-]{11}", video_id):
        message = "Provide one video URL, not a playlist or channel."
        raise ValueError(message)
    return f"https://www.youtube.com/watch?v={video_id}", video_id


def run_ytdlp(executable: str, *arguments: str) -> str:
    """Keep diagnostics visible while capturing metadata separately.

    Returns:
        Standard output from the successful yt-dlp command.

    Raises:
        ValueError: yt-dlp exits with a nonzero status.

    """
    result = subprocess.run(
        [executable, *YTDLP_OPTIONS, *arguments],
        stdout=subprocess.PIPE,
        text=True,
        encoding="utf-8",
        check=False,
    )
    if result.returncode:
        if result.stdout:
            print(result.stdout, file=sys.stderr, end="")
        message = (
            f"yt-dlp failed with exit code {result.returncode}. "
            "See its diagnostics above."
        )
        raise ValueError(message)
    return result.stdout


def caption_tracks(info: dict[str, Any]) -> Iterator[tuple[str, str, bool]]:
    """Exclude formats without structured caption events.

    Yields:
        Language, source, and translation status for each JSON3 caption track.

    """
    for key, source in (("subtitles", "human"), ("automatic_captions", "automatic")):
        for language, formats in (info.get(key) or {}).items():
            if language == "live_chat":
                continue
            for entry in formats:
                if entry.get("ext") == "json3":
                    translated = bool(
                        parse_qs(urlsplit(entry.get("url", "")).query).get("tlang")
                    )
                    yield language, source, translated
                    break


def select_track(
    tracks: list[tuple[str, str, bool]], language: str, *, allow_translated: bool
) -> tuple[str, str, bool]:
    """Require translation consent before preferring a matching caption source.

    Returns:
        The preferred permitted track for the exact language tag.

    Raises:
        ValueError: No track matches, or matching tracks require translation consent.

    """
    matches = [track for track in tracks if track[0] == language]
    if not matches:
        message = (
            f"No JSON3 captions for {language!r}. "
            "Use --list-languages to see available tracks."
        )
        raise ValueError(message)
    permitted = [track for track in matches if allow_translated or not track[2]]
    if not permitted:
        message = (
            "Only translated captions match. "
            "Confirm translation, then pass --allow-translated."
        )
        raise ValueError(message)
    return min(permitted, key=lambda track: (track[2], track[1] != "human"))


def transcript_lines(captions: dict[str, Any]) -> list[str]:
    """Preserve wording without reproducing rolling-display duplicates.

    Returns:
        Nonempty caption events with source start times in minutes and seconds.

    Raises:
        TypeError: The JSON3 events field is missing or is not a list.
        ValueError: A caption timestamp is invalid, or no transcript text remains.

    """
    events = captions.get("events")
    if not isinstance(events, list):
        message = "The downloaded captions have no JSON3 events."
        raise TypeError(message)
    lines = []
    for event in events:
        segments = event.get("segs", [])
        # Window-position events contain no speech.
        # JSON3 avoids VTT's rolling display duplicates.
        text = "".join(segment.get("utf8", "") for segment in segments)
        text = " ".join(html.unescape(text).split())
        if not text:
            continue
        start = event.get("tStartMs")
        if not isinstance(start, int) or start < 0:
            message = "A caption has an invalid start time."
            raise ValueError(message)
        seconds = start // 1000
        minutes, seconds = divmod(seconds, 60)
        lines.append(f"[{minutes}:{seconds:02d}] {text}")
    if not lines:
        message = "The downloaded captions contain no transcript text."
        raise ValueError(message)
    return lines


def download_captions(
    executable: str, info: dict[str, Any], track: tuple[str, str, bool]
) -> list[str]:
    """Reuse metadata so selection and download use the same tracks.

    Returns:
        Timestamped lines from the selected caption track.

    Raises:
        ValueError: The download does not produce exactly one nonempty caption file.

    """
    language, source, _ = track
    with tempfile.TemporaryDirectory(prefix="youtube-transcript-") as directory:
        workdir = Path(directory)
        metadata = workdir / "metadata.json"
        metadata.write_text(json.dumps(info), encoding="utf-8")
        flags = (
            ["--write-subs", "--no-write-auto-subs"]
            if source == "human"
            else ["--no-write-subs", "--write-auto-subs"]
        )
        log = run_ytdlp(
            executable,
            "--load-info-json",
            str(metadata),
            *flags,
            "--sub-langs",
            f"^{re.escape(language)}$",
            "--sub-format",
            "json3",
            "--output",
            str(workdir / "captions.%(ext)s"),
        )
        if log:
            print(log, file=sys.stderr, end="")
        files = list(workdir.glob("captions.*.json3"))
        if len(files) != 1 or files[0].stat().st_size == 0:
            message = "yt-dlp did not produce one nonempty caption file."
            raise ValueError(message)
        return transcript_lines(json.loads(files[0].read_text(encoding="utf-8")))


def run(args: argparse.Namespace) -> int:
    """Keep retrieval failures inside the CLI error boundary.

    Returns:
        Zero after listing tracks or saving the transcript.

    Raises:
        ValueError: Dependencies, output paths, video metadata, or tracks are invalid.

    """
    url, video_id = video_url(args.url)
    executable = shutil.which("yt-dlp")
    if not executable:
        message = "yt-dlp is required but was not found in PATH."
        raise ValueError(message)
    output = (
        (args.output or Path(".scratch") / "youtube" / video_id / "transcript.txt")
        .expanduser()
        .absolute()
    )
    if not args.list_languages:
        if output.suffix != ".txt" or output.is_dir():
            message = "The output must be a .txt file path, not a directory."
            raise ValueError(message)
        if (output.exists() or output.is_symlink()) and not args.overwrite:
            message = (
                f"Output already exists: {output}. "
                "Confirm replacement before using --overwrite."
            )
            raise ValueError(message)

    info = json.loads(run_ytdlp(executable, "--dump-single-json", "--", url))
    if info.get("id") != video_id or info.get("_type", "video") != "video":
        message = "yt-dlp did not return the requested single video."
        raise ValueError(message)
    tracks = list(caption_tracks(info))
    if not tracks:
        message = "No supported JSON3 caption tracks are available for this video."
        raise ValueError(message)
    if args.list_languages:
        for language, source, translated in tracks:
            print(f"{language}\t{source}" + ("\ttranslated" if translated else ""))
        return 0

    track = select_track(tracks, args.language, allow_translated=args.allow_translated)
    lines = download_captions(executable, info, track)
    output.parent.mkdir(parents=True, exist_ok=True)
    # Exclusive creation also protects files created while the download was running.
    with output.open(
        "w" if args.overwrite else "x", encoding="utf-8", newline="\n"
    ) as stream:
        stream.write("\n".join(lines) + "\n")
    language, source, translated = track
    print(f"Saved: {output}")
    print(f"Source: {url}")
    print(f"Language: {language}")
    print(f"Captions: {source}" + (", translated" if translated else ""))
    if source == "automatic":
        print("Warning: automatic captions can contain recognition errors.")
    return 0


def main() -> int:
    """Report operational failures without exposing Python tracebacks.

    Returns:
        Zero on success or one after reporting an operational failure.

    """
    parser = argparse.ArgumentParser(
        description="Save existing YouTube captions as timestamped UTF-8 text.",
    )
    parser.add_argument("url", metavar="VIDEO", help="single YouTube video ID or URL")
    selection = parser.add_mutually_exclusive_group(required=True)
    selection.add_argument(
        "--language", help="exact caption language tag, such as en or en-US"
    )
    selection.add_argument(
        "--list-languages",
        action="store_true",
        help="list supported caption tracks without downloading",
    )
    parser.add_argument(
        "--output",
        type=Path,
        help="output .txt path; default: .scratch/youtube/<id>/transcript.txt",
    )
    parser.add_argument(
        "--overwrite",
        action="store_true",
        help="replace an existing output file after user approval",
    )
    parser.add_argument(
        "--allow-translated",
        action="store_true",
        help="allow translated captions after user approval",
    )
    args = parser.parse_args()

    try:
        status = run(args)
    except (OSError, TypeError, ValueError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 1
    return status


if __name__ == "__main__":
    sys.exit(main())
