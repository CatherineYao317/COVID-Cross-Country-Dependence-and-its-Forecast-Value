"""Figure generation module for RQ2 forecast evaluation.

This module provides functions for merging hhh4 endemic-epidemic model results
(exported from R) with the benchmark/VAR comparison table produced by
``CS3_RQ2_analysis.ipynb``, and for generating the two RQ2 figures used in
the executive report:

- **fig5_rmse_comparison.png** — daily-scale RMSE: selected benchmark vs VAR(2) vs VAR(3)
- **fig6_hhh4_comparison.png** — weekly-scale RMSE: hhh4 within-country vs hhh4 full

Intended usage (from ``CS3_RQ2_analysis.ipynb``):

    >>> from generate_rq2_figures import load_hhh4_results, merge_with_benchmark
    >>> from generate_rq2_figures import plot_rmse_comparison, plot_hhh4_comparison
    >>> hhh4_compare = load_hhh4_results("RQ2_hhh4/CS3RQ2_hhh4/hhh4_exports/")
    >>> combined = merge_with_benchmark(comparison_all, hhh4_compare)
    >>> combined.to_csv("comparison_with_hhh4.csv", index=False)
    >>> plot_rmse_comparison(combined)
    >>> plot_hhh4_comparison(hhh4_compare)
"""

import os

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

# Ensure the output directory exists regardless of where this module is imported from
os.makedirs("../Results/Figures", exist_ok=True)


def load_hhh4_results(hhh4_exports_dir: str) -> pd.DataFrame:
    """Load and reshape hhh4 forecast summary from R-exported CSVs.

    Reads ``hhh4_summary_by_country.csv`` from the given directory, pivots it
    from long to wide format so that each row is one country, and adds derived
    columns for RMSE/MAE gain (full model minus within-country model) and a
    boolean flag indicating which model performs better.

    Args:
        hhh4_exports_dir: Path to the folder containing hhh4 export CSVs,
            e.g. ``"RQ2_hhh4/CS3RQ2_hhh4/hhh4_exports/"``.

    Returns:
        A DataFrame with one row per country and columns:
        ``country``, ``hhh4_within_rmse``, ``hhh4_full_rmse``,
        ``hhh4_within_mae``, ``hhh4_full_mae``,
        ``hhh4_rmse_gain_full_vs_within`` (positive = full model is better),
        ``hhh4_full_beats_within_rmse`` (bool),
        ``hhh4_full_beats_within_mae`` (bool).
    """
    summary = pd.read_csv(f"{hhh4_exports_dir}/hhh4_summary_by_country.csv")

    # Pivot RMSE, MAE, and forecast count from long to wide
    rmse_wide = (
        summary.pivot(index="country", columns="model", values="rmse")
        .reset_index()
        .rename(columns={"hhh4_within": "hhh4_within_rmse", "hhh4_full": "hhh4_full_rmse"})
    )
    mae_wide = (
        summary.pivot(index="country", columns="model", values="mae")
        .reset_index()
        .rename(columns={"hhh4_within": "hhh4_within_mae", "hhh4_full": "hhh4_full_mae"})
    )
    n_wide = (
        summary.pivot(index="country", columns="model", values="n_forecasts")
        .reset_index()
        .rename(columns={
            "hhh4_within": "hhh4_within_n_forecasts",
            "hhh4_full": "hhh4_full_n_forecasts",
        })
    )

    compare = (
        rmse_wide
        .merge(mae_wide, on="country", how="inner")
        .merge(n_wide, on="country", how="inner")
    )

    # Positive gain means the full (spillover) model has lower error than within-country
    compare["hhh4_rmse_gain_full_vs_within"] = (
        compare["hhh4_within_rmse"] - compare["hhh4_full_rmse"]
    )
    compare["hhh4_mae_gain_full_vs_within"] = (
        compare["hhh4_within_mae"] - compare["hhh4_full_mae"]
    )
    compare["hhh4_full_beats_within_rmse"] = (
        compare["hhh4_full_rmse"] < compare["hhh4_within_rmse"]
    )
    compare["hhh4_full_beats_within_mae"] = (
        compare["hhh4_full_mae"] < compare["hhh4_within_mae"]
    )

    return compare


def merge_with_benchmark(
    comparison_all: pd.DataFrame,
    hhh4_compare: pd.DataFrame,
) -> pd.DataFrame:
    """Merge the benchmark/VAR RMSE table with hhh4 results.

    Performs a left join on ``country`` so that every country in the
    benchmark table retains its row even if hhh4 results are unavailable.

    Args:
        comparison_all: DataFrame produced by ``CS3_RQ2_analysis.ipynb``
            containing per-country RMSE/MAE for the selected benchmark model,
            VAR(2), and VAR(3).  Must contain a ``country`` column.
        hhh4_compare: DataFrame returned by :func:`load_hhh4_results`.

    Returns:
        Wide DataFrame with one row per country containing benchmark, VAR,
        and hhh4 metrics side by side.  Saved to ``comparison_with_hhh4.csv``
        by the caller.
    """
    return comparison_all.merge(hhh4_compare, on="country", how="left")


def plot_rmse_comparison(
    comparison_with_hhh4: pd.DataFrame,
    out_path: str = "../Results/Figures/fig5_rmse_comparison.png",
    dpi: int = 300,
) -> None:
    """Plot daily-scale RMSE: selected benchmark vs VAR(2) vs VAR(3).

    Generates a grouped bar chart comparing one-step-ahead expanding-window
    RMSE across three model families for all seven countries.  The selected
    benchmark is either SARIMA or ETS depending on which performed better
    per country.

    Args:
        comparison_with_hhh4: Combined comparison DataFrame from
            :func:`merge_with_benchmark`.  Must contain columns
            ``country``, ``benchmark_rmse``, ``var2_rmse``, ``var3_rmse``.
        out_path: File path for the saved PNG.
        dpi: Output resolution in dots per inch.
    """
    df = comparison_with_hhh4.sort_values("country").copy()
    x = np.arange(len(df))
    width = 0.25

    fig, ax = plt.subplots(figsize=(12, 5))
    ax.bar(x - width, df["benchmark_rmse"], width=width, label="Selected benchmark (SARIMA or ETS)")
    ax.bar(x,          df["var2_rmse"],      width=width, label="VAR(2)")
    ax.bar(x + width,  df["var3_rmse"],      width=width, label="VAR(3)")

    ax.set_xticks(x)
    ax.set_xticklabels(df["country"], rotation=45, ha="right")
    ax.set_ylabel("RMSE (one-step-ahead, expanding window)")
    ax.set_title("Daily-scale forecast comparison: benchmark vs VAR(2) vs VAR(3)")
    ax.legend()
    fig.tight_layout()
    fig.savefig(out_path, dpi=dpi, bbox_inches="tight")
    plt.show()


def plot_hhh4_comparison(
    hhh4_compare: pd.DataFrame,
    out_path: str = "../Results/Figures/fig6_hhh4_comparison.png",
    dpi: int = 300,
) -> None:
    """Plot weekly-scale RMSE: hhh4 within-country vs hhh4 full spillover model.

    Generates a paired bar chart comparing the endemic-epidemic (hhh4) model
    in two specifications: (1) within-country only (no cross-border influence)
    and (2) full model with equal-weight cross-country spillover.  Near-identical
    bars indicate that the spillover component adds no forecast value.

    Args:
        hhh4_compare: DataFrame returned by :func:`load_hhh4_results`.
            Must contain columns ``country``, ``hhh4_within_rmse``,
            ``hhh4_full_rmse``.
        out_path: File path for the saved PNG.
        dpi: Output resolution in dots per inch.
    """
    df = hhh4_compare.sort_values("country").copy()
    x = np.arange(len(df))
    width = 0.35

    fig, ax = plt.subplots(figsize=(12, 5))
    ax.bar(x - width / 2, df["hhh4_within_rmse"], width=width, label="hhh4 within-country")
    ax.bar(x + width / 2, df["hhh4_full_rmse"],   width=width, label="hhh4 full (spillover)")

    ax.set_xticks(x)
    ax.set_xticklabels(df["country"], rotation=45, ha="right")
    ax.set_ylabel("RMSE (weekly, 28 forecast origins)")
    ax.set_title("Weekly-scale robustness: hhh4 within-country vs hhh4 full spillover")
    ax.legend()
    fig.tight_layout()
    fig.savefig(out_path, dpi=dpi, bbox_inches="tight")
    plt.show()
