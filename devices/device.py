import pyvisa

class Device:

    '''
    The base class for the devices. It encapsulates data structures
    and operations common to all devices adhering to the standard VISA (VXI-11).
    '''

    def __init__(self, ipaddr, name, verbose=False):
        self._ipaddr = ipaddr
        self._name = name
        self._verbose = verbose
        self._rm = pyvisa.ResourceManager()
        self._instr = self._rm.open_resource("TCPIP0::{}".format(ipaddr))

    def instance(self): return "{}@{}".format(self._name, self._ipaddr)
    def instr(self): return self._instr
    def IDN(self):return self._instr.query("*IDN?")[:-1]

    def RST(self): self._instr.write("*RST")
    def CLS(self): self._instr.write("*CLS")
