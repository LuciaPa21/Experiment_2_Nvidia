# =============================================================================
# 05_abnormal_returns.R
# Step 6: Abnormale Rendite und T-Test berechnen
# =============================================================================
# Abnormale Rendite (AR):
#   AR_t = r_stock_t - (alpha + beta * r_market_t)
#        = Tatsächliche Rendite - Erwartete Rendite laut CAPM
#
# Kumulierte abnormale Rendite (CAR):
#   CAR = Summe aller AR_t im Event Window
#   Zeigt den Gesamteffekt des Events über alle Tage
#
# T-Test (Hypothesentest):
#   H0: AR = 0  (keine abnormale Rendite - Event hatte keinen Effekt)
#   H1: AR ≠ 0  (signifikante abnormale Rendite - Event hatte einen Effekt)
#   p-Wert < 0.05 -> H0 ablehnen -> Ergebnis statistisch signifikant
# =============================================================================

cat("=== STEP 6: Abnormale Renditen und T-Test ===\n")

# --- AR und CAR berechnen ----------------------------------------------------
event_data <- returns_df %>%
  filter(date >= event_window_start & date <= event_window_end) %>%
  mutate(
    expected_return = alpha_hat + beta_hat * r_market,   # Erwartete Rendite (CAPM)
    AR              = r_stock - expected_return,          # Abnormale Rendite
    CAR             = cumsum(AR),                         # Kumulierte abnormale Rendite
    t_stat          = AR / sigma,                         # T-Statistik
    p_value         = 2 * (1 - pt(abs(t_stat), df = nrow(est_data) - 2)),  # p-Wert
    signifikant     = p_value < 0.05,                     # Signifikant bei 5%?
    event_day       = as.numeric(date - event_date),      # t=0 ist Event-Tag
    is_event        = (date == event_date)
  )

# --- Ergebnistabelle ausgeben ------------------------------------------------
cat("\nErgebnistabelle (Event Window):\n")
print(event_data %>%
        select(date, event_day, r_stock, expected_return, AR, CAR, t_stat, p_value, signifikant) %>%
        mutate(across(where(is.numeric), ~ round(., 5))))

# --- Kennzahlen am Event-Tag -------------------------------------------------
AR_event  <- event_data %>% filter(is_event) %>% pull(AR)
p_event   <- event_data %>% filter(is_event) %>% pull(p_value)
t_event   <- event_data %>% filter(is_event) %>% pull(t_stat)
CAR_total <- tail(event_data$CAR, 1)

cat("\n=== ERGEBNISSE ===\n")
cat("Abnormale Rendite am Event-Tag (AR₀):      ", round(AR_event * 100, 3), "%\n")
cat("T-Statistik:                               ", round(t_event, 4), "\n")
cat("p-Wert:                                    ", round(p_event, 4), "\n")
cat("Statistisch signifikant (5% Niveau):       ", ifelse(p_event < 0.05, "JA", "NEIN"), "\n")
cat("Kumulierte abnormale Rendite (CAR gesamt): ", round(CAR_total * 100, 3), "%\n\n")

if (p_event < 0.05) {
  cat("Interpretation: Die abnormale Rendite ist statistisch signifikant.\n")
  cat("H0 wird abgelehnt - die Marktreaktion ist nicht zufällig.\n")
} else {
  cat("Interpretation: Die abnormale Rendite ist NICHT statistisch signifikant.\n")
  cat("H0 kann nicht abgelehnt werden.\n")
}
