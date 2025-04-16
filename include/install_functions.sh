#!/usr/bin/env bash
# Armored Turtle Automated Filament Changer
#
# Copyright (C) 2024 Armored Turtle
#
# This file may be distributed under the terms of the GNU GPLv3 license.

check_dirs() {
  if [ ! -d "${afc_path}/include/" ]; then
    echo "Directory ${afc_path}/include/ does not exist."
    exit 1
  fi

  if [ -z "$(ls -A "${afc_path}/include/")" ]; then
    echo "No files found in ${afc_path}/include/"
    exit 1
  fi
}

link_extensions() {
  if [ -d "${klipper_dir}/klippy/extras" ]; then
    for extension in "${afc_path}"/extras/*.py; do
      ln -sf "${afc_path}/extras/$(basename "${extension}")" "${klipper_dir}/klippy/extras/$(basename "${extension}")"
    done
  else
    export message="AFC Klipper extensions not installed; Klipper extras directory not found."
  fi
}

unlink_extensions() {
  if [ -d "${klipper_dir}/klippy/extras" ]; then
    for extension in "${afc_path}"/extras/*.py; do
      rm -f "${klipper_dir}/klippy/extras/$(basename "${extension}")"
    done
  else
    print_msg ERROR "AFC Klipper extensions not uninstalled; Klipper extras directory not found."
    exit 1
  fi
}

copy_unit_files() {
  if [ "$installation_type" == "BoxTurtle" ]; then
    cp "${afc_path}/templates/AFC_Hardware-AFC.cfg" "${afc_config_dir}/AFC_Hardware.cfg"
    cp "${afc_path}/templates/AFC_Turtle_1.cfg" "${afc_config_dir}/AFC_Turtle_1.cfg"
  elif [ "$installation_type" == "NightOwl" ]; then
    cp "${afc_path}/templates/AFC_Hardware-NightOwl.cfg" "${afc_config_dir}/AFC_Hardware.cfg"
    cp "${afc_path}/templates/AFC_NightOwl_1.cfg" "${afc_config_dir}/AFC_NightOwl_1.cfg"
  elif [ "$installation_type" == "TurtleCore" ]; then
    cp "${afc_path}/templates/AFC_Hardware-TurtleCore.cfg" "${afc_config_dir}/AFC_Hardware.cfg"
    cp "${afc_path}/templates/AFC_TurtleCore_1.cfg" "${afc_config_dir}/AFC_TurtleCore_1.cfg"
  fi
}

install_afc() {
  link_extensions
  copy_config
  copy_unit_files
  exclude_from_klipper_git

  if [ "$afc_includes" == True ]; then
    manage_include "${printer_config_dir}/printer.cfg" "add"
  fi

  update_config_value "${afc_file}" "Type" "${installation_type}"
  update_config_value "${afc_file}" "park" "${park_macro}"
  update_config_value "${afc_file}" "poop" "${poop_macro}"
  update_config_value "${afc_file}" "form_tip" "${tip_forming}"
  update_config_value "${afc_file}" "tool_cut" "${toolhead_cutter}"
  update_config_value "${afc_file}" "hub_cut" "${hub_cutter}"
  update_config_value "${afc_file}" "kick" "${kick_macro}"
  update_config_value "${afc_file}" "wipe" "${wipe_macro}"

  if [ "$toolhead_sensor" == "Sensor" ]; then
    update_switch_pin "${afc_config_dir}/AFC_Hardware.cfg" "${toolhead_sensor_pin}"
  elif [ "$toolhead_sensor" == "Ramming" ]; then
    update_switch_pin "${afc_config_dir}/AFC_Hardware.cfg" "buffer"
  fi

  if [ "$buffer_type" == "TurtleNeck" ]; then
    query_tn_pins "TN"
    append_buffer_config "TurtleNeck" "$tn_advance_pin" "$tn_trailing_pin"
    add_buffer_to_extruder "${afc_config_dir}/AFC_Turtle_1.cfg" "Turtle_1"
  elif [ "$buffer_type" == "TurtleNeckV2" ]; then
    append_buffer_config "TurtleNeckV2"
    add_buffer_to_extruder "${afc_config_dir}/AFC_Turtle_1.cfg" "Turtle_1"
  fi

  check_and_append_prep "${afc_config_dir}/AFC.cfg"

  if [ "$installation_type" == "TurtleCore" ]; then
    sed -i 's/^\[include mcu\/AFC_Lite.cfg\]/#[include mcu\/AFC_Lite.cfg]/' "${afc_config_dir}/AFC.cfg"
  fi

  replace_varfile_path "${afc_config_dir}/AFC.cfg"
  update_moonraker_config

  message="""
- AFC Configuration updated with selected options at ${afc_file}
- AFC-Klipper-Add-On python extensions installed to ${klipper_dir}/klippy/extras/
"""

  if [ "$installation_type" == "BoxTurtle" ]; then
    message+="""
- Enter your CAN bus or serial info in ${afc_config_dir}/AFC_Turtle_1.cfg"""
  elif [ "$installation_type" == "NightOwl" ]; then
    message+="""
- Enter your CAN bus or serial info in ${afc_config_dir}/AFC_NightOwl_1.cfg"""
  elif [ "$installation_type" == "TurtleCore" ]; then
    message+="""
- Enter your CAN bus or serial info in ${afc_config_dir}/AFC_TurtleCore_1.cfg"""
  fi

  if [ "$buffer_type" == "TurtleNeckV2" ]; then
    message+="""
- Add correct serial info to ${afc_config_dir}/mcu/TurtleNeckv2.cfg"""
  fi

  message+="""
You may now quit the script or return to the main menu.
"""

  export message
  files_updated_or_installed="True"
}
