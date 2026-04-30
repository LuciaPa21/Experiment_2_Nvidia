# =============================================================================
# 06_sensitivity.R
# Sensitivitätsanalyse: Verschiedene Event Windows testen
# =============================================================================
# Was ist eine Sensitivitätsanalyse?
# Wir testen ob unser Ergebnis stabil bleibt wenn wir Parameter ändern.
#
# Ändert sich das Ergebnis STARK  -> nicht robust, Vorsicht!
# Ändert sich das Ergebnis WENIG  -> Ergebnis ist glaubwürdig
#
# Wir testen 4 verschiedene Event Windows:
# [-1,+1]   = Unser Hauptmodell (minimales Window)
# [-3,+3]   = Kurzes Window
# [-5,+5]   = Mittleres Window
# [-10,+10] = Breites Window (viele Vorabeffekte, mehr Rauschen)
# =============================================================================

cat("=== SENSITIVITÄTSANALYSE: Verschiedene Event Windows ===\n\n")

event_windows <- list(c(1,1), c(3,3), c(5,5), c(10,10))
sens_results  <- data.frame()

for (ew in event_windows) {
  pre  <- ew[1]
  post <- ew[2]

  ew_data <- returns_df %>%
    filter(date >= (event_date - pre) & date <= (event_date + post)) %>%
    mutate(
      expected_return = alpha_hat + beta_hat * r_market,
      AR              = r_stock - expected_return,
      CAR             = cumsum(AR),
      t_stat          = AR / sigma,
      p_value         = 2 * (1 - pt(abs(t_stat), df = nrow(est_data) - 2)),
      is_event        = (date == event_date)
    )

  AR_ev  <- ew_data %>% filter(is_event) %>% pull(AR)
  p_ev   <- ew_data %>% filter(is_event) %>% pull(p_value)
  CAR_ev <- tail(ew_data$CAR, 1)

  sens_results <- rbind(sens_results, data.frame(
    Event_Window = paste0("[-", pre, ", +", post, "]"),
    AR_EventTag  = round(AR_ev * 100, 3),
    p_Wert       = round(p_ev, 4),
    Signifikant  = ifelse(p_ev < 0.05, "JA", "NEIN"),
    CAR_gesamt   = round(CAR_ev * 100, 3)
  ))
}

print(sens_results)
cat("\nTipp: Wenn AR_EventTag über alle Windows ähnlich ist, ist das Ergebnis robust.\n\n")
