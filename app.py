import os
import queue
import threading
from dataclasses import dataclass
from pathlib import Path
from typing import List

import customtkinter as ctk
import imageio_ffmpeg
import tkinter.filedialog as fd
import yt_dlp


ctk.set_appearance_mode("light")
ctk.set_default_color_theme("blue")


@dataclass
class DownloadJob:
    urls: List[str]
    output_dir: Path
    mode: str  # video | audio


class YTDLPApp(ctk.CTk):
    def __init__(self):
        super().__init__()
        self.title("클릭다운 - 재생목록 한번에 저장")
        self.geometry("960x680")
        self.minsize(840, 600)

        self.log_queue: queue.Queue[str] = queue.Queue()
        self.worker_thread: threading.Thread | None = None

        self._build_ui()
        self.after(100, self._drain_log_queue)

    def _build_ui(self):
        self.grid_columnconfigure(0, weight=1)
        self.grid_rowconfigure(1, weight=1)

        header = ctk.CTkFrame(self, fg_color="#F8FAFD", corner_radius=0)
        header.grid(row=0, column=0, sticky="ew")
        header.grid_columnconfigure(0, weight=1)

        title = ctk.CTkLabel(
            header,
            text="클릭다운",
            font=ctk.CTkFont(size=30, weight="bold"),
            text_color="#1F2937",
        )
        title.grid(row=0, column=0, sticky="w", padx=30, pady=(24, 4))

        subtitle = ctk.CTkLabel(
            header,
            text="링크/재생목록 붙여넣기 → 저장 폴더 선택 → 다운로드",
            font=ctk.CTkFont(size=14),
            text_color="#6B7280",
        )
        subtitle.grid(row=1, column=0, sticky="w", padx=30, pady=(0, 20))

        body = ctk.CTkFrame(self, fg_color="#EEF2F7", corner_radius=18)
        body.grid(row=1, column=0, sticky="nsew", padx=20, pady=20)
        body.grid_columnconfigure(0, weight=1)
        body.grid_rowconfigure(3, weight=1)

        urls_label = ctk.CTkLabel(body, text="다운로드 링크 (여러 개 가능)", font=ctk.CTkFont(size=15, weight="bold"))
        urls_label.grid(row=0, column=0, sticky="w", padx=20, pady=(20, 8))

        self.urls_input = ctk.CTkTextbox(body, height=160, font=("Malgun Gothic", 13), corner_radius=12)
        self.urls_input.grid(row=1, column=0, sticky="ew", padx=20)
        self.urls_input.insert("1.0", "https://www.youtube.com/watch?v=...\nhttps://www.youtube.com/playlist?list=...")

        options = ctk.CTkFrame(body, fg_color="transparent")
        options.grid(row=2, column=0, sticky="ew", padx=20, pady=16)
        options.grid_columnconfigure(1, weight=1)

        ctk.CTkLabel(options, text="저장 위치", width=80).grid(row=0, column=0, sticky="w")
        self.output_entry = ctk.CTkEntry(options, height=40)
        self.output_entry.grid(row=0, column=1, sticky="ew", padx=(12, 12))
        self.output_entry.insert(0, str(Path.home() / "Downloads" / "클릭다운"))

        browse_btn = ctk.CTkButton(options, text="폴더 선택", command=self.pick_output_dir, width=120, height=40)
        browse_btn.grid(row=0, column=2)

        ctk.CTkLabel(options, text="형식", width=80).grid(row=1, column=0, sticky="w", pady=(12, 0))
        self.mode_var = ctk.StringVar(value="video")
        self.mode_option = ctk.CTkOptionMenu(
            options,
            values=["video", "audio"],
            variable=self.mode_var,
            width=180,
            height=36,
        )
        self.mode_option.grid(row=1, column=1, sticky="w", padx=(12, 0), pady=(12, 0))

        self.start_btn = ctk.CTkButton(
            options,
            text="다운로드 시작",
            command=self.start_download,
            height=42,
            width=180,
            fg_color="#3182F6",
            hover_color="#2369CD",
        )
        self.start_btn.grid(row=1, column=2, pady=(12, 0))

        log_frame = ctk.CTkFrame(body, fg_color="#FFFFFF", corner_radius=12)
        log_frame.grid(row=3, column=0, sticky="nsew", padx=20, pady=(8, 20))
        log_frame.grid_columnconfigure(0, weight=1)
        log_frame.grid_rowconfigure(1, weight=1)

        ctk.CTkLabel(log_frame, text="진행 로그", font=ctk.CTkFont(size=15, weight="bold")).grid(
            row=0, column=0, sticky="w", padx=14, pady=(12, 6)
        )

        self.log_box = ctk.CTkTextbox(log_frame, font=("Consolas", 12), corner_radius=8)
        self.log_box.grid(row=1, column=0, sticky="nsew", padx=12, pady=(0, 12))

    def pick_output_dir(self):
        selected = fd.askdirectory()
        if selected:
            self.output_entry.delete(0, "end")
            self.output_entry.insert(0, selected)

    def _append_log(self, message: str):
        self.log_box.insert("end", message + "\n")
        self.log_box.see("end")

    def _drain_log_queue(self):
        while not self.log_queue.empty():
            self._append_log(self.log_queue.get_nowait())
        self.after(120, self._drain_log_queue)

    def _validate(self) -> DownloadJob | None:
        raw = self.urls_input.get("1.0", "end").strip()
        urls = [line.strip() for line in raw.splitlines() if line.strip().startswith("http")]
        if not urls:
            self.log_queue.put("❌ URL을 하나 이상 입력하세요.")
            return None

        output_dir = Path(self.output_entry.get().strip())
        output_dir.mkdir(parents=True, exist_ok=True)
        mode = self.mode_var.get()
        return DownloadJob(urls=urls, output_dir=output_dir, mode=mode)

    def start_download(self):
        if self.worker_thread and self.worker_thread.is_alive():
            self.log_queue.put("⚠️ 이미 다운로드가 진행 중입니다.")
            return

        job = self._validate()
        if not job:
            return

        self.start_btn.configure(state="disabled", text="다운로드 중...")
        self.log_queue.put(f"🚀 작업 시작: 링크 {len(job.urls)}개")
        self.worker_thread = threading.Thread(target=self._download_worker, args=(job,), daemon=True)
        self.worker_thread.start()

    def _download_worker(self, job: DownloadJob):
        ffmpeg_path = imageio_ffmpeg.get_ffmpeg_exe()
        self.log_queue.put(f"ℹ️ FFmpeg 사용: {ffmpeg_path}")

        def hook(d):
            status = d.get("status")
            if status == "downloading":
                filename = os.path.basename(d.get("filename", ""))
                percent = d.get("_percent_str", "").strip()
                speed = d.get("_speed_str", "")
                self.log_queue.put(f"⬇️ {filename} {percent} {speed}")
            elif status == "finished":
                self.log_queue.put("✅ 파일 다운로드 완료, 후처리 진행 중")

        options = {
            "ffmpeg_location": ffmpeg_path,
            "ignoreerrors": True,
            "noplaylist": False,
            "outtmpl": str(job.output_dir / "%(title)s.%(ext)s"),
            "progress_hooks": [hook],
            "quiet": True,
            "no_warnings": True,
        }

        if job.mode == "audio":
            options.update(
                {
                    "format": "bestaudio/best",
                    "postprocessors": [
                        {
                            "key": "FFmpegExtractAudio",
                            "preferredcodec": "mp3",
                            "preferredquality": "192",
                        }
                    ],
                }
            )
        else:
            options.update({"format": "bv*+ba/b"})

        try:
            with yt_dlp.YoutubeDL(options) as ydl:
                for url in job.urls:
                    self.log_queue.put(f"🔎 분석: {url}")
                    ydl.download([url])
            self.log_queue.put("🎉 모든 다운로드가 완료되었습니다.")
        except Exception as exc:  # noqa: BLE001
            self.log_queue.put(f"❌ 오류 발생: {exc}")
        finally:
            self.after(0, lambda: self.start_btn.configure(state="normal", text="다운로드 시작"))


if __name__ == "__main__":
    app = YTDLPApp()
    app.mainloop()
