# =============================================================================
# EVENT STUDY: ABNORMALE RENDITE NVIDIA (Q4 FY2025 Earnings, 26. Feb 2026)
# =============================================================================
# Methodik: MacKinlay (1997) – klassische Event Study mit CAPM
#
# Step 1: Identify the Event and the Event Window
# Step 2: Identify the Estimation Period
# Step 3: Data Gathering
# Step 4: Calculate Returns
# Step 5: Perform Market Model Regression (CAPM)
# Step 6: Calculate Abnormal Return and p-Value (T-Test)
# =============================================================================

# --- 0. Pakete installieren & laden ----------------------------------------
# Beim ersten Mal: install.packages(c("quantmod", "ggplot2", "dplyr", "lubridate"))

library(quantmod)   # Finanzdaten von Yahoo Finance herunterladen
library(ggplot2)    # Visualisierung
library(dplyr)      # Datentransformation
library(lubridate)  # Datumsverarbeitung


# =============================================================================
# STEP 1: Identify the Event and the Event Window
# =============================================================================
# Event: NVIDIA Q4 FY2025 Earnings Announcement am 26. Februar 2026
# Trotz Rekordumsatz (+100% YoY) fiel die Aktie um ca. -5%
# Event Window: [-10, +10] Handelstage rund um das Event

event_date        <- as.Date("2026-02-26")   # Tag der Earnings-Veröffentlichung
event_window_pre  <- 10                       # Tage VOR dem Event
event_window_post <- 10                       # Tage NACH dem Event

cat("=== STEP 1: Event und Event Window ===\n")
cat("Event-Datum:   ", format(event_date), "\n")
cat("Event Window:  [", -event_window_pre, ",", event_window_post, "] Handelstage\n\n")


# =============================================================================
# STEP 2: Identify the Estimation Period
# =============================================================================
# Estimation Period: 1 Jahr (ca. 252 Handelstage) VOR dem Event Window
# Mehr Daten = besseres Modell, aber Trade-Off: zu alte Daten könnten
# strukturelle Veränderungen enthalten (Sensitivitätsanalyse möglich)

estimation_days <- 252   # ca. 1 Jahr Handelstage

cat("=== STEP 2: Estimation Period ===\n")
cat("Länge: ca.", estimation_days, "Handelstage (1 Jahr) vor dem Event Window\n\n")


# =============================================================================
# STEP 3: Data Gathering
# =============================================================================
# Daten: NVIDIA (NVDA) + S&P 500 als Marktbenchmark
# Quelle: Yahoo Finance via quantmod

ticker_stock  <- "NVDA"   # NVIDIA
ticker_market <- "^GSPC"  # S&P 500 (Marktindex / Market Proxy)

start_date <- event_date - estimation_days - event_window_pre - 30
end_date   <- event_date + event_window_post + 5

cat("=== STEP 3: Data Gathering ===\n")
cat("Lade Daten von Yahoo Finance...\n")
cat("Zeitraum:", format(start_date), "bis", format(end_date), "\n\n")

getSymbols(ticker_stock,  src = "yahoo", from = start_date, to = end_date, auto.assign = TRUE)
getSymbols(ticker_market, src = "yahoo", from = start_date, to = end_date, auto.assign = TRUE)

prices_stock  <- Ad(NVDA)
prices_market <- Ad(GSPC)

cat("Daten erfolgreich geladen!\n\n")


# =============================================================================
# STEP 4: Calculate NVIDIA and Market Returns
# =============================================================================
# Log-Renditen: r_t = ln(P_t / P_{t-1})
# Log-Renditen sind additiv und normalverteilt -> besser für Statistik

cat("=== STEP 4: Calculate Returns ===\n")

returns_stock  <- dailyReturn(prices_stock,  type = "log")
returns_market <- dailyReturn(prices_market, type = "log")

returns_stock  <- returns_stock[-1]
returns_market <- returns_market[-1]

returns_df <- merge(returns_stock, returns_market)
colnames(returns_df) <- c("r_stock", "r_market")
returns_df <- as.data.frame(returns_df)
returns_df$date <- as.Date(rownames(returns_df))
rownames(returns_df) <- NULL

cat("Anzahl Handelstage im Datensatz:", nrow(returns_df), "\n\n")

# Estimation Window und Event Window definieren
event_window_start <- event_date - event_window_pre
event_window_end   <- event_date + event_window_post
estimation_end     <- event_window_start - 1
estimation_start   <- estimation_end - estimation_days

cat("Estimation Period:", format(estimation_start), "bis", format(estimation_end), "\n")
cat("Event Window:     ", format(event_window_start), "bis", format(event_window_end), "\n\n")

est_data <- returns_df %>%
  filter(date >= estimation_start & date <= estimation_end)

cat("Handelstage im Estimation Window:", nrow(est_data), "\n\n")

if (nrow(est_data) < 30) {
  stop("Zu wenige Datenpunkte! Bitte estimation_days erhöhen.")
}


# =============================================================================
# STEP 5: Perform Market Model Regression During the Estimation Period
# =============================================================================
# CAPM-Regression (OLS): r_stock = alpha + beta * r_market + epsilon
#
# alpha = Überrendite unabhängig vom Markt
# beta  = Sensitivität gegenüber dem Markt (systematisches Risiko)
# R²    = Erklärungskraft des Modells

cat("=== STEP 5: Market Model Regression (CAPM) ===\n")
capm_model <- lm(r_stock ~ r_market, data = est_data)
print(summary(capm_model))

alpha_hat <- coef(capm_model)[1]
beta_hat  <- coef(capm_model)[2]
r_squared <- summary(capm_model)$r.squared

cat("\nGeschätztes Alpha:", round(alpha_hat, 6), "\n")
cat("Geschätztes Beta: ", round(beta_hat,  4),  "\n")
cat("R²:               ", round(r_squared, 4),  "\n\n")

# Sensitivitätsanalyse: Was passiert mit Beta bei kürzerem Estimation Window?
cat("--- Sensitivitätsanalyse Beta ---\n")
for (tage in c(60, 120, 180, 252)) {
  est_sens <- returns_df %>%
    filter(date >= (estimation_end - tage) & date <= estimation_end)
  if (nrow(est_sens) >= 20) {
    beta_sens <- coef(lm(r_stock ~ r_market, data = est_sens))[2]
    cat("Beta bei", tage, "Tagen Estimation Window:", round(beta_sens, 4), "\n")
  }
}
cat("\n")


# =============================================================================
# STEP 6: Calculate Abnormal Return and p-Value (T-Test)
# =============================================================================
# AR_t = r_stock_t - (alpha + beta * r_market_t)
#      = tatsächliche Rendite - erwartete Rendite laut CAPM
#
# T-Test: Ist die abnormale Rendite statistisch signifikant?
# H0: AR = 0 (keine abnormale Rendite)
# H1: AR ≠ 0 (signifikante abnormale Rendite)

cat("=== STEP 6: Abnormal Return und T-Test ===\n")

# Residualstandardabweichung aus dem CAPM-Modell
sigma <- summary(capm_model)$sigma

event_data <- returns_df %>%
  filter(date >= event_window_start & date <= event_window_end) %>%
  mutate(
    expected_return = alpha_hat + beta_hat * r_market,
    AR              = r_stock - expected_return,
    CAR             = cumsum(AR),
    t_stat          = AR / sigma,           # T-Statistik
    p_value         = 2 * (1 - pt(abs(t_stat), df = nrow(est_data) - 2)),  # p-Wert (zweiseitig)
    signifikant     = p_value < 0.05,       # Signifikant bei 5% Niveau?
    event_day       = as.numeric(date - event_date),
    is_event        = (date == event_date)
  )

cat("\nErgebnistabelle:\n")
print(event_data %>%
        select(date, event_day, r_stock, expected_return, AR, CAR, t_stat, p_value, signifikant) %>%
        mutate(across(where(is.numeric), ~ round(., 5))))

# Kennzahlen am Event-Tag
AR_event  <- event_data %>% filter(is_event) %>% pull(AR)
p_event   <- event_data %>% filter(is_event) %>% pull(p_value)
t_event   <- event_data %>% filter(is_event) %>% pull(t_stat)
CAR_total <- tail(event_data$CAR, 1)

cat("\n=== ERGEBNISSE ===\n")
cat("Abnormale Rendite am Event-Tag (AR_0):     ", round(AR_event * 100, 3), "%\n")
cat("T-Statistik:                               ", round(t_event, 4), "\n")
cat("p-Wert:                                    ", round(p_event, 4), "\n")
cat("Statistisch signifikant (5% Niveau):       ", ifelse(p_event < 0.05, "JA", "NEIN"), "\n")
cat("Kumulierte abnormale Rendite (CAR):        ", round(CAR_total * 100, 3), "%\n\n")

if (p_event < 0.05) {
  cat("Interpretation: Die abnormale Rendite ist statistisch signifikant.\n")
  cat("H0 (AR=0) wird abgelehnt – die Marktreaktion ist nicht zufällig.\n")
} else {
  cat("Interpretation: Die abnormale Rendite ist NICHT statistisch signifikant.\n")
  cat("H0 (AR=0) kann nicht abgelehnt werden.\n")
}


# --- Visualisierung ---------------------------------------------------------

# Plot 1: Abnormale Renditen (AR)
p1 <- ggplot(event_data, aes(x = event_day, y = AR * 100)) +
  geom_col(aes(fill = AR > 0), width = 0.7, alpha = 0.85) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "red", linewidth = 1) +
  annotate("text", x = 0.3, y = max(event_data$AR * 100) * 0.9,
           label = "Event\n(26. Feb 2026)", color = "red", hjust = 0, size = 3.5) +
  scale_fill_manual(values = c("TRUE" = "#2ecc71", "FALSE" = "#e74c3c"),
                    labels = c("TRUE" = "Positiv", "FALSE" = "Negativ"), name = "AR") +
  scale_x_continuous(breaks = seq(-event_window_pre, event_window_post, by = 2)) +
  labs(title = "Step 6: Abnormale Renditen (AR) – NVIDIA Event Study",
       subtitle = paste0("Event Window: [", -event_window_pre, ", +", event_window_post,
                         "] | p-Wert Event-Tag: ", round(p_event, 4)),
       x = "Handelstage relativ zum Event (t=0)", y = "Abnormale Rendite (%)") +
  theme_minimal(base_size = 13) + theme(legend.position = "bottom")
print(p1)

# Plot 2: Kumulierte Abnormale Renditen (CAR)
p2 <- ggplot(event_data, aes(x = event_day, y = CAR * 100)) +
  geom_line(color = "#2980b9", linewidth = 1.2) +
  geom_point(color = "#2980b9", size = 2.5) +
  geom_point(data = filter(event_data, is_event),
             aes(x = event_day, y = CAR * 100),
             color = "red", size = 4, shape = 18) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "red", linewidth = 1) +
  geom_hline(yintercept = 0, color = "gray50", linewidth = 0.5) +
  scale_x_continuous(breaks = seq(-event_window_pre, event_window_post, by = 2)) +
  labs(title = "Kumulierte Abnormale Renditen (CAR) – NVIDIA Event Study",
       subtitle = paste0("CAR gesamt: ", round(CAR_total * 100, 2), "% | Roter Punkt = Event-Tag"),
       x = "Handelstage relativ zum Event (t=0)", y = "Kumulierte abnormale Rendite (%)") +
  theme_minimal(base_size = 13)
print(p2)

# --- Optional: Plots speichern ---
# ggsave("plot_AR.png",  plot = p1, width = 10, height = 6, dpi = 150)
# ggsave("plot_CAR.png", plot = p2, width = 10, height = 6, dpi = 150)

cat("\nFertig! Alle 6 Schritte abgeschlossen.\n")