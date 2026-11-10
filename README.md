# GDP per Capita: Econometric Analysis

**R | Econometrics | OLS Regression**

## Overview

An econometric study of the relationship between **GDP per capita** and economic and institutional indicators across countries, using annual data from the World Bank. The analysis compares baseline and expanded ordinary least squares (OLS) specifications, examines influential observations, and evaluates model assumptions.

## Methodology

- **Data preparation:** Reshape and merge six World Bank indicators into a country–year dataset, excluding regional and income-group aggregates.
- **Baseline regression:** Model log GDP per capita using log gross savings and log population growth.
- **Model diagnostics:** Examine residual normality, linearity, heteroscedasticity, and high-leverage observations; compare regression fit after filtering.
- **Extended specifications:** Evaluate seven combinations of R&D expenditure, education expenditure, and rule of law, using coefficient significance and adjusted R².

## Key Findings

- The baseline regression reported an **adjusted R² of 0.309**, improving to **0.340** after filtering high-leverage observations.
- Institutional quality, measured by the **rule-of-law indicator**, was strongly associated with GDP per capita in the expanded models.
- The specification including **R&D expenditure and rule of law** alongside the baseline predictors achieved an adjusted R² of approximately **0.697** in the original analysis. Higher-fitting specifications also included education spending, but its coefficient was not statistically significant in those models.
- Residual diagnostics indicated remaining departures from ideal OLS assumptions, particularly heteroscedasticity and tail behavior.

These results describe associations, not causal effects. Log transformations also exclude observations with nonpositive values, including years of zero or negative population growth. Comparisons across model specifications may involve different samples because of missing data.

## Repository Contents

- `gdp_regression_analysis.R` — Data preparation, OLS specifications, model comparisons, and diagnostics.
- `data/` — Six World Bank indicator datasets (`.xls` / `.xlsx`).

## Running the Analysis

Install **R** and the `data.table` and `readxl` packages, then run from the repository directory:

```r
install.packages(c("data.table", "readxl"))
source("gdp_regression_analysis.R")
```

The script prints regression summaries and saves the model-comparison table and diagnostic figures to `outputs/`.

**Data source:** [World Bank Open Data](https://data.worldbank.org/).
