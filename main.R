# =============================================================================
# main.R
# Hauptskript – ruft alle Teilskripte der Reihe nach auf
# =============================================================================
# Einfach dieses Skript ausführen (Source-Button oder Strg+Shift+Enter)
# und die gesamte Event Study läuft durch.
#
# Reihenfolge:
#   01 Pakete laden
#   02 Parameter definieren
#   03 Daten herunterladen
#   04 CAPM-Regression
#   05 Abnormale Renditen berechnen
#   06 Sensitivitätsanalyse
#   07 Plots erstellen
# =============================================================================

cat("=====================================\n")
cat("  NVIDIA Event Study – Start\n")
cat("=====================================\n\n")

source("01_packages.R")
source("02_parameters.R")
source("03_data.R")
source("04_capm.R")
source("05_abnormal_returns.R")
source("06_sensitivity.R")
source("07_plots.R")

cat("\n=====================================\n")
cat("  Fertig! Alle Schritte abgeschlossen\n")
cat("=====================================\n")
