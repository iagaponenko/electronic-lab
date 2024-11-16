from .device import Device
import pyvisa

class SDS1102X(Device):
    '''
    SDS1102X - SDS1000X/X+ Series Super Phosphor Oscilloscope.
    General specs:
        100 MHz bandwidth model
        Real-time sampling rate up to 1 GSa/s
        Waveform capture rate up to 60,000 wfm/s (normal mode), and 400,000 wfm/s (sequence mode)
        Supports 256-level intensity grading and color display modes
        Record length up to 14 Mpts
        Digital trigger system
        Channels: 2 CH

    More info at:
        https://siglentna.com/digital-oscilloscopes/sds1000xx-series-super-phosphor-oscilloscopes/

    Programming Guide:
        https://siglentna.com/wp-content/uploads/dlm_uploads/2017/10/ProgrammingGuide_forSDS-1-1.pdf
    '''

    def __init__(self, ipaddr, verbose=False):
        super().__init__(ipaddr, 'SDS1102X', verbose)

    def STATUS_PRESET(self): self.instr().write("STATUS:PRESET")
