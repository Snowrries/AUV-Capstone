#!/usr/bin/env python
'''
Calvin Li
April 2017


This module sends commands that direct which propellers should spin and when. Orients vehicle in correct direction,
according to data passed to it from auv_process.py
'''

import os
import os.path
import sys
from pymavlink import mavutil
import errno
import time

from MAVProxy.modules.lib import mp_module
from MAVProxy.modules.lib import mp_util
from MAVProxy.modules.lib import mp_settings


class propellers(mp_module.MPModule):
    def __init__(self, mpstate):
        """Initialise module"""
        super(propellers, self).__init__(mpstate, "propellers", "")
        self.status_callcount = 0
        self.boredom_interval = 1 #seconds
        self.last_bored = time.time()

        self.packets_mytarget = 0
        self.packets_othertarget = 0
        self.verbose = False

        self.propellers_settings = mp_settings.MPSettings(
            [ ('verbose', bool, True),
          ])
        self.add_command('propellers', self.cmd_propellers, "auv_propellers module", ['status','set (LOGSETTING)'])

    def usage(self):
        '''show help on command line options'''
        return "Usage: propellers <status|set>"

    def cmd_propellers(self, args):
        '''control behaviour of the module'''
        if len(args) == 0:
            print self.usage()
        elif args[0] == "status":
            print self.status()
        elif args[0] == "set":
            self.propellers_settings.command(args[1:])
        else:
            print self.usage()

    def status(self):
        '''returns information about module'''
        self.status_callcount += 1
        self.last_bored = time.time() # status entertains us
        return("status called %(status_callcount)d times.  My target positions=%(packets_mytarget)u  Other target positions=%(packets_mytarget)u" %
               {"status_callcount": self.status_callcount,
                "packets_mytarget": self.packets_mytarget,
                "packets_othertarget": self.packets_othertarget,
               })

    def boredom_message(self):
        if self.propellers_settings.verbose:
            return ("I'm very bored")
        return ("I'm bored")

    def idle_task(self):
        '''called rapidly by mavproxy'''
        now = time.time()
        if now-self.last_bored > self.boredom_interval:
            self.last_bored = now
            message = self.boredom_message()
            self.say("%s: %s" % (self.name,message))
            # See if whatever we're connected to would like to play:
            self.master.mav.statustext_send(mavutil.mavlink.MAV_SEVERITY_NOTICE,
                                            message)

    def mavlink_packet(self, m):
        '''handle mavlink packets'''
        if m.get_type() == 'GLOBAL_POSITION_INT':
            if self.settings.target_system == 0 or self.settings.target_system == m.get_srcSystem():
                self.packets_mytarget += 1
            else:
                self.packets_othertarget += 1

def init(mpstate):
    '''initialise module'''
    return propellers(mpstate)
