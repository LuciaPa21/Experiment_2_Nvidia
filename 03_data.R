# =============================================================================
# 03_data.R
# Step 3: Data Gathering
# =============================================================================
# Kursdaten für NVIDIA und den S&P 500 von Yahoo Finance herunterladen
# und Log-Renditen berechnen.
#
# Log-Renditen: r_t = ln(P_t / P_{t-1})
# Vorteil gegenüber einfachen Renditen: additiv und annähernd normalverteilt
# =============================================================================

cat("=== STEP 3: Data Gathering ===\n")
cat("Lade Daten von Yahoo Finance...\n")

# --- Kursdaten herunterladen -------------------------------------------------
getSymbols(ticker_stock,  src = "yahoo", from = start_date, to = end_date, auto.assign = TRUE)
getSymbols(ticker_market, src = "yahoo", from = start_date, to = end_date, auto.assign = TRUE)

# --- Adjusted Closing Prices -------------------------------------------------
# "Adjusted" = bereinigt um Dividenden und Aktiensplits -> vergleichbarer
prices_stock  <- Ad(NVDA)
prices_market <- Ad(GSPC)

# --- Log-Renditen berechnen --------------------------------------------------
returns_stock  <- dailyReturn(prices_stock,  type = "log")
returns_market <- dailyReturn(prices_market, type = "log")

# Ersten NA-Wert entfernen (entsteht durch die Differenzbildung)
returns_stock  <- returns_stock[-1]
returns_market <- returns_market[-1]

# --- Gemeinsamen Data Frame erstellen ----------------------------------------
returns_df <- merge(returns_stock, returns_market)
colnames(returns_df) <- c("r_stock", "r_market")
returns_df <- as.data.frame(returns_df)
returns_df$date <- as.Date(rownames(returns_df))
rownames(returns_df) <- NULL

# --- Estimation Window filtern -----------------------------------------------
est_data <- returns_df %>%
  filter(date >= estimation_start & date <= estimation_end)

cat("Daten erfolgreich geladen!\n")
cat("Gesamte Handelstage im Datensatz:", nrow(returns_df), "\n")
cat("Handelstage im Estimation Window:", nrow(est_data), "\n\n")

if (nrow(est_data) < 30) {
  stop("Zu wenige Datenpunkte im Estimation Window! Bitte estimation_days erhöhen.")
}
