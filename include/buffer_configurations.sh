#!/usr/bin/env bash
# Armored Turtle Automated Filament Changer
#
# Copyright (C) 2024 Armored Turtle
#
# This file may be distributed under the terms of the GNU GPLv3 license.

append_buffer_config() {
  local buffer_type="$1"
  local buffer_config=""
  local buffer_name=""
  tn_advance_pin=$2
  tn_trailing_pin=$3

  # 🛑 Überspringe bei TurtleCore + TurtleNeck
  if [ "$installation_type" == "TurtleCore" ] && [ "$buffer_type" == "TurtleNeck" ]; then
    print_msg INFO "Überspringe das Hinzufügen des Buffers '$buffer_type' bei Installationstyp 'TurtleCore'."
    return 0
  fi

  case "$buffer_type" in
    "TurtleNeck")
      buffer_config=$(cat <<EOF
[AFC_buffer Turtle_1]
advance_pin: ${tn_advance_pin}    # set advance pin
trailing_pin: ${tn_trailing_pin}  # set trailing pin
multiplier_high: 1.05   # default 1.05, factor to feed more filament
multiplier_low:  0.95   # default 0.95, factor to feed less filament
velocity: 0
EOF
)
      buffer_name="Turtle_1"
      ;;
    "TurtleNeckV2")
      buffer_config=$(cat <<'EOF'
[AFC_buffer Turtle_1]
advance_pin: !turtleneck:ADVANCE
trailing_pin: !turtleneck:TRAILING
multiplier_high: 1.05   # default 1.05, factor to feed more filament
multiplier_low:  0.95   # default 0.95, factor to feed less filament
led_index: Buffer_Indicator:1
velocity: 0

[AFC_led Buffer_Indicator]
pin: turtleneck:RGB
chain_count: 1
color_order: GRBW
initial_RED: 0.0
initial_GREEN: 0.0
initial_BLUE: 0.0
initial_WHITE: 0.0
EOF
)
      buffer_name="Turtle_1"
      ;;
    *)
      echo "Ungültiger BUFFER_SYSTEM: $buffer_type"
      return 1
      ;;
  esac

  # Konfiguration nur einfügen, wenn sie noch nicht existiert
  if ! grep -qF "$(echo "$buffer_config" | head -n 1)" "$afc_config_dir/AFC_Hardware.cfg"; then
    echo -e "\n$buffer_config" >> "$afc_config_dir/AFC_Hardware.cfg"
  fi

  # Nur für TurtleNeckV2: zusätzliche Konfigurationsdatei einbinden
  if [ "$buffer_type" == "TurtleNeckV2" ]; then
    if ! grep -qF "[include mcu/TurtleNeckv2.cfg]" "$afc_config_dir/AFC_Hardware.cfg"; then
      echo -e "\n[include mcu/TurtleNeckv2.cfg]" >> "$afc_config_dir/AFC_Hardware.cfg"
    fi
  fi
}

add_buffer_to_extruder() {
  # Fügt den buffer: Eintrag in die Sektion [AFC_BoxTurtle Turtle_1] ein.
  local file_path="$1"
  local buffer_name="$2"
  local section="[AFC_BoxTurtle Turtle_1]"
  local buffer_line="buffer: $buffer_name"

  awk -v section="$section" -v buffer="$buffer_line" '
    BEGIN { in_section = 0 }
    $0 == section {
      in_section = 1
      print $0
      next
    }
    in_section && /^$/ {
      print buffer
      in_section = 0
    }
    in_section && /^\[.+\]/ { in_section = 0 }
    { print $0 }
  ' "$file_path" > "$file_path.tmp" && mv "$file_path.tmp" "$file_path"

  print_msg WARNING "Buffer-Zeile '$buffer_line' zur Sektion '$section' in $file_path hinzugefügt."
}

query_tn_pins() {
  # Fragt Benutzer nach den TurtleNeck Pins.
  local buffer_name="$1"
  local input
  tn_advance_pin="^Turtle_1:TN_ADV"
  tn_trailing_pin="^Turtle_1:TN_TRL"

  print_msg INFO "\nBitte gib die PIN-Nummern für den TurtleNeck-Puffer '$buffer_name' ein:"
  print_msg INFO "(Leer lassen für Standardwerte)"
  print_msg INFO "Wichtig: Ein '^' verwenden, wenn es sich um einen AFC-Endschalter-Pin handelt."
  print_msg INFO "(Standard: ^Turtle_1:TN_ADV)"
  print_msg INFO "(Standard: ^Turtle_1:TN_TRL)"

  read -p "  Advance-Pin eingeben (Standard: $tn_advance_pin): " -r input
  if [ -n "$input" ]; then
    tn_advance_pin="$input"
  fi

  read -p "  Trailing-Pin eingeben (Standard: $tn_trailing_pin): " -r input
  if [ -n "$input" ]; then
    tn_trailing_pin="$input"
  fi

  print_msg INFO "Advance-Pin für ${buffer_name}: $tn_advance_pin"
  print_msg INFO "Trailing-Pin für ${buffer_name}: $tn_trailing_pin"
}
