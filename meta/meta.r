###############################################################################
# MULTILEVEL META-ANALYSIS (3 LEVELS) – F1-SCORE
###############################################################################

## 1 · PACKAGES ----------------------------------------------------------------
pkgs <- c("metafor", "readxl", "dplyr", "janitor",
          "stringr", "tibble")                # tibble for prettier prints
inst  <- rownames(installed.packages())
if (any(!pkgs %in% inst)) install.packages(setdiff(pkgs, inst))

library(metafor); library(readxl); library(dplyr); library(janitor)
library(stringr); library(tibble)

## 2 · DATA IMPORT --------------------------------------------------------------
df <- read_excel("meta_analysis_v4.xlsx", sheet = "geral") %>%
  clean_names() %>%
  rename(n_samples = test_or_validation_samples,
         f1_raw    = f1_score)

## 3 · PRE-PROCESSING -----------------------------------------------------------
df <- df %>%
  mutate(
    f1_raw    = as.numeric(f1_raw) /
      ifelse(max(f1_raw, na.rm = TRUE) > 1, 100, 1),
    n_samples = as.numeric(n_samples),
    f1_adj    = pmax(pmin(f1_raw, 1 - 0.5/n_samples), 0.5/n_samples),
    yi_logit  = qlogis(f1_adj),
    vi_logit  = 1/(n_samples * f1_adj * (1 - f1_adj)),
    sei_logit = sqrt(vi_logit)
  ) %>%
  group_by(study_id) %>%
  mutate(
    arm_no = row_number(),
    arm_id = interaction(study_id, arm_no, drop = TRUE)
  ) %>%
  ungroup()

## 4 · GLOBAL MODEL -------------------------------------------------------------
res <- rma.mv(
  yi_logit, vi_logit,
  random = ~1 | study_id/arm_id,
  method = "REML",
  data = df
)

overall    <- predict(res, transf = transf.ilogit)  # 95% CI + PI already computed
sigma2_L3  <- res$sigma2[1]; sigma2_L2 <- res$sigma2[2]
sigma2_L1  <- mean(df$vi_logit)

cat("\n========== OVERALL EFFECT ==========\n")
cat(sprintf("Combined mean F1     : %.3f\n", overall$pred))
cat(sprintf("95%% CI               : [%.3f ; %.3f]\n",
            overall$ci.lb, overall$ci.ub))
cat(sprintf("95%% PI               : [%.3f ; %.3f]\n",
            overall$pi.lb, overall$pi.ub))

cat("\n========== HETEROGENEITY ==========\n")
cat(sprintf("I² between studies (L3): %.1f %%\n",
            100 * sigma2_L3/(sigma2_L3 + sigma2_L2 + sigma2_L1)))
cat(sprintf("I² within studies  (L2): %.1f %%\n",
            100 * sigma2_L2/(sigma2_L3 + sigma2_L2 + sigma2_L1)))

# --- 95% CI for tau² and I² ----------------------------------
ci_tau    <- confint(res)$random
total_var <- sigma2_L3 + sigma2_L2 + sigma2_L1

i2_interval <- function(tau2_ci, total) round(100 * tau2_ci / total, 1)

I2_L3_ci <- i2_interval(
  c(ci_tau[1, "ci.lb"], ci_tau[1, "ci.ub"]),
  total_var
)
I2_L2_ci <- i2_interval(
  c(ci_tau[2, "ci.lb"], ci_tau[2, "ci.ub"]),
  total_var
)

cat("\n========== I² with 95% CI ==========\n")
cat(sprintf("I² between studies (L3): %.1f %% [%.1f – %.1f]\n",
            100*sigma2_L3 / total_var, I2_L3_ci[1], I2_L3_ci[2]))
cat(sprintf("I² within studies  (L2): %.1f %% [%.1f – %.1f]\n",
            100*sigma2_L2 / total_var, I2_L2_ci[1], I2_L2_ci[2]))

###############################################################################
# 5 · FUNNEL PLOT + EGGER TEST ------------------------------------------------
###############################################################################
study_level <- df %>%
  group_by(study_id) %>%
  summarise(
    yi_logit  = sum(yi_logit/vi_logit)/sum(1/vi_logit),
    vi_logit  = 1/sum(1/vi_logit),
    sei_logit = sqrt(vi_logit),
    .groups   = "drop"
  )

egger <- with(study_level,
              regtest(yi_logit, sei = sei_logit, model = "lm"))

cat("\n========== EGGER'S TEST ==========\n")
print(egger)

funnel(
  study_level$yi_logit, study_level$sei_logit,
  refline = as.vector(res$beta),
  shade   = c("white", "grey90"),
  xlab    = "logit(F1) by study",
  ylab    = "SE (logit)"
)
abline(v = res$beta, lty = 2)

###############################################################################
# 6 · GLOBAL FOREST PLOT (13 STUDIES) ------------------------------------------
###############################################################################
forest(
  study_level$yi_logit, vi = study_level$vi_logit,
  transf = transf.ilogit,
  slab   = study_level$study_id,
  xlab   = "F1 (95% CI)",
  at     = seq(0,1,.25),
  ylim   = c(-2, 16),
  refline = overall$pred
)
abline(h = 0, lty = "dotted")

addpoly(
  res$beta,
  ci.lb  = res$ci.lb[1],
  ci.ub  = res$ci.ub[1],
  rows   = -1,
  transf = transf.ilogit,
  mlab   = "Overall"
)

###############################################################################
# 7 · MODERATORS – DATA PREP ---------------------------------------------------
###############################################################################
df <- df %>%
  mutate(
    data_resolution_m = ifelse(
      grepl(",", data_resolution),
      sapply(str_extract_all(data_resolution, "\\d+\\.?\\d*"),
             \(v) mean(as.numeric(v))),
      as.numeric(gsub("[^0-9.]", "", data_resolution))
    ),
    segmentation_type  = factor(segmentation_type),
    architecture_base  = factor(architecture_base),
    data_source_std    = factor(data_source_std)
  ) %>%
  group_by(architecture_base) %>%
  mutate(
    arch_grp = ifelse(n() < 5, "Other", as.character(architecture_base))
  ) %>%
  ungroup() %>%
  mutate(
    arch_grp    = factor(arch_grp),
    sensor_cat  = case_when(
      str_detect(data_source_std, "(?i)sentinel-1") ~ "Sentinel-1 (SAR)",
      str_detect(data_source_std, "(?i)sentinel-2") ~ "Sentinel-2 (Optical)",
      str_detect(data_source_std, "(?i)landsat")    ~ "Landsat (Optical)",
      str_detect(data_source_std, "(?i)gaofen|google") ~ "High Resolution",
      TRUE ~ "Other"
    ) %>% factor()
  )

###############################################################################
# 8 · SUBGROUP MODELS ----------------------------------------------------------
###############################################################################
res_task <- rma.mv(
  yi_logit, vi_logit,
  random = ~1 | study_id/arm_id,
  mods   = ~ segmentation_type,
  method = "REML",
  data   = df
)

res_arch <- rma.mv(
  yi_logit, vi_logit,
  random = ~1 | study_id/arm_id,
  mods   = ~ arch_grp,
  method = "REML",
  data   = df
)

res_src <- rma.mv(
  yi_logit, vi_logit,
  random = ~1 | study_id/arm_id,
  mods   = ~ sensor_cat,
  method = "REML",
  data   = df
)

cat("\n========== COEFFICIENTS · TASK TYPE ==========\n")
print(as_tibble(coef(summary(res_task)), rownames = "term"), n = Inf)

cat("\n========== COEFFICIENTS · ARCHITECTURE ==========\n")
print(as_tibble(coef(summary(res_arch)), rownames = "term"), n = Inf)

cat("\n========== COEFFICIENTS · SENSOR ==========\n")
print(as_tibble(coef(summary(res_src)), rownames = "term"), n = Inf)

forest_moderator <- function(rma_obj, var, ttl) {
  levs <- levels(df[[var]])
  X    <- model.matrix(
    reformulate(var),
    setNames(data.frame(tmp = factor(levs, levs)), var)
  )[,-1]
  pr   <- predict(rma_obj, newmods = X, transf = transf.ilogit)
  forest(
    pr$pred,
    ci.lb   = pr$ci.lb,
    ci.ub   = pr$ci.ub,
    slab    = levs,
    refline = overall$pred,
    alim    = c(0,1), psize = 1.5, efac = 1.2,
    main    = ttl,
    xlab    = "Mean F1 (95% CI)"
  )
}

forest_moderator(res_arch, "arch_grp",         "Base Architecture")
forest_moderator(res_task, "segmentation_type","Task Type")
forest_moderator(res_src,  "sensor_cat",       "Sensor / Data Source")

###############################################################################
# 9 · META-REGRESSION (RESOLUTION) ---------------------------------------------
###############################################################################
res_res <- rma.mv(
  yi_logit, vi_logit,
  random = ~1 | study_id/arm_id,
  mods   = ~ data_resolution_m,
  method = "REML",
  data   = df %>% filter(!is.na(data_resolution_m))
)

cat("\n========== META-REGRESSION (resolution) ==========\n")
print(summary(res_res))

df$pred_f1 <- plogis(fitted(res_res, level = 0))
w          <- 1/sqrt(df$vi_logit)
plot(
  df$pred_f1, df$data_resolution_m,
  pch  = 21, bg = "grey85",
  cex  = (w/max(w))*4,
  xlab = "Adjusted F1",
  ylab = "Spatial resolution (m)",
  xlim = c(0,1),
  ylim = rev(range(df$data_resolution_m, na.rm = TRUE))
)
beta <- coef(res_res)
grid <- seq(
  min(df$data_resolution_m, na.rm = TRUE),
  max(df$data_resolution_m, na.rm = TRUE),
  length.out = 400
)
lines(plogis(beta[1] + beta[2]*grid), grid, lty = 2)
abline(v = overall$pred, lty = 3)

###############################################################################
# 10 · LEAVE-ONE-OUT ANALYSIS --------------------------------------------------
###############################################################################
loo_tbl <- lapply(unique(df$study_id), function(s) {
  fit <- rma.mv(
    yi_logit, vi_logit,
    random = ~1 | study_id/arm_id,
    method = "REML",
    data   = df %>% filter(study_id != s)
  )
  data.frame(
    study_out = s,
    logit     = fit$beta, se = fit$se,
    F1        = plogis(fit$beta),
    LCL       = plogis(fit$ci.lb), UCL = plogis(fit$ci.ub)
  )
}) %>% bind_rows()

cat("\n========== LEAVE-ONE-OUT ==========\n")
print(loo_tbl, digits = 3, row.names = FALSE)

forest(
  loo_tbl$logit, sei = loo_tbl$se,
  slab    = loo_tbl$study_out,
  refline = as.vector(res$beta),
  xlab    = "logit(F1) after omitting each study"
)

summary(res_task)
summary(res_arch)
summary(res_src)

###############################################################################
# 11 · PRINT NUMBERS FOR TABLE (console only) ---------------------------------
###############################################################################
# A) Overall effect and intervals
cat("\n========== OVERALL EFFECT ==========\n")
cat(sprintf("Combined mean F1         : %.3f\n", overall$pred))
cat(sprintf("95%% CI                   : [%.3f – %.3f]\n",
            overall$ci.lb, overall$ci.ub))
cat(sprintf("95%% PI                   : [%.3f – %.3f]\n",
            overall$pi.lb, overall$pi.ub))

# B) Heterogeneity metrics
sigma2_L3  <- res$sigma2[1]
sigma2_L2  <- res$sigma2[2]
sigma2_L1  <- mean(df$vi_logit)
total_var  <- sigma2_L3 + sigma2_L2 + sigma2_L1
cat("\n========== HETEROGENEITY ==========\n")
cat(sprintf("Q (df = %d)              : %.1f,  p = %.3f\n",
            res$k - res$p, res$QE, res$QEp))
cat(sprintf("Tau² between studies     : %.3f\n", sigma2_L3))
cat(sprintf("Tau² within studies      : %.3f\n", sigma2_L2))
cat(sprintf("I² between studies       : %.1f %%\n",
            100 * sigma2_L3 / total_var))
cat(sprintf("I² within studies        : %.1f %%\n",
            100 * sigma2_L2 / total_var))

# C) Egger’s test
egger <- with(
  study_level,
  regtest(yi_logit, sei = sei_logit, model = "lm")
)
cat("\n========== EGGER'S TEST ==========\n")
cat(sprintf("t(%d) = %.2f,  p = %.3f\n",
            egger$df[2], egger$statistic, egger$pval))
cat("\n")
print(egger)

###############################################################################
# 12 · PRINT SUBGROUP DATA (console only) -------------------------------------
###############################################################################
library(dplyr)
library(glue)

#– helper to extract predicted F1 and 95% CI per level  -----------------------
pred_by_level <- function(rma_obj, var) {
  levs <- levels(df[[var]])
  X    <- model.matrix(
    reformulate(var),
    setNames(data.frame(tmp = factor(levs, levs)), var)
  )[,-1]
  pr   <- predict(rma_obj, newmods = X, transf = transf.ilogit)
  tibble(
    subgroup = levs,
    F1       = round(pr$pred, 3),
    LCL      = round(pr$ci.lb, 3),
    UCL      = round(pr$ci.ub, 3)
  )
}

# 1 · Architecture subgroup ---------------------------------------------------
tbl_arch <- df %>%
  count(arch_grp, name = "n_arms") %>%
  full_join(pred_by_level(res_arch, "arch_grp"),
            by = c("arch_grp" = "subgroup")) %>%
  mutate(moderator = "Architecture") %>%
  select(moderator, subgroup = arch_grp, n_arms, F1, LCL, UCL)

p_arch <- res_arch$QMp  # moderator p-value

# 2 · Task type subgroup ------------------------------------------------------
tbl_task <- df %>%
  count(segmentation_type, name = "n_arms") %>%
  full_join(pred_by_level(res_task, "segmentation_type"),
            by = c("segmentation_type" = "subgroup")) %>%
  mutate(moderator = "Task Type") %>%
  select(moderator, subgroup = segmentation_type, n_arms, F1, LCL, UCL)

p_task <- res_task$QMp

# 3 · Data source subgroup ----------------------------------------------------
tbl_src <- df %>%
  count(sensor_cat, name = "n_arms") %>%
  full_join(pred_by_level(res_src, "sensor_cat"),
            by = c("sensor_cat" = "subgroup")) %>%
  mutate(moderator = "Data Source") %>%
  select(moderator, subgroup = sensor_cat, n_arms, F1, LCL, UCL)

p_src <- res_src$QMp

# Consolidate and print -------------------------------------------------------
print(tbl_arch, n = Inf)
cat(glue("\n(p = {formatC(p_arch, digits = 3, format = 'f')})\n\n"))

print(tbl_task, n = Inf)
cat(glue("\n(p = {formatC(p_task, digits = 3, format = 'f')})\n\n"))

print(tbl_src, n = Inf)
cat(glue("\n(p = {formatC(p_src, digits = 3, format = 'f')})\n\n"))

cat("\n=== SAMPLE COUNTS ===\n")
cat(sprintf("Total arms in dataset                   : %d\n", nrow(df)))
cat(sprintf("Arms in GLOBAL model (res)              : %d\n", res$k))
cat(sprintf("Arms in ARCHITECTURE model (res_arch)   : %d\n", res_arch$k))
cat(sprintf("Arms in TASK TYPE model (res_task)      : %d\n", res_task$k))
cat(sprintf("Arms in SENSOR model (res_src)          : %d\n", res_src$k))
cat(sprintf("Arms in META-REGRESSION model (res_res) : %d\n\n", res_res$k))

