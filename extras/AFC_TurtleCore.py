# Armored Turtle Automated Filament Changer
#
# Copyright (C) 2024 Armored Turtle
#
# This file may be distributed under the terms of the GNU GPLv3 license.
from configparser import Error as error
try:
    from extras.AFC_BoxTurtle import afcBoxTurtle
except:
    raise error("Error trying to import AFC_BoxTurtle, please rerun install-afc.sh script in your AFC-Klipper-Add-On directory then restart klipper")

class afcTurtleCore(afcBoxTurtle):
    def __init__(self, config):
        super().__init__(config)
        self.type = config.get('type', 'Turtle_Core')

    def handle_connect(self):
        """
        Handle the connection event.
        This function is called when the printer connects. It looks up AFC info
        and assigns it to the instance variable `self.AFC`.
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

def load_config_prefix(config):
    return afcTurtleCore(config)
