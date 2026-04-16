# COVID Cross-Country Dependence and Its Forecast Value

**STAT 946 Case Study 3 — Winter 2026**

This project investigates whether cross-country COVID-19 signals improve short-term forecasts beyond country-specific baselines, using a 575-day aligned daily panel of seven countries (Australia, Brazil, Canada, China, South Africa, United Kingdom, United States).

COVID-19 is used as a methodological test bed — not as the primary public-health target. The framework for judging cross-country forecast value transfers directly to influenza, RSV, and future emerging pathogens.

---

## Repository Structure

```
.
├── Analysis/
│   ├── case_study_3_RQ1_analysis.qmd   # RQ1: dependence patterns (R)
│   ├── CS3_RQ2_analysis.ipynb          # RQ2: forecast evaluation (Python)
│   ├── generate_rq2_figures.py         # Module: figure generation for RQ2
│   ├── comparison_with_hhh4.csv        # Pre-computed RQ2 scalar results
│   └── RQ2_hhh4/                       # hhh4 endemic-epidemic model (R)
│       └── CS3RQ2_hhh4/
│           ├── CS3_RQ2_hhh4.r          # hhh4 model script
│           └── hhh4_exports/           # Pre-computed hhh4 results (CSV)
├── Data/
│   ├── AllNationsCombined.csv          # Aligned 7-country daily panel
│   └── *.csv                           # Per-country raw series
├── Results/
│   └── Figures/                        # Pre-generated figures (fig1–fig6)
├── .github/workflows/                  # CI configuration (see workflows/README.md)
├── executive_report.qmd                # Final executive report source
├── executive_report.pdf                # Rendered report (also available as CI artifact)
└── pyproject.toml                      # Python dependency specification
```

---

## Reproducing the Analysis

### Prerequisites

**R** (≥ 4.4) with the following packages:
```r
install.packages(c(
  "tidyverse", "lubridate", "janitor", "zoo", "slider", "scales",
  "patchwork", "GGally", "corrplot", "tsibble", "fable", "feasts",
  "tseries", "forecast", "urca", "vars", "broom", "knitr",
  "kableExtra", "surveillance", "reshape2", "lmtest"
))
```

**Python** (≥ 3.10) via [uv](https://docs.astral.sh/uv/):
```bash
uv sync
```
This installs all pinned Python dependencies from `uv.lock`.

**Quarto** (≥ 1.6): [https://quarto.org/docs/get-started/](https://quarto.org/docs/get-started/)

---

### Step 1 — RQ1 Analysis (R, ~10 min)

Renders the full RQ1 dependence analysis and saves figures to `Results/Figures/`.

```bash
cd Analysis
quarto render case_study_3_RQ1_analysis.qmd --to pdf
```

Output: `Results/Figures/fig1_series.png` through `fig4_sentinel.png`, `Results/case_study_3_RQ1_analysis.pdf`

> Pre-computed outputs are already committed. Re-running this step is optional.

---

### Step 2 — RQ2 hhh4 Model (R, ~15–30 min)

Fits the endemic-epidemic (`hhh4`) model and exports forecast results to CSV.

```bash
cd Analysis/RQ2_hhh4/CS3RQ2_hhh4
Rscript CS3_RQ2_hhh4.r
```

Output: `hhh4_exports/hhh4_forecasts_long.csv`, `hhh4_exports/hhh4_summary_by_country.csv`, etc.

> Pre-computed outputs are already committed. Re-running this step is optional.

---

### Step 3 — RQ2 Python Evaluation (Python, ~60–120 min)

Runs SARIMA/ETS grid search, expanding-window forecast evaluation, VAR evaluation, and generates RQ2 figures.

> **Warning:** The SARIMA expanding-window evaluation (144 combinations × 7 countries × ~169 origins) takes 60–120 minutes. This step cannot run in CI due to runtime constraints.

```bash
cd Analysis
uv run jupyter nbconvert --to notebook --execute CS3_RQ2_analysis.ipynb --output CS3_RQ2_analysis.ipynb
```

Or open the notebook in Jupyter and run all cells:
```bash
uv run jupyter lab
```

Output: `Results/Figures/fig5_rmse_comparison.png`, `Results/Figures/fig6_hhh4_comparison.png`, `Analysis/comparison_with_hhh4.csv`

> The notebook is committed with all cell outputs visible. Pre-computed figures and CSVs are also committed. Re-running is optional but recommended to verify reproducibility.

---

### Step 4 — Executive Report (R + Quarto, ~3 min)

Renders the executive report from pre-committed figures and CSV scalars. No model fitting occurs.

```bash
quarto render executive_report.qmd --to pdf
```

Output: `executive_report.pdf`

> This step also runs automatically on every push to `main` via GitHub Actions, producing a PDF artifact.

---

## CI vs Local Summary

| Component | Runs in CI | Reason |
|-----------|-----------|--------|
| Executive report rendering | Yes (on push) | Lightweight — reads committed figures only |
| RQ1 analysis (R QMD) | No | Runtime feasible but outputs are stable and committed |
| RQ2 SARIMA evaluation (Python) | No | 60–120 min runtime — not viable in CI |
| RQ2 hhh4 model (R) | No | ~15–30 min; outputs committed |

See `.github/workflows/README.md` for full details.

---

## Data

`Data/AllNationsCombined.csv` is the primary analysis dataset: daily COVID-19 case counts for 7 countries from the [Project Tycho portal](https://www.tycho.pitt.edu/) (WHO source), covering January 4, 2020 – July 31, 2021 (575 days, fully balanced after interpolation).

| Column | Description |
|--------|-------------|
| `date` | Date (YYYY-MM-DD) |
| `country` | Country name |
| `cases` | Daily confirmed case count |
| `population` | Country population (used for per-capita scaling) |
