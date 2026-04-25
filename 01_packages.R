# =============================================================================
# 01_packages.R
# Pakete installieren und laden
# =============================================================================
# Dieses Skript wird als erstes ausgeführt.
# Es stellt sicher dass alle benötigten Pakete vorhanden sind.
#
# Beim allerersten Mal: Die install.packages()-Zeilen einkommentieren,
# danach können sie wieder auskommentiert bleiben.
# =============================================================================

# --- Pakete installieren (nur einmalig nötig) --------------------------------
# install.packages(c("quantmod", "ggplot2", "dplyr", "lubridate"))

# --- Pakete laden (bei jedem Start nötig) ------------------------------------
library(quantmod)   # Finanzdaten von Yahoo Finance herunterladen
library(ggplot2)    # Visualisierung
library(dplyr)      # Datentransformation
library(lubridate)  # Datumsverarbeitung

cat("Alle Pakete erfolgreich geladen.\n")
