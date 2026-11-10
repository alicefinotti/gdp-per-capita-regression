# GDP per Capita: Econometric Analysis

## Overview

An econometric study of the relationship between **GDP per capita** and economic and institutional indicators using World Bank country-year data. The analysis compares pooled ordinary least squares (OLS) models and examines how additional predictors affect model fit and statistical diagnostics.

## Methodology

- **Data preparation:** Reshape and merge six World Bank indicators; exclude regional and income-group aggregates; apply logarithmic transformations where appropriate.
- **Baseline regression:** Regress log GDP per capita on log gross savings and log population growth.
- **Model diagnostics:** Compare seven specifications incorporating R&D expenditure, government education spending, and the rule-of-law indicator.
- **Extended specifications:** Examine adjusted R², coefficient significance, residual distributions, heteroscedasticity, and high-leverage observations.

## Key Findings

- The baseline regression reported an **adjusted R² of 0.309**, improving to **0.340** after filtering high-leverage observations.
- Adding **R&D expenditure and rule of law** to the baseline predictors increased adjusted R² to approximately **0.697**. Both indicators were positively associated with GDP per capita.
_ Specifications including education spending reached higher adjusted R² values (up to approximately **0.730**), but the education coefficient was not statistically significant in the highest-fitting models.

**Data source:** [World Bank Open Data](https://data.worldbank.org/).
