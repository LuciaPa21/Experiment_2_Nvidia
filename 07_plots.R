# =============================================================================
# 07_plots.R
# Alle Visualisierungen der Event Study
# =============================================================================
# Plot 1: Abnormale Renditen (AR) als Balkendiagramm
# Plot 2: Kumulierte Abnormale Renditen (CAR) als Linienchart
# Plot 3: Sensitivitätsanalyse CAR-Vergleich
#
# Zum Speichern: ggsave()-Zeilen am Ende einkommentieren
# =============================================================================

cat("=== Erstelle Plots ===\n")

# --- Plot 1: Abnormale Renditen (AR) -----------------------------------------
p1 <- ggplot(event_data, aes(x = event_day, y = AR * 100)) +
  geom_col(aes(fill = AR > 0), width = 0.7, alpha = 0.85) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "red", linewidth = 1) +
  annotate("text", x = 0.3, y = max(event_data$AR * 100) * 0.9,
           label = "Event\n(26. Feb 2026)", color = "red", hjust = 0, size = 3.5) +
  scale_fill_manual(values = c("TRUE" = "#2ecc71", "FALSE" = "#e74c3c"),
                    labels = c("TRUE" = "Positiv", "FALSE" = "Negativ"), name = "AR") +
  scale_x_continuous(breaks = seq(-event_window_pre, event_window_post, by = 2)) +
  labs(
    title    = "Abnormale Renditen (AR) – NVIDIA Event Study",
    subtitle = paste0("Event Window: [", -event_window_pre, ", +", event_window_post,
                      "] | p-Wert Event-Tag: ", round(p_event, 4)),
    x = "Handelstage relativ zum Event (t=0)",
    y = "Abnormale Rendite (%)"
  ) +
  theme_minimal(base_size = 13) +
  theme(legend.position = "bottom")
print(p1)

# --- Plot 2: Kumulierte Abnormale Renditen (CAR) -----------------------------
p2 <- ggplot(event_data, aes(x = event_day, y = CAR * 100)) +
  geom_line(color = "#2980b9", linewidth = 1.2) +
  geom_point(color = "#2980b9", size = 2.5) +
  geom_point(data = filter(event_data, is_event),
             aes(x = event_day, y = CAR * 100),
             color = "red", size = 4, shape = 18) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "red", linewidth = 1) +
  geom_hline(yintercept = 0, color = "gray50", linewidth = 0.5) +
  scale_x_continuous(breaks = seq(-event_window_pre, event_window_post, by = 2)) +
  labs(
    title    = "Kumulierte Abnormale Renditen (CAR) – NVIDIA Event Study",
    subtitle = paste0("CAR gesamt: ", round(CAR_total * 100, 2), "% | Roter Punkt = Event-Tag"),
    x = "Handelstage relativ zum Event (t=0)",
    y = "Kumulierte abnormale Rendite (%)"
  ) +
  theme_minimal(base_size = 13)
print(p2)

# --- Grafik für GitHub speichern ---

# Ordner 'plots' erstellen, falls er noch nicht da ist
if (!dir.exists("plots")) {
  dir.create("plots")
}

# Speichert die CAR-Grafik (p2) als PNG-Datei
ggsave(filename = "plots/car_plot.png", 
       plot = p2, 
       width = 8, 
       height = 5, 
       dpi = 300)

# --- NEU: Plot 2b: Vergleich Erwartung vs. Realität (Das Paradoxon) -----------

# Wir filtern die Daten für den Event-Tag (t=0)
event_day_data <- subset(event_data, is_event)

# Daten für den Vergleichsplot vorbereiten
comp_data <- data.frame(
  Typ = c("Realität (Tatsächlich)", "Modell (Erwartet)"),
  Rendite = c(event_day_data$r_stock * 100, event_day_data$expected_return * 100)
)

# --- DER ULTIMATIVE BRECHEISEN-FIX ---
p2b <- ggplot(comp_data, aes(x = Typ, y = as.numeric(Rendite), fill = Typ)) +
  geom_col(width = 0.5, alpha = 0.9) +
  scale_fill_manual(values = c("Realität (Tatsächlich)" = "#e74c3c", 
                               "Modell (Erwartet)" = "#3498db")) +
  # Wir erzwingen hier die Skala von +0.5 bis -5.5
  coord_cartesian(ylim = c(-5.5, 0.5)) +
  scale_y_continuous(breaks = seq(-5, 0, by = 1)) +
  labs(
    title = "NVIDIA Paradoxon: Gute Zahlen, fallender Kurs",
    subtitle = paste0("Abnormale Rendite: ", round(event_day_data$AR * 100, 2), "%"),
    y = "Rendite (%)",
    x = ""
  ) +
  theme_minimal(base_size = 13) +
  theme(legend.position = "none")

print(p2b)

# Speichern
ggsave(filename = "plots/paradox_comparison.png", plot = p2b, width = 8, height = 5, dpi = 300)

# -----------------------------------------------------------------------------

# --- Plot 3: Sensitivitätsanalyse --------------------------------------------
p3 <- ggplot(sens_results, aes(x = Event_Window, y = CAR_gesamt, fill = CAR_gesamt > 0)) +
  geom_col(width = 0.5, alpha = 0.85) +
  geom_hline(yintercept = 0, color = "gray50", linewidth = 0.5) +
  scale_fill_manual(values = c("TRUE" = "#2ecc71", "FALSE" = "#e74c3c"), guide = "none") +
  labs(
    title    = "Sensitivitätsanalyse: CAR bei verschiedenen Event Windows",
    subtitle = "NVIDIA Event Study – Robustheit des Ergebnisses",
    x        = "Event Window",
    y        = "Kumulierte abnormale Rendite (%)"
  ) +
  theme_minimal(base_size = 13)
print(p3)

# --- Optional: Plots speichern -----------------------------------------------
# ggsave("plot_AR.png",            plot = p1, width = 10, height = 6, dpi = 150)
# ggsave("plot_CAR.png",           plot = p2, width = 10, height = 6, dpi = 150)
# ggsave("plot_sensitivity.png",   plot = p3, width = 10, height = 6, dpi = 150)

cat("Alle Plots erstellt!\n")
