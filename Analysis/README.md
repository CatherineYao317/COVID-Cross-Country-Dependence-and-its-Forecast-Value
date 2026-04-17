# Analysis

This folder contains all statistical analysis scripts and notebooks for the project.

## File Overview

| File | Type | Role | Input | Output |
|------|------|------|-------|--------|
| `case_study_3_RQ1_analysis.qmd` | Quarto/R | **RQ1 analysis** — dependence patterns: CCF, rolling correlations, VAR, PCA, sentinel scoring | `../Data/AllNationsCombined.csv` | `../Results/Figures/fig1–fig4` |
| `CS3_RQ2_analysis.ipynb` | Jupyter/Python | **RQ2 analysis** — SARIMA/ETS grid search, expanding-window forecast evaluation, VAR evaluation, figure generation | `../Data/AllNationsCombined.csv`, `RQ2_hhh4/CS3RQ2_hhh4/hhh4_exports/*.csv` | `../Results/Figures/fig5–fig6`, `comparison_with_hhh4.csv` |
| `generate_rq2_figures.py` | Python module | Standalone module with documented functions for RQ2 figure generation and hhh4 result reshaping. Can be imported and called independently of the notebook. | hhh4 export CSVs, RMSE comparison DataFrame | `../Results/Figures/fig5_rmse_comparison.png`, `fig6_hhh4_comparison.png` |
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

All model outputs are committed as **verifiable proof that each script ran successfully end-to-end**:

- `case_study_3_RQ1_analysis.pdf` — rendered PDF of the full RQ1 Quarto document, proving `case_study_3_RQ1_analysis.qmd` executed without error
- `CS3_RQ2_analysis.ipynb` — committed **with all cell outputs retained**, proving the notebook ran end-to-end and all figures, tables, and scalar results are reproducible from the committed code

The figures and CSVs below are the outputs consumed by the executive report:

- `../Results/Figures/fig1_series.png` — standardized 7-day MA log per-capita series (RQ1)
- `../Results/Figures/fig2_heatmap.png` — pairwise full-sample correlation heatmap (RQ1)
- `../Results/Figures/fig3_rolling_corr.png` — 60-day rolling pairwise correlations (RQ1)
- `../Results/Figures/fig4_sentinel.png` — sentinel score bar chart (RQ1)
- `../Results/Figures/fig5_rmse_comparison.png` — expanding-window RMSE: benchmark vs VAR(2) vs VAR(3) (RQ2)
- `../Results/Figures/fig6_hhh4_comparison.png` — weekly RMSE: hhh4 within vs hhh4 full (RQ2)
- `comparison_with_hhh4.csv` — combined RMSE/MAE table used for inline scalars in the executive report
- `RQ2_hhh4/CS3RQ2_hhh4/hhh4_exports/hhh4_forecasts_long.csv` — long-format OSA forecasts for both hhh4 specifications
- `RQ2_hhh4/CS3RQ2_hhh4/hhh4_exports/hhh4_summary_by_country.csv` — per-country RMSE/MAE
- `RQ2_hhh4/CS3RQ2_hhh4/hhh4_exports/hhh4_summary_overall.csv` — panel-wide RMSE/MAE
- `RQ2_hhh4/CS3RQ2_hhh4/hhh4_exports/hhh4_metadata.csv` — run settings (n_weeks, initial_train_weeks)
