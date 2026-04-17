# Data

This folder contains all raw and processed data files used in the analysis.

---

## Primary Analysis Dataset

### `AllNationsCombined.csv`

The single input file consumed by all analysis scripts. It is a fully balanced, aligned daily panel covering **7 countries × 575 days** (2020-01-04 to 2021-07-31), constructed from the per-country raw files below.

| Column | Type | Description |
|--------|------|-------------|
| `date` | Date (YYYY-MM-DD) | Calendar date |
| `country` | String | Country name (Australia, Brazil, Canada, China, South Africa, United Kingdom, United States) |
| `cases` | Integer | Daily confirmed COVID-19 case count |
| `population` | Integer | Country population (used for per-capita scaling) |

Missing values in the raw series were filled by linear interpolation so that the panel is complete with no gaps. The 575-day window is the longest common period over which all seven countries reported continuously.

---

## Per-Country Raw Source Files

These files were downloaded from the [Project Tycho portal](https://www.tycho.pitt.edu/) (WHO source) and are kept for provenance. They are **not read directly by any analysis script** — `AllNationsCombined.csv` is derived from them.

| File | Country | Key Columns |
|------|---------|-------------|
| `Australia.csv` | Australia | `ConditionName`, `CountryName`, `Date`, `CountValue`, `TotalPopulation` |
| `Brazil.csv` | Brazil | same schema |
| `Canada.csv` | Canada | same schema |
| `China.csv` | China | same schema |
| `South Africa.csv` | South Africa | same schema |
| `United Kingdom.csv` | United Kingdom | same schema |
| `US.csv` | United States | same schema |

All raw files share the same Project Tycho schema: one row per country–date, with `CountValue` giving the daily case count and `TotalPopulation` giving the country population.

---

## Auxiliary File

| File | Description |
|------|-------------|
| `US States_Territories.csv` | State-level US case data (Admin1 resolution) from the CDC. Kept for reference but **not used in the analysis** — the national-level `US.csv` is used instead. |
