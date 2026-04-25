# =============================================================================
# 08_diagnostics.R
# Diagnose & Robustness Checks des Estimation Windows
# =============================================================================
# Warum brauchen wir das?
# Die CAPM-Regression (OLS) hat Voraussetzungen die erfüllt sein müssen,
# damit unsere Ergebnisse (Beta, AR, T-Test) gültig sind.
#
# Wir prüfen 4 Dinge:
#
# CHECK 1: Ausreißer
#   Extreme Rendite-Tage können Beta stark verzerren.
#   Wir definieren Ausreißer als Tage mit |Rendite| > 3 Standardabweichungen.
#
# CHECK 2: Normalverteilung der Residuen
#   Der T-Test setzt voraus dass die Residuen normalverteilt sind.
#   Test: Jarque-Bera oder visuell per Q-Q Plot.
#
# CHECK 3: Autokorrelation
#   OLS setzt voraus dass Residuen unabhängig sind (kein Muster über Zeit).
#   Wenn heute eine hohe Rendite -> morgen auch hoch, ist das ein Problem.
#
# CHECK 4: Rolling Beta (Stabilität)
#   Ist Beta über das Estimation Window stabil?
#   Ein stark schwankendes Beta deutet auf Strukturbrüche hin.
# =============================================================================

cat("=== DIAGNOSE: Robustness Checks des Estimation Windows ===\n\n")

# Residuen aus der CAPM-Regression extrahieren
residuals_est <- residuals(capm_model)
fitted_est    <- fitted(capm_model)
sd_residuals  <- sd(residuals_est)
sd_returns    <- sd(est_data$r_stock)


# =============================================================================
# CHECK 1: Ausreißer im Estimation Window
# =============================================================================
cat("--- CHECK 1: Ausreißer ---\n")

# Ausreißer = Tage mit |Rendite| > 3 Standardabweichungen
outlier_threshold <- 3 * sd_returns
outliers <- est_data %>%
  mutate(
    z_score     = abs(r_stock) / sd_returns,
    ist_ausreisser = abs(r_stock) > outlier_threshold
  ) %>%
  filter(ist_ausreisser)

if (nrow(outliers) == 0) {
  cat("Keine Ausreißer gefunden (|Rendite| > 3 SD). Estimation Window ist sauber.\n\n")
} else {
  cat("ACHTUNG:", nrow(outliers), "Ausreißer gefunden:\n")
  print(outliers %>% select(date, r_stock, z_score) %>% mutate(across(where(is.numeric), ~round(., 4))))
  cat("\nDiese Tage könnten Beta verzerren. Prüfe ob es bekannte Ereignisse gab.\n\n")
}

# Plot 1: Renditen im Estimation Window mit Ausreißer-Markierung
ausreisser_daten <- est_data %>%
  mutate(
    ist_ausreisser = abs(r_stock) > outlier_threshold,
    upper_band     = outlier_threshold,
    lower_band     = -outlier_threshold
  )

p_diag1 <- ggplot(ausreisser_daten, aes(x = date, y = r_stock * 100)) +
  geom_line(color = "gray60", linewidth = 0.5) +
  geom_point(aes(color = ist_ausreisser), size = 1.5) +
  geom_hline(aes(yintercept =  outlier_threshold * 100), linetype = "dashed", color = "red", linewidth = 0.8) +
  geom_hline(aes(yintercept = -outlier_threshold * 100), linetype = "dashed", color = "red", linewidth = 0.8) +
  scale_color_manual(values = c("FALSE" = "#2980b9", "TRUE" = "#e74c3c"),
                     labels = c("FALSE" = "Normal", "TRUE" = "Ausreißer (>3 SD)"),
                     name = "") +
  labs(
    title    = "CHECK 1: Renditen im Estimation Window",
    subtitle = "Rote Linien = ±3 Standardabweichungen | Rote Punkte = Ausreißer",
    x        = "Datum",
    y        = "Tagesrendite NVIDIA (%)"
  ) +
  theme_minimal(base_size = 13) +
  theme(legend.position = "bottom")
print(p_diag1)


# =============================================================================
# CHECK 2: Normalverteilung der Residuen (Q-Q Plot)
# =============================================================================
cat("--- CHECK 2: Normalverteilung der Residuen ---\n")

# Schiefe und Kurtosis berechnen
n        <- length(residuals_est)
skewness <- (sum((residuals_est - mean(residuals_est))^3) / n) / sd(residuals_est)^3
kurtosis <- (sum((residuals_est - mean(residuals_est))^4) / n) / sd(residuals_est)^4

cat("Schiefe (Skewness):", round(skewness, 4),
    "| Idealwert: 0 (symmetrisch)\n")
cat("Kurtosis:          ", round(kurtosis, 4),
    "| Idealwert: 3 (Normalverteilung)\n")

if (abs(skewness) < 0.5 && abs(kurtosis - 3) < 1) {
  cat("Residuen sind annähernd normalverteilt. T-Test ist gültig.\n\n")
} else {
  cat("HINWEIS: Residuen weichen von der Normalverteilung ab.\n")
  cat("T-Test Ergebnisse sollten vorsichtig interpretiert werden.\n\n")
}

# Plot 2: Q-Q Plot
residuals_df <- data.frame(residuals = residuals_est)

p_diag2 <- ggplot(residuals_df, aes(sample = residuals)) +
  stat_qq(color = "#2980b9", size = 1.5, alpha = 0.7) +
  stat_qq_line(color = "red", linewidth = 1) +
  labs(
    title    = "CHECK 2: Q-Q Plot der Residuen",
    subtitle = "Punkte nah an der roten Linie = Normalverteilung. Abweichungen an den Enden = schwere Ränder (Fat Tails)",
    x        = "Theoretische Quantile (Normalverteilung)",
    y        = "Beobachtete Residuen"
  ) +
  theme_minimal(base_size = 13)
print(p_diag2)


# =============================================================================
# CHECK 3: Autokorrelation der Residuen
# =============================================================================
cat("--- CHECK 3: Autokorrelation ---\n")

# Korrelation zwischen Residuum heute und Residuum gestern
autocorr_lag1 <- cor(residuals_est[-1], residuals_est[-length(residuals_est)])
cat("Autokorrelation (Lag 1):", round(autocorr_lag1, 4),
    "| Idealwert: ~0\n")

if (abs(autocorr_lag1) < 0.1) {
  cat("Keine relevante Autokorrelation. OLS-Annahmen erfüllt.\n\n")
} else {
  cat("HINWEIS: Leichte Autokorrelation vorhanden.\n")
  cat("Standardfehler könnten leicht unterschätzt sein.\n\n")
}

# Plot 3: Autokorrelation visualisieren
acf_values <- acf(residuals_est, plot = FALSE, lag.max = 20)
acf_df <- data.frame(
  lag  = acf_values$lag[-1],
  acf  = acf_values$acf[-1],
  conf = qnorm(0.975) / sqrt(n)
)

p_diag3 <- ggplot(acf_df, aes(x = lag, y = acf)) +
  geom_col(fill = "#2980b9", alpha = 0.8, width = 0.5) +
  geom_hline(aes(yintercept =  conf), linetype = "dashed", color = "red") +
  geom_hline(aes(yintercept = -conf), linetype = "dashed", color = "red") +
  geom_hline(yintercept = 0, color = "gray50") +
  labs(
    title    = "CHECK 3: Autokorrelation der Residuen",
    subtitle = "Balken außerhalb der roten Linien = signifikante Autokorrelation",
    x        = "Lag (Tage)",
    y        = "Autokorrelation"
  ) +
  theme_minimal(base_size = 13)
print(p_diag3)


# =============================================================================
# CHECK 4: Rolling Beta (Stabilität über Zeit)
# =============================================================================
cat("--- CHECK 4: Rolling Beta (Stabilität) ---\n")
cat("Ein stabiles Beta ist wichtig - sonst ist unsere Schätzung nicht zuverlässig.\n")

# Rollendes Beta mit 60-Tage-Fenster berechnen
window_size  <- 60
rolling_beta <- numeric(nrow(est_data) - window_size + 1)
rolling_date <- est_data$date[window_size:nrow(est_data)]

for (i in 1:(nrow(est_data) - window_size + 1)) {
  window_data    <- est_data[i:(i + window_size - 1), ]
  rolling_beta[i] <- coef(lm(r_stock ~ r_market, data = window_data))[2]
}

rolling_df <- data.frame(
  date = rolling_date,
  beta = rolling_beta
)

beta_varianz <- sd(rolling_beta)
cat("Standardabweichung des Rolling Beta:", round(beta_varianz, 4), "\n")

if (beta_varianz < 0.3) {
  cat("Beta ist stabil über das Estimation Window. Schätzung ist zuverlässig.\n\n")
} else {
  cat("HINWEIS: Beta schwankt stark. Möglicher Strukturbruch im Estimation Window.\n")
  cat("Erwäge ein kürzeres oder alternatives Estimation Window.\n\n")
}

p_diag4 <- ggplot(rolling_df, aes(x = date, y = beta)) +
  geom_line(color = "#2980b9", linewidth = 1) +
  geom_hline(yintercept = beta_hat, linetype = "dashed",
             color = "red", linewidth = 0.8) +
  annotate("text", x = min(rolling_df$date),
           y = beta_hat + 0.05,
           label = paste("Gesamt-Beta:", round(beta_hat, 3)),
           color = "red", hjust = 0, size = 3.5) +
  labs(
    title    = "CHECK 4: Rolling Beta (60-Tage-Fenster)",
    subtitle = "Rote Linie = Beta aus gesamtem Estimation Window | Stabile Linie = robust",
    x        = "Datum",
    y        = "Beta (60-Tage-Rolling)"
  ) +
  theme_minimal(base_size = 13)
print(p_diag4)


# =============================================================================
# ZUSAMMENFASSUNG
# =============================================================================
cat("=== DIAGNOSE ZUSAMMENFASSUNG ===\n")
cat("CHECK 1 – Ausreißer:         ",
    ifelse(nrow(outliers) == 0, "OK", paste("ACHTUNG –", nrow(outliers), "Ausreißer")), "\n")
cat("CHECK 2 – Normalverteilung:  ",
    ifelse(abs(skewness) < 0.5 && abs(kurtosis - 3) < 1, "OK", "HINWEIS – Abweichung"), "\n")
cat("CHECK 3 – Autokorrelation:   ",
    ifelse(abs(autocorr_lag1) < 0.1, "OK", "HINWEIS – Leichte Autokorrelation"), "\n")
cat("CHECK 4 – Rolling Beta:      ",
    ifelse(beta_varianz < 0.3, "OK", "HINWEIS – Beta schwankt"), "\n\n")
cat("Legende: OK = Annahmen erfüllt | HINWEIS = prüfen | ACHTUNG = kritisch\n")
