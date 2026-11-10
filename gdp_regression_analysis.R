# GDP per capita: econometric analysis
# Cross-country regression using World Bank economic and institutional indicators.

suppressPackageStartupMessages({
  library(data.table)
  library(readxl)
})

# Read each World Bank export and reshape years into a common country-year panel.
read_indicator <- function(filename, indicator_name) {
  path <- file.path("data", filename)
  raw <- readxl::read_excel(path)
  names(raw) <- trimws(names(raw))

  if (!"Country Name" %in% names(raw)) {
    stop(sprintf("Missing 'Country Name' column in %s", path))
  }
  years <- grep("^(19|20)[0-9]{2}$", names(raw), value = TRUE)
  if (length(years) == 0L) {
    stop(sprintf("No year columns found in %s", path))
  }

  dt <- as.data.table(raw)[, c("Country Name", years), with = FALSE]
  dt <- melt(
    dt,
    id.vars = "Country Name",
    measure.vars = years,
    variable.name = "year",
    value.name = indicator_name,
    variable.factor = FALSE
  )
  dt[, year := as.integer(as.character(year))]
  dt[, (indicator_name) := suppressWarnings(as.numeric(get(indicator_name)))]
  setnames(dt, "Country Name", "country")
  dt
}

# World Bank regions and income-group aggregates are excluded from the
# country-level comparisons.
non_country_groups <- c(
  "Africa Eastern and Southern", "Africa Western and Central", "Arab World",
  "Caribbean small states", "Central Europe and the Baltics",
  "East Asia & Pacific", "East Asia & Pacific (excluding high income)",
  "East Asia & Pacific (IDA & IBRD countries)", "Early-demographic dividend",
  "Euro area", "Europe & Central Asia", "Europe & Central Asia (excluding high income)",
  "Europe & Central Asia (IDA & IBRD countries)", "European Union",
  "Fragile and conflict affected situations", "Heavily indebted poor countries (HIPC)",
  "High income", "IBRD only", "IDA & IBRD total", "IDA blend", "IDA only",
  "IDA total", "Late-demographic dividend", "Latin America & Caribbean",
  "Latin America & Caribbean (excluding high income)",
  "Latin America & the Caribbean (IDA & IBRD countries)",
  "Least developed countries: UN classification", "Low & middle income",
  "Low income", "Lower middle income", "Middle East & North Africa",
  "Middle East & North Africa (excluding high income)",
  "Middle East & North Africa (IDA & IBRD countries)", "Middle income",
  "North America", "Not classified", "OECD members", "Other small states",
  "Pacific island small states", "Post-demographic dividend",
  "Pre-demographic dividend", "Small states", "South Asia", "South Asia (IDA & IBRD)",
  "Sub-Saharan Africa", "Sub-Saharan Africa (excluding high income)",
  "Sub-Saharan Africa (IDA & IBRD countries)", "Upper middle income", "World"
)

# A logarithm is defined only for strictly positive observations.
positive_log <- function(x) {
  ifelse(is.finite(x) & x > 0, log(x), NA_real_)
}

# Each specification is fitted on the observations available for its variables.
fit_model <- function(formula, data) {
  lm(formula, data = as.data.frame(data), na.action = na.omit)
}

# Filter the model's estimation sample, rather than all rows of the raw panel.
filter_by_influence <- function(model, method = c("leverage", "residual")) {
  method <- match.arg(method)
  sample <- model.frame(model)
  if (method == "leverage") {
    h <- hatvalues(model)
    cutoff <- mean(h) + 2 * sd(h)
    keep <- h <= cutoff
  } else {
    z <- rstandard(model)
    q <- quantile(z, c(0.25, 0.75), na.rm = TRUE)
    iqr <- q[2] - q[1]
    keep <- z >= q[1] - 1.5 * iqr & z <= q[2] + 1.5 * iqr
  }
  sample[keep & !is.na(keep), , drop = FALSE]
}

summarize_model <- function(model, name) {
  s <- summary(model)
  data.table(
    model = name,
    observations = nobs(model),
    adjusted_r_squared = unname(s$adj.r.squared),
    r_squared = unname(s$r.squared)
  )
}

save_diagnostics <- function(model, name) {
  png(file.path("outputs", paste0(name, "_diagnostics.png")),
      width = 1100, height = 850, res = 125)
  par(mfrow = c(2, 2), mar = c(4.5, 4.5, 3, 1))
  plot(model, which = 1:4)
  dev.off()
}

# -----------------------------------------------------------------------------
# Data preparation
# -----------------------------------------------------------------------------
gdp <- read_indicator("gdp_per_capita.xlsx", "gdp_pc")
savings <- read_indicator("gross_savings.xls", "gross_savings")
population <- read_indicator("population_growth.xls", "population_growth")
rd <- read_indicator("rd_expenditure.xls", "rd_expenditure")
education <- read_indicator("education_expenditure.xls", "education_expenditure")
rule <- read_indicator("rule_of_law.xlsx", "rule_of_law")

baseline_data <- Reduce(
  function(x, y) merge(x, y, by = c("country", "year")),
  list(gdp, savings, population)
)
baseline_data <- baseline_data[!country %in% non_country_groups]
baseline_data[, `:=`(
  log_gdp = positive_log(gdp_pc),
  log_savings = positive_log(gross_savings),
  log_population_growth = positive_log(population_growth)
)]

# -----------------------------------------------------------------------------
# Baseline OLS and influence diagnostics
# -----------------------------------------------------------------------------
baseline_formula <- log_gdp ~ log_savings + log_population_growth
baseline <- fit_model(baseline_formula, baseline_data)

# Compare the original specification with two influential-observation filters.
residual_filtered <- lm(baseline_formula, data = filter_by_influence(baseline, "residual"))
leverage_filtered <- lm(baseline_formula, data = filter_by_influence(baseline, "leverage"))

# -----------------------------------------------------------------------------
# Extended OLS specifications
# -----------------------------------------------------------------------------
extended_data <- Reduce(
  function(x, y) merge(x, y, by = c("country", "year")),
  list(baseline_data, rd, education, rule)
)
extended_data[, `:=`(
  log_rd_expenditure = positive_log(rd_expenditure),
  log_education_expenditure = positive_log(education_expenditure)
)]

# As in the original analysis, the additional predictors enter in levels.
base_terms <- "log_gdp ~ log_savings + log_population_growth"
extra_terms <- list(
  rd = "rd_expenditure",
  education = "education_expenditure",
  rule_of_law = "rule_of_law",
  rd_education = "rd_expenditure + education_expenditure",
  rd_rule_of_law = "rd_expenditure + rule_of_law",
  education_rule_of_law = "education_expenditure + rule_of_law",
  full_model = "rd_expenditure + education_expenditure + rule_of_law"
)

extended_models <- lapply(extra_terms, function(add) {
  fit_model(as.formula(paste(base_terms, "+", add)), extended_data)
})

# Examine the impact of leverage filtering on the institutional-quality models.
rule_leverage <- lm(formula(extended_models$rule_of_law),
                    data = filter_by_influence(extended_models$rule_of_law, "leverage"))
rd_rule_leverage <- lm(formula(extended_models$rd_rule_of_law),
                       data = filter_by_influence(extended_models$rd_rule_of_law, "leverage"))

# -----------------------------------------------------------------------------
# Model summaries and diagnostic figures
# -----------------------------------------------------------------------------
dir.create("outputs", showWarnings = FALSE)
models <- c(
  list(baseline = baseline, residual_filtered = residual_filtered,
       leverage_filtered = leverage_filtered),
  extended_models,
  list(rule_leverage = rule_leverage, rd_rule_leverage = rd_rule_leverage)
)
comparison <- rbindlist(Map(summarize_model, models, names(models)))
setorder(comparison, -adjusted_r_squared)
print(comparison)
fwrite(comparison, file.path("outputs", "model_comparison.csv"))

for (name in names(models)) {
  cat("\n", strrep("=", 72), "\n", name, "\n", sep = "")
  print(summary(models[[name]]))
}

for (name in c("baseline", "leverage_filtered", "rule_of_law", "rd_rule_of_law")) {
  save_diagnostics(models[[name]], name)
}

cat("\nModel comparison saved in outputs/model_comparison.csv\n")
cat("Diagnostic plots saved in outputs/\n")
