import pyvisa
import sys
import time

class BasicWaveParams:

    '''
    Public instance members:
      device    The owner device
      chan:     The channel number

    Public class members:
        units:  The dictionary of theuits of measurement for each attribute
    '''

    keys = {
        'SINE'  : ['FRQ',   'PERI', 'AMP', 'AMPVRMS', 'OFST', 'HLEV', 'LLEV', 'PHSE'],
        'SQUARE': ['FRQ',   'PERI', 'AMP', 'AMPVRMS', 'OFST', 'HLEV', 'LLEV', 'PHSE', 'DUTY'],
        'RAMP'  : ['FRQ',   'PERI', 'AMP', 'AMPVRMS', 'OFST', 'HLEV', 'LLEV', 'PHSE', 'SYM'],
        'PULSE' : ['FRQ',   'PERI', 'AMP', 'AMPVRMS', 'OFST', 'HLEV', 'LLEV',         'WIDTH', 'RISE', 'FALL', 'DLY'],
        'ARB'   : ['FRQ',   'PERI', 'AMP',            'OFST', 'HLEV', 'LLEV', 'PHSE'],
        'DC'    : [                                   'OFST'],
        'NOISE' : ['STDEV', 'MEAN']
    }

    units = {
        'WVTP'   : '',
        'FRQ'    : 'Hz',
        'PERI'   : 's',
        'AMP'    : 'V',
        'AMPVRMS': 'Vrms',
        'OFST'   : 'V',
        'HLEV'   : 'V',
        'LLEV'   : 'V',
        'PHSE'   : 'deg',
        'DUTY'   : '%',
        'SYM'    : '?',
        'WIDTH'  : '?',
        'RISE'   : '?',
        'FALL'   : '?',
        'DLY'    : '?',
        'STDEV'  : 'V',
        'MEAN'   : 'V'
    }

    @staticmethod
    def unit(param):
        context = f"{__class__.__name__}.unit"
        if param not in BasicWaveParams.units:
            raise KeyError(f"{context}: unsupported parameter: {param}")
        return BasicWaveParams.units[param]

    def __init__(self, device, chan):
        self.device = device
        self.chan = chan
        self._data = None           # raw data returned by a query
        self._property = None       # (key,val) pairs for parsed parameters

    def __str__(self):
        if self._data is None: self._update()
        return self._data

    # ----------------------
    # High-level API methods
    # ----------------------

    def save(self):
        '''
        Return a dictionary of the current properties of a device. They keys are the names
        of the properties, and the values are the corresponding measurements. A set of
        the keys depends on the current state of WVTP.

        Suggestd use of the method is to capture a self-consistent snapshot of
        the current settings of an instrument. These settings could be restored back
        using the counterpart method 'restore()'.
        '''
        # Make sure the current state of the device's setting is preloaded
        # into memory.
        if self._property is None: self._update()

        parameters = {}
        for key in self._property.keys():
            parameters[key] = self.__getattribute__(key)
        return parameters

    def restore(self, parameters):
        '''
        Set properties specified in the input dictionary of parameters to be restore.
        Note that the dictionary shall include WVTP. Other properties are optional.
        Though, if present, they must adhere to a valid set of the ones for the requested
        value of WVTP. The method returns a updated set of all properties for
        the given WVTP.

        Suggestd use of the method is to restore a consistent set of instrument setting
        captured by the counterpart method 'save()'.
        '''
        context = f"{__class__.__name__}.restore"

        WVTP_key = 'WVTP'
        if WVTP_key not in parameters.keys():
            raise KeyError(f"{context}: missing parameter: {WVTP_key}")

        WVTP_val = parameters[WVTP_key]
        if WVTP_val not in BasicWaveParams.keys:
            raise KeyError(f"{context}: unsupported value of {WVTP_key}: {WVTP_val}")

        return self._set_WVTP(WVTP_val, BasicWaveParams.keys[WVTP_val], parameters)

    # --------------------------------------------------------------------
    # Medium-level methods for updating a waveform and its full or partial
    # sets of properties.
    # --------------------------------------------------------------------

    def set_SINE(self, **kwargs):
        return self._set_WVTP('SINE', BasicWaveParams.keys['SINE'], kwargs)

    def set_SQUARE(self, **kwargs):
        return self._set_WVTP('SQUARE', BasicWaveParams.keys['SQUARE'], kwargs)

    def set_RAMP(self, **kwargs):
        return self._set_WVTP('RAMP', BasicWaveParams.keys['RAMP'], kwargs)

    def set_PULSE(self, **kwargs):
        return self._set_WVTP('PULSE', BasicWaveParams.keys['PULSE'], kwargs)

    def set_ARB(self, **kwargs):
        return self._set_WVTP('ARB', BasicWaveParams.keys['ARB'], kwargs)

    def set_DC(self, **kwargs):
        return self._set_WVTP('DC', BasicWaveParams.keys['DC'], kwargs)

    def set_NOISE(self, **kwargs):
        return self._set_WVTP('NOISE', BasicWaveParams.keys['NOISE'], kwargs)

    # -----------------------------------------------------------------------
    # Low-level methods for getting/updating a type of a waveform or a single
    # property of the current waveform.
    # -----------------------------------------------------------------------

    @property
    def WVTP(self):
        return self._get('WVTP')
    @WVTP.setter
    def WVTP(self, val): self._set('WVTP', val)


    @property
    def FRQ(self):
        return float(self._get('FRQ')[:-2])
    @FRQ.setter
    def FRQ(self, val): self._set('FRQ', val)


    @property
    def PERI(self):
        return float(self._get('PERI')[:-1])
    @PERI.setter
    def PERI(self, val): self._set('PERI', val)


    @property
    def AMP(self):
        return float(self._get('AMP')[:-1])
    @AMP.setter
    def AMP(self, val): self._set('AMP', val)


    @property
    def AMPVRMS(self):
        return float(self._get('AMPVRMS')[:-4])
    @AMPVRMS.setter
    def AMPVRMS(self, val): self._set('AMPVRMS', val)


    @property
    def OFST(self):
        return float(self._get('OFST')[:-1])
    @OFST.setter
    def OFST(self, val): self._set('OFST', val)


    @property
    def HLEV(self):
        return float(self._get('HLEV')[:-1])
    @HLEV.setter
    def HLEV(self, val): self._set('HLEV', val)


    @property
    def LLEV(self):
        return  float(self._get('LLEV')[:-1])
    @LLEV.setter
    def LLEV(self, val): self._set('LLEV', val)


    @property
    def PHSE(self):
        return self._get('PHSE')
    @PHSE.setter
    def PHSE(self, val): self._set('PHSE', val)


    @property
    def DUTY(self):
        return self._get('DUTY')
    @DUTY.setter
    def DUTY(self, val): self._set('DUTY', val)


    @property
    def SYM(self):
        return self._get('SYM')
    @SYM.setter
    def SYM(self, val): self._set('SYM', val)


    @property
    def WIDTH(self):
        return self._get('WIDTH')
    @WIDTH.setter
    def WIDTH(self, val): self._set('WIDTH', val)


    @property
    def RISE(self):
        return self._get('RISE')
    @RISE.setter
    def RISE(self, val):
        self._set('RISE', val)


    @property
    def FALL(self):
        return self._get('FALL')
    @FALL.setter
    def FALL(self, val):
        self._set('FALL', val)


    @property
    def DLY(self):
        return self._get('DLY')
    @DLY.setter
    def DLY(self, val):
        self._set('DLY', val)


    @property
    def STDEV(self):
        return self._get('STDEV')
    @STDEV.setter
    def STDEV(self, val):
        self._set('STDEV', val)


    @property
    def MEAN(self):
        return self._get('MEAN')
    @MEAN.setter
    def MEAN(self, val):
        self._set('MEAN', val)


    # ----------------------
    # Implementation details
    # ----------------------

    def _set_WVTP(self, WVTP, keys, parameters):

        self.WVTP = WVTP
        for key, value in parameters.items():
            if key == 'WVTP': continue
            if key not in keys:
                raise KeyError(f"{__class__.__name__}.{__name__}: unsupported parameter: {key}")
            self.__setattr__(key, value)

        parameters = {'WVTP': self.WVTP}
        for key in keys:
            parameters[key] = self.__getattribute__(key);
        return parameters

    def _get(self, name):
        if self._data is None: self._update()
        return self._property[name]

    def _set(self, prop, val):
        self.device.instr().write("C{}:BSWV {},{}".format(self.chan, prop, val))
        self._update()

    def _update(self):
        self._property = {}
        self._data = self.device.instr().query("C{}:BSWV?".format(self.chan)).split()[1]
        foldedParams = self._data.split(",")
        for i in range(0, len(foldedParams), 2):
            self._property[foldedParams[i]] = foldedParams[i + 1]



class SDG1032X:

    name = 'SDG1032X'

    def __init__(self, ipaddr, verbose=False):
        self._ipaddr = ipaddr
        self._verbose = verbose
        self._rm = pyvisa.ResourceManager()
        self._instr = self._rm.open_resource("TCPIP0::{}".format(ipaddr))

    def instance(self): return "{}@{}".format(self.name, self._ipaddr)
    def instr(self): return self._instr
    def IDN(self):return self._instr.query("*IDN?")[:-1]

    def RST(self): self._instr.write("*RST")
    def CLS(self): self._instr.write("*CLS")
    def STATUS_PRESET(self): self._instr.write("STATUS:PRESET")

    def BSWV(self, chan=1): return BasicWaveParams(self, chan)
