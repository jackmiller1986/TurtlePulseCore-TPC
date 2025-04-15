# Armored Turtle Automated Filament Changer
#
# Copyright (C) 2024 Armored Turtle
#
# This file may be distributed under the terms of the GNU GPLv3 license.

from configparser import Error as error

# Import der Standardklasse
try:
    from extras.AFC_BoxTurtle import afcBoxTurtle
except Exception as e:
    raise error(
        "Fehler beim Import von AFC_BoxTurtle.\n"
        "Bitte führe das Installationsskript erneut aus: ./install-afc.sh\n"
        f"Originalfehler: {str(e)}"
    )

# Spezialklasse TurtleCore, erbt von afcBoxTurtle
class afcTurtleCore(afcBoxTurtle):
    def __init__(self, config):
        super().__init__(config)
        self.type = config.get('type', 'TurtleCore')

    def handle_connect(self):
        """
        Handle the connection event.
        Wird aufgerufen, wenn der Drucker verbunden ist.
        """
        super().handle_connect()

        self.logo = '<span class=success--text>TurtleCore Ready</span>\n'
        self.logo += '<span class=success--text>  ,----,      \n'
        self.logo += ' (  o  o )     \n'
        self.logo += '  \\_--_/____ \n'
        self.logo += '  /      \\  \n'
        self.logo += ' |  ----  | \n'
        self.logo += '  \\______/  </span>\n'

        self.logo_error = '<span class=error--text>TurtleCore Not Ready</span>\n'

# Diese Methode wird von Klipper beim Laden des Moduls verwendet
def load_config_prefix(config):
    try:
        section_type, section_name = config.get_name().split(None, 1)
    except ValueError:
        raise error(f"Ungültiger Abschnittsname: {config.get_name()} (erwarte: [AFC_BoxTurtle <Name>])")

    if section_type == "AFC_BoxTurtle":
        type_value = config.get('type', '').lower()
        if type_value == "turtlecore":
            return afcTurtleCore(config)
        else:
            return afcBoxTurtle(config)

    raise error(f"Unbekannter Abschnittstyp: {section_type}")
