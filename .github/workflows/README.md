# GitHub Actions Workflows

## What runs in CI

| Workflow | Trigger | What it does |
|----------|---------|--------------|
| `render-report.yml` | Push / PR to `main` | Renders `executive_report.qmd` → PDF and uploads as a downloadable artifact |

## What does NOT run in CI — and why

All statistical models are run **locally** and their outputs are committed to the repository. The CI workflow only renders the final report from those pre-committed outputs.

| Analysis | Why not in CI | Pre-committed output |
|----------|--------------|----------------------|
| RQ1: CCF, rolling correlations, VAR, PCA (`Analysis/case_study_3_RQ1_analysis.qmd`) | R packages take several minutes to install + computation adds ~10 min; feasible but unnecessary since outputs are stable | `Results/Figures/fig1_series.png` – `fig4_sentinel.png`, `Results/case_study_3_RQ1_analysis.pdf` |
| RQ2: SARIMA grid search + expanding-window evaluation (`Analysis/CS3_RQ2_analysis.ipynb`) | SARIMA grid search (144 combinations × 7 countries) + expanding-window refit (~1183 origins) takes **60–120 minutes** — not viable in CI | `Results/Figures/fig5_rmse_comparison.png`, `Analysis/comparison_with_hhh4.csv`, notebook committed with all cell outputs |
| RQ2: hhh4 endemic-epidemic model (`Analysis/RQ2_hhh4/CS3RQ2_hhh4/CS3_RQ2_hhh4.r`) | Requires the `surveillance` R package and fitting over 28 weekly forecast origins; runtime ~15–30 min | `Analysis/RQ2_hhh4/CS3RQ2_hhh4/hhh4_exports/*.csv`, `Results/Figures/fig6_hhh4_comparison.png` |

## How the executive report uses pre-committed outputs

`executive_report.qmd` reads figures directly from `Results/Figures/` using `include_graphics()` and reads scalar results from `Analysis/comparison_with_hhh4.csv`. No model fitting happens at render time, so the CI render is fast (<5 minutes total including R package installation).

## Reproducing the analysis locally

See the root `README.md` for step-by-step instructions on running each component locally.
