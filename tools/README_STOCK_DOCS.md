# India Stock Documents Reader

This script pulls listed equity stocks from BSE, fetches corporate filing records for each stock, downloads PDF attachments, and can extract text from each PDF.

## File

- `/Users/utkarshmishra/Desktop/Learn_SwiftUI/UtilityHub/tools/india_stock_docs_reader.py`

## Data Sources

- `https://api.bseindia.com/BseIndiaAPI/api/ListofScripData/w`
- `https://api.bseindia.com/BseIndiaAPI/api/AnnSubCategoryGetData/w`
- `https://www.bseindia.com/xml-data/corpfiling/CorpAttachment/{year}/{month}/{attachment}.pdf`

## Setup

```bash
cd /Users/utkarshmishra/Desktop/Learn_SwiftUI/UtilityHub
python3 -m pip install requests pypdf
```

## Quick Test

```bash
python3 tools/india_stock_docs_reader.py \
  --output-dir stock_docs_india \
  --max-stocks 3 \
  --max-pages-per-stock 1 \
  --max-docs-per-stock 5 \
  --extract-text
```

## Full Run (All Active Equity Stocks)

Warning: this can take many hours and large disk space.

```bash
python3 tools/india_stock_docs_reader.py \
  --output-dir stock_docs_india \
  --extract-text
```

## Output

- `stock_docs_india/pdfs/...` downloaded PDFs
- `stock_docs_india/texts/...` extracted text files
- `stock_docs_india/metadata/announcements.jsonl`
- `stock_docs_india/metadata/announcements.csv`
- `stock_docs_india/metadata/stock_document_counts.json`
- `stock_docs_india/metadata/run_summary.json`
