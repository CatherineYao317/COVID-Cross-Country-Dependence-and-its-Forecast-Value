# Analysis

This folder contains all statistical analysis scripts and notebooks for the project.

## File Overview

| File | Type | Role | Input | Output |
|------|------|------|-------|--------|
| `case_study_3_RQ1_analysis.qmd` | Quarto/R | **RQ1 analysis** — dependence patterns: CCF, rolling correlations, VAR, PCA, sentinel scoring | `../Data/AllNationsCombined.csv` | `../Results/Figures/fig1–fig4`, `../Results/case_study_3_RQ1_analysis.pdf` |
| `CS3_RQ2_analysis.ipynb` | Jupyter/Python | **RQ2 analysis** — SARIMA/ETS grid search, expanding-window forecast evaluation, VAR evaluation, figure generation | `../Data/AllNationsCombined.csv`, `RQ2_hhh4/CS3RQ2_hhh4/hhh4_exports/*.csv` | `../Results/Figures/fig5–fig6`, `comparison_with_hhh4.csv` |
| `generate_rq2_figures.py` | Python module | Figure generation functions called by `CS3_RQ2_analysis.ipynb` | hhh4 export CSVs, RMSE comparison data | `../Results/Figures/fig5_rmse_comparison.png`, `fig6_hhh4_comparison.png` |
| `comparison_with_hhh4.csv` | CSV | Pre-computed RMSE comparison table (VAR vs benchmark vs hhh4) | — | Used by `executive_report.qmd` for inline scalars |
| `RQ2_hhh4/CS3RQ2_hhh4/CS3_RQ2_hhh4.r` | R script | **hhh4 endemic-epidemic model** — fits within-country and full spillover specifications, exports forecast results | `../../../Data/AllNationsCombined.csv` | `RQ2_hhh4/CS3RQ2_hhh4/hhh4_exports/*.csv` |

## Run Order

If reproducing from scratch, run in this order:

```
1. case_study_3_RQ1_analysis.qmd   (quarto render)
2. RQ2_hhh4/.../CS3_RQ2_hhh4.r    (Rscript)
3. CS3_RQ2_analysis.ipynb          (jupyter nbconvert --execute)
4. executive_report.qmd            (quarto render, from repo root)
```

Steps 1–3 can be skipped if using pre-committed outputs. See the root `README.md` for full instructions and runtime estimates.

## Pre-committed Outputs

All model outputs are committed so the executive report can be rendered without re-running the analysis:

- `../Results/Figures/fig1_series.png` — standardized series plot (RQ1)
- `../Results/Figures/fig2_heatmap.png` — pairwise correlation heatmap (RQ1)
- `../Results/Figures/fig3_rolling_corr.png` — rolling correlations (RQ1)
- `../Results/Figures/fig4_sentinel.png` — sentinel score bar chart (RQ1)
- `../Results/Figures/fig5_rmse_comparison.png` — RMSE comparison: benchmark vs VAR (RQ2)
- `../Results/Figures/fig6_hhh4_comparison.png` — hhh4 within vs full model (RQ2)
- `comparison_with_hhh4.csv` — RMSE table used for inline scalars in the report
- `RQ2_hhh4/CS3RQ2_hhh4/hhh4_exports/*.csv` — hhh4 model forecasts and summaries
