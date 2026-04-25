# =============================================================================
# 04_capm.R
# Step 4 & 5: Returns berechnen und CAPM-Regression
# =============================================================================
# CAPM-Modell (Capital Asset Pricing Model):
#
#   r_stock = alpha + beta * r_market + epsilon
#
# alpha = Überrendite unabhängig vom Markt
# beta  = Sensitivität gegenüber dem Markt (systematisches Risiko)
#         beta > 1: Aktie schwankt stärker als der Markt
#         beta < 1: Aktie schwankt schwächer als der Markt
# R²    = Wie gut erklärt der Markt die Aktienrendite? (0-100%)
#
# Wichtig: Regression nur auf dem Estimation Window!
# Das Event Window bleibt bewusst außen vor, damit das Event
# die Beta-Schätzung nicht verzerrt.
# =============================================================================

cat("=== STEP 4 & 5: CAPM-Regression (Estimation Window) ===\n")

# --- OLS-Regression ----------------------------------------------------------
capm_model <- lm(r_stock ~ r_market, data = est_data)
print(summary(capm_model))

# --- Koeffizienten extrahieren -----------------------------------------------
alpha_hat <- coef(capm_model)[1]   # Geschätztes Alpha
beta_hat  <- coef(capm_model)[2]   # Geschätztes Beta
r_squared <- summary(capm_model)$r.squared
sigma     <- summary(capm_model)$sigma  # Residualstandardabweichung (für T-Test)

cat("\nGeschätztes Alpha:", round(alpha_hat, 6), "\n")
cat("Geschätztes Beta: ", round(beta_hat,  4),  "\n")
cat("R²:               ", round(r_squared, 4),  "\n\n")

if (beta_hat > 1) {
  cat("Interpretation Beta: NVIDIA ist VOLATILER als der Gesamtmarkt.\n")
  cat("Eine Marktbewegung von 1% führt zu ca.", round(beta_hat, 2), "% bei NVIDIA.\n\n")
} else {
  cat("Interpretation Beta: NVIDIA ist WENIGER volatil als der Gesamtmarkt.\n\n")
}

# --- Sensitivitätsanalyse Beta -----------------------------------------------
# Ist unser Beta stabil gegenüber der Länge des Estimation Windows?
cat("--- Sensitivitätsanalyse: Beta bei verschiedenen Estimation Windows ---\n")
for (tage in c(60, 120, 180, 252)) {
  est_sens <- returns_df %>%
    filter(date >= (estimation_end - tage) & date <= estimation_end)
  if (nrow(est_sens) >= 20) {
    beta_sens <- coef(lm(r_stock ~ r_market, data = est_sens))[2]
    cat("Beta bei", tage, "Tagen:", round(beta_sens, 4), "\n")
  }
}
cat("\n")
