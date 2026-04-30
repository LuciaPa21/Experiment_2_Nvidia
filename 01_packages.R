# =============================================================================
# 01_packages.R
# Pakete installieren und laden
# =============================================================================
# Dieses Skript wird als erstes ausgeführt.
# Es stellt sicher dass alle benötigten Pakete vorhanden sind.
#
# Fehlende Pakete werden automatisch installiert 
# =============================================================================

# --- Fehlende Pakete automatisch installieren --------------------------------
packages <- c("quantmod", "ggplot2", "dplyr", "lubridate")

new_packages <- packages[!(packages %in% installed.packages()[, "Package"])]
if (length(new_packages) > 0) {
  cat("Installiere fehlende Pakete:", paste(new_packages, collapse = ", "), "\n")
  install.packages(new_packages)
}

# --- Pakete laden (bei jedem Start nötig) ------------------------------------
library(quantmod)   # Finanzdaten von Yahoo Finance herunterladen
library(ggplot2)    # Visualisierung
library(dplyr)      # Datentransformation
library(lubridate)  # Datumsverarbeitung

cat("Alle Pakete erfolgreich geladen.\n")
