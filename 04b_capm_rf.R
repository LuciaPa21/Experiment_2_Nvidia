# =============================================================================
# 04b_capm_rf.R
# Klassisches CAPM mit risikofreiem Zinssatz
# =============================================================================
# Unterschied zum Marktmodell (04_capm.R):
#
#   Marktmodell:      r_stock = α + β × r_Markt
#   Klassisches CAPM: r_stock − rf = β × (r_Markt − rf)
#
# Der risikofreie Zinssatz (rf) wird von beiden Seiten abgezogen.
# Dadurch arbeiten wir mit sogenannten "Excess Returns" –
# also der Rendite die ÜBER dem risikofreien Zinssatz liegt.
#
# Woher kommt rf?
# → 3-Monats-US-Treasury-Bill (DTB3) von der Federal Reserve (FRED)
# → Das ist der Standard in der empirischen Finanzliteratur
# → Quelle: Fama & French (1993), MacKinlay (1997)
#
# Warum 3-Monats-Treasury?
# → Gilt als "risikolose" Anlage da US-Staatsanleihen als
#   ausfallsicher gelten
# → Kurzlaufend (3 Monate) passt am besten zu täglichen Renditen
# → Annualisierter Zinssatz wird auf Tagesbasis umgerechnet: rf/252
# =============================================================================

cat("=== STEP 4b: Klassisches CAPM mit risikofreiem Zinssatz ===\n\n")

# --- Risikofreien Zinssatz laden ---------------------------------------------
# DTB3 = 3-Month Treasury Bill Secondary Market Rate
# Quelle: FRED (Federal Reserve Economic Data)
# URL: https://fred.stlouisfed.org/series/DTB3

cat("Lade risikofreien Zinssatz (3-Monats-Treasury) von FRED...\n")

tryCatch({
  getSymbols("DTB3", src = "FRED", auto.assign = TRUE)

  # Letzten verfügbaren Wert nehmen (annualisiert in Prozent)
  rf_annual <- as.numeric(last(na.omit(DTB3))) / 100

  # Auf Tagesbasis umrechnen (252 Handelstage pro Jahr)
  rf_daily  <- rf_annual / 252

  cat("Risikofreier Zinssatz (annualisiert):", round(rf_annual * 100, 4), "%\n")
  cat("Risikofreier Zinssatz (täglich):     ", round(rf_daily  * 100, 6), "%\n\n")

}, error = function(e) {
  cat("FRED nicht erreichbar – verwende Schätzwert rf = 4.5% p.a.\n")
  cat("(Bitte manuell aktualisieren unter: https://fred.stlouisfed.org/series/DTB3)\n\n")
  rf_annual <<- 0.045   # Fallback: aktueller US-Leitzinsbereich
  rf_daily  <<- rf_annual / 252
})

# --- Excess Returns berechnen ------------------------------------------------
# Excess Return = tatsächliche Rendite MINUS risikofreier Zinssatz
# Intuition: Was verdiene ich ÜBER eine risikolose Anlage hinaus?

est_data_rf <- est_data %>%
  mutate(
    excess_stock  = r_stock  - rf_daily,   # NVIDIA Excess Return
    excess_market = r_market - rf_daily    # S&P 500 Excess Return
  )

cat("Excess Returns berechnet (erste 3 Zeilen zur Kontrolle):\n")
print(head(est_data_rf[, c("date", "r_stock", "r_market",
                            "excess_stock", "excess_market")], 3))
cat("\n")

# --- Klassische CAPM-Regression ----------------------------------------------
# Im klassischen CAPM ist Alpha theoretisch = 0
# (keine Überrendite ohne Risiko)
# Wir schätzen es trotzdem – wenn Alpha signifikant ≠ 0 ist,
# spricht das gegen das CAPM (sogenanntes "Alpha-Puzzle")

capm_rf_model <- lm(excess_stock ~ excess_market, data = est_data_rf)
print(summary(capm_rf_model))

# --- Koeffizienten extrahieren -----------------------------------------------
alpha_rf  <- coef(capm_rf_model)[1]
beta_rf   <- coef(capm_rf_model)[2]
r2_rf     <- summary(capm_rf_model)$r.squared
sigma_rf  <- summary(capm_rf_model)$sigma

cat("\nGeschätztes Alpha (CAPM): ", round(alpha_rf, 6), "\n")
cat("Geschätztes Beta  (CAPM): ", round(beta_rf,  4),  "\n")
cat("R²                (CAPM): ", round(r2_rf,    4),  "\n\n")

# Alpha-Interpretation:
# Im klassischen CAPM sollte Alpha = 0 sein.
# Ein signifikant positives Alpha bedeutet: NVIDIA erwirtschaftet
# eine Überrendite die nicht durch Marktrisiko erklärt wird.
alpha_pval <- summary(capm_rf_model)$coefficients[1, 4]
if (alpha_pval < 0.05) {
  cat("Hinweis: Alpha ist statistisch signifikant (p =",
      round(alpha_pval, 4), ")\n")
  cat("→ NVIDIA zeigt eine Überrendite die das klassische CAPM nicht erklärt.\n\n")
} else {
  cat("Hinweis: Alpha ist NICHT signifikant (p =",
      round(alpha_pval, 4), ")\n")
  cat("→ Konsistent mit klassischem CAPM (Alpha ≈ 0 nicht ablehnen).\n\n")
}

# --- Modellvergleich ---------------------------------------------------------
cat("=== Modellvergleich: Marktmodell vs. Klassisches CAPM ===\n\n")

comparison_df <- data.frame(
  Modell  = c("Marktmodell (04_capm.R)", "Klassisches CAPM (04b_capm_rf.R)"),
  Alpha   = round(c(alpha_hat, alpha_rf), 6),
  Beta    = round(c(beta_hat,  beta_rf),  4),
  R2      = round(c(r_squared, r2_rf),    4),
  Sigma   = round(c(sigma,     sigma_rf), 6)
)

print(comparison_df)

cat("\nInterpretation:\n")
cat("Wenn Beta und R² ähnlich sind → Ergebnisse sind robust\n")
cat("gegenüber der Modellwahl (Marktmodell vs. CAPM).\n\n")

# Differenz Beta als Robustheitscheck
beta_diff <- abs(beta_hat - beta_rf)
if (beta_diff < 0.05) {
  cat("Beta-Differenz:", round(beta_diff, 4),
      "→ Sehr ähnlich. Modellwahl hat kaum Einfluss.\n\n")
} else {
  cat("Beta-Differenz:", round(beta_diff, 4),
      "→ Spürbare Abweichung. Im Methodikteil begründen.\n\n")
}
