# =============================================================================
# 02_parameters.R
# Alle Parameter der Event Study zentral definieren
# =============================================================================
# Hier sind ALLE Einstellungen an einem Ort.
# Möchtest du etwas ändern (z.B. anderes Event-Datum oder andere Aktie),
# musst du NUR diese Datei anpassen – der Rest passt sich automatisch an.
# =============================================================================

# --- Event -------------------------------------------------------------------
event_date        <- as.Date("2026-02-26")  # Tag der Earnings-Veröffentlichung
# Quelle: Aufgabenstellung, Thema 3 – CAPM und Event Study

# --- Event Window ------------------------------------------------------------
# Wie viele Handelstage VOR und NACH dem Event betrachten wir?
# Trade-Off: Breiter = mehr Vorabeffekte erfasst, aber mehr Rauschen
event_window_pre  <- 10   # Tage VOR dem Event  (t = -10)
event_window_post <- 10   # Tage NACH dem Event (t = +10)

# --- Estimation Window -------------------------------------------------------
# Wie viele Handelstage vor dem Event Window schätzen wir Beta?
# Standard in der Literatur: 120-252 Handelstage (ca. 6-12 Monate)
# Trade-Off: Mehr Tage = stabileres Beta, aber ältere Daten könnten veraltet sein
estimation_days   <- 252  # ca. 1 Jahr

# --- Ticker ------------------------------------------------------------------
ticker_stock  <- "NVDA"   # NVIDIA-Aktie
ticker_market <- "^GSPC"  # S&P 500 als Marktindex (Market Proxy)

# --- Abgeleitete Datumsgrenzen -----------------------------------------------
event_window_start <- event_date - event_window_pre
event_window_end   <- event_date + event_window_post
estimation_end     <- event_window_start - 1
estimation_start   <- estimation_end - estimation_days
start_date         <- estimation_start - 30  # Puffer für Wochenenden etc.
end_date           <- event_window_end + 5

cat("=== Parameter geladen ===\n")
cat("Event-Datum:       ", format(event_date), "\n")
cat("Event Window:      [", -event_window_pre, ", +", event_window_post, "]\n")
cat("Estimation Period: ", format(estimation_start), "bis", format(estimation_end), "\n\n")
