
from SDG1032X import SDG1032X, BasicWaveParams
import sys
import time

def print_BSWV(chan, BSWV, parameters):
    print(f"C{chan} BSWV {BSWV}")
    for key, value in parameters.items():
        print(f"        {key}\t{value}\t{BasicWaveParams.unit(key)}")


def main():
    device = SDG1032X('192.168.0.20')
    print("instance:", device.instance())
    print("     IDN:", device.IDN())
    print()

    # Reset to the initial state
    device.RST()
    device.CLS()
    device.STATUS_PRESET()

    time.sleep(1)

    # Basic Wave operations
    BSWV = {
        1: device.BSWV(1),
        2: device.BSWV(2)}
    BSWV_saved_parameters = {}
    for chan in [1,2]:
        BSWV_saved_parameters[chan] = BSWV[chan].save()
        print_BSWV(chan, BSWV[chan], BSWV_saved_parameters[chan])
        BSWV[chan].restore(BSWV_saved_parameters[chan])
    print()

    # -------------------------------------------------------------------------------
    kHz = 1000
    for chan in [1,2]:
        BSWV[chan].WVTP    = 'SINE'
        BSWV[chan].FRQ     = 1 * kHz
        BSWV[chan].PERI    = 0.002
        BSWV[chan].AMP     = 3.0
        BSWV[chan].AMPVRMS = 0.5
        BSWV[chan].OFST    = 0.0
        BSWV[chan].HLEV    = 1.0
        BSWV[chan].LLEV    = -1.0
        BSWV[chan].PHSE    = -361.0
        print(f"C{chan} BSWV {BSWV[chan]}")
        print(f"        WVTP    {BSWV[chan].WVTP}\t{BasicWaveParams.unit('WVTP')}")
        print(f"        FRQ     {BSWV[chan].FRQ}\t{BasicWaveParams.unit('FRQ')}")
        print(f"        PERI    {BSWV[chan].PERI}\t{BasicWaveParams.unit('PERI')}")
        print(f"        AMP     {BSWV[chan].AMP}\t{BasicWaveParams.unit('AMP')}")
        print(f"        AMPVRMS {BSWV[chan].AMPVRMS}\t{BasicWaveParams.unit('AMPVRMS')}")
        print(f"        OFST    {BSWV[chan].OFST}\t{BasicWaveParams.unit('OFST')}")
        print(f"        HLEV    {BSWV[chan].HLEV}\t{BasicWaveParams.unit('HLEV')}")
        print(f"        LLEV    {BSWV[chan].LLEV}\t{BasicWaveParams.unit('LLEV')}")
        print(f"        PHSE    {BSWV[chan].PHSE}\t{BasicWaveParams.unit('PHSE')}")
    print()
    time.sleep(2)

    for chan in [1,2]:
        parameters = BSWV[chan].set_SINE(FRQ=2*kHz, AMP=2.5)
        print_BSWV(chan, BSWV[chan], parameters)
    time.sleep(2)

    # -------------------------------------------------------------------------------
    for chan in [1,2]:
        BSWV[chan].WVTP = 'SQUARE'
        BSWV[chan].DUTY = 25
        print(f'C{chan}:BSWV:', BSWV[chan])
        print(f"        WVTP    {BSWV[chan].WVTP}\t{BasicWaveParams.unit('WVTP')}")
        print(f"        DUTY    {BSWV[chan].DUTY}\t{BasicWaveParams.unit('DUTY')}")
    print()
    time.sleep(2)

    for chan in [1,2]:
        parameters = BSWV[chan].set_SQUARE(DUTY=75)
        print_BSWV(chan, BSWV[chan], parameters)
    time.sleep(2)

    # -------------------------------------------------------------------------------
    BSWV[1].WVTP = 'RAMP'
    BSWV[2].WVTP = 'RAMP'
    BSWV[1].SYM = 0
    BSWV[2].SYM = 0
    for chan in [1,2]:
        print(f'C{chan}:BSWV:', BSWV[chan])
    print()
    print("C{}:WVTP:".format(1), BSWV[1].WVTP)
    print("C{}:WVTP:".format(2), BSWV[2].WVTP)
    print("C{}:BSWV.SYM:".format(1), BSWV[1].SYM)
    print("C{}:BSWV.SYM:".format(2), BSWV[2].SYM)
    print()
    time.sleep(2)

    for chan in [1,2]:
        parameters = BSWV[chan].set_RAMP(SYM=25)
        print_BSWV(chan, BSWV[chan], parameters)
    time.sleep(2)

    # -------------------------------------------------------------------------------
    BSWV[1].WVTP = 'PULSE'
    BSWV[2].WVTP = 'PULSE'
    BSWV[1].DUTY = 25
    BSWV[2].DUTY = 25
    BSWV[1].RISE = 15    # [%]
    BSWV[2].RISE = 15    # [%]
    BSWV[1].FALL = 16    # [%]
    BSWV[2].FALL = 16    # [%]
    for chan in [1,2]:
        print(f'C{chan}:BSWV:', BSWV[chan])
    print()
    print("C{}:WVTP:".format(1), BSWV[1].WVTP)
    print("C{}:WVTP:".format(2), BSWV[2].WVTP)
    print("C{}:BSWV.DUTY:".format(1), BSWV[1].DUTY)
    print("C{}:BSWV.DUTY:".format(2), BSWV[2].DUTY)
    print("C{}:BSWV.RISE:".format(1), BSWV[1].RISE)
    print("C{}:BSWV.RISE:".format(2), BSWV[2].RISE)
    print("C{}:BSWV.FALL:".format(1), BSWV[1].FALL)
    print("C{}:BSWV.FALL:".format(2), BSWV[2].FALL)
    print()
    time.sleep(2)

    for chan in [1,2]:
        parameters = BSWV[chan].set_PULSE(RISE=25, FALL=90, DLY=1.5)
        print_BSWV(chan, BSWV[chan], parameters)
    time.sleep(2)

    # -------------------------------------------------------------------------------
    BSWV[1].WVTP = 'ARB'
    BSWV[2].WVTP = 'ARB'
    for chan in [1,2]:
        print(f'C{chan}:BSWV:', BSWV[chan])
    print()
    print("C{}:WVTP:".format(1), BSWV[1].WVTP)
    print("C{}:WVTP:".format(2), BSWV[2].WVTP)
    time.sleep(2)

    # -------------------------------------------------------------------------------
    BSWV[1].WVTP = 'DC'
    BSWV[2].WVTP = 'DC'
    for chan in [1,2]:
        print(f'C{chan}:BSWV:', BSWV[chan])
    print()
    print("C{}:WVTP:".format(1), BSWV[1].WVTP)
    print("C{}:WVTP:".format(2), BSWV[2].WVTP)
    time.sleep(2)

    # -------------------------------------------------------------------------------
    BSWV[1].WVTP = 'NOISE'
    BSWV[2].WVTP = 'NOISE'
    for chan in [1,2]:
        print(f'C{chan}:BSWV:', BSWV[chan])
    print()
    print("C{}:WVTP:".format(1), BSWV[1].WVTP)
    print("C{}:WVTP:".format(2), BSWV[2].WVTP)
    print()
    time.sleep(2)

    # -------------------------------------------------------------------
    # Restore inital parameters of the instrument that were saved earlier
    # -------------------------------------------------------------------
    for chan in [1,2]:
        BSWV[chan].restore(BSWV_saved_parameters[chan])
        print(f'C{chan}:BSWV:', BSWV[chan])

if __name__ == '__main__':
    main()
