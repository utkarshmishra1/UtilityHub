#!/usr/bin/env python3
"""
Download and read BSE corporate filing PDFs for India-listed equities.

Source endpoints used:
- https://api.bseindia.com/BseIndiaAPI/api/ListofScripData/w
- https://api.bseindia.com/BseIndiaAPI/api/AnnSubCategoryGetData/w
"""

from __future__ import annotations

import argparse
import csv
import json
import random
import re
import sys
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, Iterable, List, Optional, Tuple

import requests

try:
    from pypdf import PdfReader

    HAS_PYPDF = True
except Exception:
    HAS_PYPDF = False


BASE_API = "https://api.bseindia.com/BseIndiaAPI/api"
BASE_SITE = "https://www.bseindia.com"
LIST_SCRIPS_REFERRER = f"{BASE_SITE}/corporates/List_Scrips.html"
ANNOUNCEMENTS_REFERRER = f"{BASE_SITE}/corporates/ann.html"
DEFAULT_USER_AGENT = (
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
    "AppleWebKit/537.36 (KHTML, like Gecko) "
    "Chrome/123.0.0.0 Safari/537.36"
)


def safe_filename(value: str, max_len: int = 160) -> str:
    value = value.strip().replace("/", "_")
    value = re.sub(r"[^a-zA-Z0-9._ -]", "", value)
    value = re.sub(r"\s+", "_", value)
    return value[:max_len] if len(value) > max_len else value


def parse_year_month(news_dt: str) -> Tuple[str, str]:
    # format: 2026-03-18T23:34:25.913
    parts = news_dt.split("-")
    year = parts[0]
    month = str(int(parts[1]))  # remove leading zeros: 03 -> 3
    return year, month


@dataclass
class BseClient:
    session: requests.Session
    min_sleep: float
    max_sleep: float
    timeout: int
    retries: int
    backoff: float

    @staticmethod
    def create(
        user_agent: str = DEFAULT_USER_AGENT,
        min_sleep: float = 0.05,
        max_sleep: float = 0.15,
        timeout: int = 30,
        retries: int = 4,
        backoff: float = 1.5,
    ) -> "BseClient":
        s = requests.Session()
        s.headers.update(
            {
                "User-Agent": user_agent,
                "Accept": "application/json,text/plain,*/*",
                "Accept-Language": "en-US,en;q=0.9",
                "Connection": "keep-alive",
            }
        )
        return BseClient(
            session=s,
            min_sleep=min_sleep,
            max_sleep=max_sleep,
            timeout=timeout,
            retries=retries,
            backoff=backoff,
        )

    def _sleep(self) -> None:
        if self.max_sleep <= 0:
            return
        time.sleep(random.uniform(self.min_sleep, self.max_sleep))

    def _get_json(self, url: str, params: Dict[str, str], referer: str) -> object:
        last_err: Optional[Exception] = None
        for attempt in range(1, self.retries + 1):
            try:
                resp = self.session.get(
                    url,
                    params=params,
                    headers={"Referer": referer},
                    timeout=self.timeout,
                )
                if resp.status_code == 200:
                    self._sleep()
                    return resp.json()
                if resp.status_code in (429, 500, 502, 503, 504):
                    wait = self.backoff ** attempt
                    time.sleep(wait)
                    continue
                raise RuntimeError(
                    f"Unexpected status {resp.status_code} for {url} params={params}"
                )
            except Exception as err:
                last_err = err
                wait = self.backoff ** attempt
                time.sleep(wait)
        raise RuntimeError(f"Failed request after retries: {url} ({last_err})")

    def _download_file(
        self, url: str, out_path: Path, referer: str, skip_if_exists: bool = True
    ) -> bool:
        if skip_if_exists and out_path.exists() and out_path.stat().st_size > 0:
            return False

        out_path.parent.mkdir(parents=True, exist_ok=True)
        last_err: Optional[Exception] = None
        for attempt in range(1, self.retries + 1):
            try:
                resp = self.session.get(
                    url,
                    headers={"Referer": referer, "Accept": "*/*"},
                    timeout=self.timeout,
                    stream=True,
                )
                if resp.status_code == 200:
                    with out_path.open("wb") as f:
                        for chunk in resp.iter_content(chunk_size=64 * 1024):
                            if chunk:
                                f.write(chunk)
                    self._sleep()
                    return True
                if resp.status_code in (429, 500, 502, 503, 504):
                    wait = self.backoff ** attempt
                    time.sleep(wait)
                    continue
                raise RuntimeError(
                    f"Unexpected status {resp.status_code} when downloading {url}"
                )
            except Exception as err:
                last_err = err
                wait = self.backoff ** attempt
                time.sleep(wait)
        raise RuntimeError(f"Failed download after retries: {url} ({last_err})")

    def list_scrips(self, segment: str = "Equity", status: str = "Active") -> List[dict]:
        url = f"{BASE_API}/ListofScripData/w"
        payload = self._get_json(
            url=url,
            params={"segment": segment, "status": status, "Group": "", "Scripcode": ""},
            referer=LIST_SCRIPS_REFERRER,
        )
        if not isinstance(payload, list):
            raise RuntimeError("Expected a list response for ListofScripData")
        return payload

    def fetch_announcement_page(
        self, scrip_code: str, page: int
    ) -> Tuple[List[dict], int]:
        url = f"{BASE_API}/AnnSubCategoryGetData/w"
        payload = self._get_json(
            url=url,
            params={
                "strScrip": str(scrip_code),
                "strCat": "-1",
                "strPrevDate": "",
                "strToDate": "",
                "strSearch": "A",
                "strType": "C",
                "pageno": str(page),
                "subcategory": "-1",
            },
            referer=f"{ANNOUNCEMENTS_REFERRER}?scrip={scrip_code}&dur=A",
        )
        if not isinstance(payload, dict):
            return [], 0
        table = payload.get("Table") or []
        rowcnt = 0
        table1 = payload.get("Table1") or []
        if table1 and isinstance(table1[0], dict):
            rowcnt = int(table1[0].get("ROWCNT") or 0)
        return table, rowcnt


def iter_stock_announcements(
    client: BseClient,
    scrip_code: str,
    max_pages_per_stock: Optional[int] = None,
) -> Iterable[dict]:
    page = 1
    total_rows = None
    per_page = 50
    while True:
        if max_pages_per_stock is not None and page > max_pages_per_stock:
            return
        rows, rowcnt = client.fetch_announcement_page(scrip_code=scrip_code, page=page)
        if total_rows is None:
            total_rows = rowcnt
        if not rows:
            return
        for row in rows:
            yield row
        if len(rows) < per_page:
            return
        if total_rows is not None and page * per_page >= total_rows:
            return
        page += 1


def announcement_pdf_url(announcement: dict) -> Optional[str]:
    name = str(announcement.get("ATTACHMENTNAME") or "").strip()
    news_dt = str(announcement.get("NEWS_DT") or "").strip()
    if not name or not news_dt:
        return None
    year, month = parse_year_month(news_dt)
    return f"{BASE_SITE}/xml-data/corpfiling/CorpAttachment/{year}/{month}/{name}"


def extract_pdf_text(pdf_path: Path) -> str:
    if not HAS_PYPDF:
        raise RuntimeError(
            "Text extraction requires pypdf. Install with: pip install pypdf"
        )
    reader = PdfReader(str(pdf_path))
    text_chunks: List[str] = []
    for page in reader.pages:
        text_chunks.append(page.extract_text() or "")
    return "\n".join(text_chunks).strip()


def write_jsonl(path: Path, rows: Iterable[dict]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as f:
        for row in rows:
            f.write(json.dumps(row, ensure_ascii=False) + "\n")


def write_csv(path: Path, rows: List[dict]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if not rows:
        with path.open("w", encoding="utf-8", newline="") as f:
            writer = csv.writer(f)
            writer.writerow([])
        return
    fieldnames = sorted(set().union(*(r.keys() for r in rows)))
    with path.open("w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames, extrasaction="ignore")
        writer.writeheader()
        writer.writerows(rows)


def run(args: argparse.Namespace) -> int:
    out_dir = Path(args.output_dir).resolve()
    out_dir.mkdir(parents=True, exist_ok=True)

    client = BseClient.create(
        min_sleep=args.min_sleep,
        max_sleep=args.max_sleep,
        timeout=args.timeout,
        retries=args.retries,
        backoff=args.backoff,
    )

    scrips = client.list_scrips(segment="Equity", status="Active")
    scrips.sort(key=lambda x: int(x.get("SCRIP_CD") or 0))

    if args.max_stocks is not None:
        scrips = scrips[: args.max_stocks]

    metadata_rows: List[dict] = []
    downloaded = 0
    extracted = 0
    failures = 0

    print(f"Loaded {len(scrips)} active equity stocks from BSE.")

    stock_docs_index: Dict[str, int] = {}
    for idx, scrip in enumerate(scrips, start=1):
        scrip_code = str(scrip.get("SCRIP_CD") or "").strip()
        stock_name = str(scrip.get("Scrip_Name") or scrip_code).strip()
        if not scrip_code:
            continue

        print(f"[{idx}/{len(scrips)}] {scrip_code} {stock_name}")

        docs_for_stock = 0
        try:
            for ann in iter_stock_announcements(
                client=client,
                scrip_code=scrip_code,
                max_pages_per_stock=args.max_pages_per_stock,
            ):
                if args.max_docs_per_stock is not None and docs_for_stock >= args.max_docs_per_stock:
                    break

                pdf_url = announcement_pdf_url(ann)
                if not pdf_url:
                    continue

                news_id = str(ann.get("NEWSID") or "").strip()
                news_dt = str(ann.get("NEWS_DT") or "").strip()
                headline = str(ann.get("HEADLINE") or ann.get("NEWSSUB") or "").strip()
                attachment = str(ann.get("ATTACHMENTNAME") or "").strip()

                stock_folder = out_dir / "pdfs" / f"{scrip_code}_{safe_filename(stock_name)}"
                pdf_path = stock_folder / f"{news_id}_{attachment}"
                if not attachment.lower().endswith(".pdf"):
                    pdf_path = pdf_path.with_suffix(".pdf")

                text_rel_path = None
                pdf_rel_path = str(pdf_path.relative_to(out_dir))

                try:
                    if client._download_file(
                        url=pdf_url,
                        out_path=pdf_path,
                        referer=f"{ANNOUNCEMENTS_REFERRER}?scrip={scrip_code}&dur=A",
                        skip_if_exists=not args.redownload,
                    ):
                        downloaded += 1
                except Exception as err:
                    failures += 1
                    print(f"  ! download failed {news_id}: {err}", file=sys.stderr)
                    continue

                if args.extract_text:
                    text_folder = out_dir / "texts" / f"{scrip_code}_{safe_filename(stock_name)}"
                    text_path = text_folder / (pdf_path.stem + ".txt")
                    text_rel_path = str(text_path.relative_to(out_dir))
                    if args.reextract or not text_path.exists():
                        try:
                            text = extract_pdf_text(pdf_path)
                            text_path.parent.mkdir(parents=True, exist_ok=True)
                            text_path.write_text(text, encoding="utf-8")
                            extracted += 1
                        except Exception as err:
                            failures += 1
                            print(f"  ! text extraction failed {news_id}: {err}", file=sys.stderr)

                metadata = {
                    "scrip_code": scrip_code,
                    "stock_name": stock_name,
                    "news_id": news_id,
                    "news_datetime": news_dt,
                    "headline": headline,
                    "category": ann.get("CATEGORYNAME"),
                    "sub_category": ann.get("SUBCATNAME"),
                    "attachment_name": attachment,
                    "pdf_url": pdf_url,
                    "pdf_path": pdf_rel_path,
                    "text_path": text_rel_path,
                    "company_url": ann.get("NSURL"),
                }
                metadata_rows.append(metadata)
                docs_for_stock += 1
        except Exception as err:
            failures += 1
            print(f"  ! stock failed {scrip_code}: {err}", file=sys.stderr)
            continue

        stock_docs_index[scrip_code] = docs_for_stock

    metadata_jsonl = out_dir / "metadata" / "announcements.jsonl"
    metadata_csv = out_dir / "metadata" / "announcements.csv"
    stock_counts_json = out_dir / "metadata" / "stock_document_counts.json"

    write_jsonl(metadata_jsonl, metadata_rows)
    write_csv(metadata_csv, metadata_rows)
    stock_counts_json.parent.mkdir(parents=True, exist_ok=True)
    stock_counts_json.write_text(
        json.dumps(stock_docs_index, ensure_ascii=False, indent=2), encoding="utf-8"
    )

    summary = {
        "stocks_processed": len(scrips),
        "documents_indexed": len(metadata_rows),
        "pdfs_downloaded_now": downloaded,
        "texts_extracted_now": extracted,
        "failures": failures,
        "extract_text_enabled": bool(args.extract_text),
        "has_pypdf": HAS_PYPDF,
        "output_dir": str(out_dir),
        "metadata_jsonl": str(metadata_jsonl),
        "metadata_csv": str(metadata_csv),
    }
    summary_path = out_dir / "metadata" / "run_summary.json"
    summary_path.write_text(json.dumps(summary, indent=2), encoding="utf-8")

    print("\nRun complete.")
    print(json.dumps(summary, indent=2))
    return 0


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        description="Read BSE corporate filing documents for India-listed equities."
    )
    p.add_argument(
        "--output-dir",
        default="stock_docs_india",
        help="Output directory for PDFs, text, and metadata.",
    )
    p.add_argument(
        "--max-stocks",
        type=int,
        default=None,
        help="Limit number of stocks (useful for test runs).",
    )
    p.add_argument(
        "--max-pages-per-stock",
        type=int,
        default=None,
        help="Limit announcement pages per stock (50 rows/page).",
    )
    p.add_argument(
        "--max-docs-per-stock",
        type=int,
        default=None,
        help="Limit documents per stock (applied while iterating announcements).",
    )
    p.add_argument(
        "--extract-text",
        action="store_true",
        help="Extract text from downloaded PDFs using pypdf.",
    )
    p.add_argument(
        "--redownload",
        action="store_true",
        help="Re-download PDFs even if they already exist.",
    )
    p.add_argument(
        "--reextract",
        action="store_true",
        help="Re-extract text files even if text files already exist.",
    )
    p.add_argument("--timeout", type=int, default=30, help="HTTP timeout in seconds.")
    p.add_argument("--retries", type=int, default=4, help="Retries per request.")
    p.add_argument("--backoff", type=float, default=1.5, help="Exponential backoff base.")
    p.add_argument("--min-sleep", type=float, default=0.05, help="Min jitter sleep between requests.")
    p.add_argument("--max-sleep", type=float, default=0.15, help="Max jitter sleep between requests.")
    return p


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    return run(args)


if __name__ == "__main__":
    raise SystemExit(main())
