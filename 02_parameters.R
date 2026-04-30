# =============================================================================
# 02_parameters.R
# Alle Parameter der Event Study zentral definieren
# =============================================================================
# Hier sind ALLE Einstellungen an einem Ort.
# Möchtest du etwas ändern (z.B. anderes Event-Datum oder andere Aktie),
# musst du NUR diese Datei anpassen – alle R-Skripte passen sich automatisch an.
# (Hinweis: Die Text-Dokumentation in der README.md muss manuell aktualisiert werden!)
# =============================================================================

# --- Event -------------------------------------------------------------------
event_date        <- as.Date("2026-02-26")  #  statistische Event-Datum ($t=0$): 26.02.2026

# --- Event Window ------------------------------------------------------------
# Wie viele Handelstage VOR und NACH dem Event betrachten wir?
# Trade-Off: Breiter = mehr Vorabeffekte erfasst, aber mehr Rauschen
event_window_pre  <- 1   # Tage VOR dem Event  (t = -1)
event_window_post <- 1   # Tage NACH dem Event (t = +1)

# --- Estimation Window -------------------------------------------------------
# Wie viele Handelstage vor dem Event Window schätzen wir Beta?
# Standard in der Literatur: 120-252 Handelstage (ca. 6-12 Monate)
# Trade-Off: Mehr Tage = stabileres Beta, aber ältere Daten könnten veraltet sein
estimation_days   <- 365  # 365 Kalendertage ≈ 252 Handelstage (1 Börsenjahr)

# --- Ticker ------------------------------------------------------------------
ticker_stock  <- "NVDA"   # NVIDIA-Aktie
ticker_market <- "^GSPC"  # S&P 500 als Marktindex (Market Proxy)

# --- Abgeleitete Datumsgrenzen (Berechnung erfolgt automatisch) --------------
# Diese Werte basieren auf den obigen Eingaben und müssen i.d.R. nicht manuell geändert werden.-----------------------------------------------
event_window_start <- event_date - event_window_pre
event_window_end   <- event_date + event_window_post
estimation_end     <- event_window_start - 1
estimation_start   <- estimation_end - estimation_days
start_date         <- estimation_start - 30  # Puffer für Renditeberechnung (Kurs t-1) & Schließtage (Wochenenden/Feiertage)
end_date           <- event_window_end + 5 # Kleiner Puffer am Ende, um den vollständigen Zeitraum sicher abzurufen

cat("=== Parameter geladen ===\n")
cat("Event-Datum:       ", format(event_date), "\n")
cat("Event Window:      [", -event_window_pre, ", +", event_window_post, "]\n")
cat("Estimation Period: ", format(estimation_start), "bis", format(estimation_end), "\n\n")
