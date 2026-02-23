
from devices.SDG1032X import SDG1032X, BasicWaveParams

import sys
import time

def print_BSWV(bswv, parameters):
    print(f"C{bswv.chan} BSWV {bswv}")
    for key, value in parameters.items():
        print(f"        {key}\t{value}\t{BasicWaveParams.unit(key)}")


def main():
    device = SDG1032X('10.0.0.229')
    print("instance:", device.instance())
    print("     IDN:", device.IDN())
    print()

    # Reset to the initial state
    device.RST()
    device.CLS()
    device.STATUS_PRESET()

    time.sleep(1)

    # API objects for the Basic Wave operations
    bswvs = [device.BSWV(chan) for chan in [1,2]]

    # Save a complete state of the channel's parameters into a dictionary. The states
    # the channel's state coulf be easily restored from those.
    bswv_params = {}
    for bswv in bswvs:
        chan = bswv.chan
        bswv_params[chan] = bswv.save()
        print_BSWV(bswv, bswv_params[chan])
        bswv.restore(bswv_params[chan])
    print()

    # --- SINE ---

    kHz = 1000
    for bswv in bswvs:
        bswv.WVTP    = 'SINE'
        bswv.FRQ     = 1 * kHz
        bswv.PERI    = 0.002
        bswv.AMP     = 3.0
        bswv.AMPVRMS = 0.5
        bswv.OFST    = 0.0
        bswv.HLEV    = 1.0
        bswv.LLEV    = -1.0
        bswv.PHSE    = -361.0
        print(f"C{bswv.chan} BSWV {bswv}")
        print(f"        WVTP    {bswv.WVTP}\t{BasicWaveParams.unit('WVTP')}")
        print(f"        FRQ     {bswv.FRQ}\t{BasicWaveParams.unit('FRQ')}")
        print(f"        PERI    {bswv.PERI}\t{BasicWaveParams.unit('PERI')}")
        print(f"        AMP     {bswv.AMP}\t{BasicWaveParams.unit('AMP')}")
        print(f"        AMPVRMS {bswv.AMPVRMS}\t{BasicWaveParams.unit('AMPVRMS')}")
        print(f"        OFST    {bswv.OFST}\t{BasicWaveParams.unit('OFST')}")
        print(f"        HLEV    {bswv.HLEV}\t{BasicWaveParams.unit('HLEV')}")
        print(f"        LLEV    {bswv.LLEV}\t{BasicWaveParams.unit('LLEV')}")
        print(f"        PHSE    {bswv.PHSE}\t{BasicWaveParams.unit('PHSE')}")
    print()

    time.sleep(2)

    for bswv in bswvs:
        parameters = bswv.set_SINE(FRQ=2*kHz, AMP=2.5)
        print_BSWV(bswv, parameters)
    print()

    time.sleep(2)

    # --- SQUARE ---

    for bswv in bswvs:
        bswv.WVTP = 'SQUARE'
        bswv.DUTY = 25
        print(f'C{bswv.chan}:BSWV:', bswv)
        print(f"        WVTP    {bswv.WVTP}\t{BasicWaveParams.unit('WVTP')}")
        print(f"        DUTY    {bswv.DUTY}\t{BasicWaveParams.unit('DUTY')}")
    print()

    time.sleep(2)

    for bswv in bswvs:
        params = bswv.set_SQUARE(DUTY=75)
        print_BSWV(bswv, params)
    print()

    time.sleep(2)

    # --- RAMP ---

    for bswv in bswvs:
        bswv.WVTP = 'RAMP'
        bswv.SYM = 0
        print(f'C{bswv.chan}:BSWV:', bswv)
        print(f"        WVTP    {bswv.WVTP}\t{BasicWaveParams.unit('WVTP')}")
        print(f"        SYM     {bswv.SYM}\t{BasicWaveParams.unit('SYM')}")
    print()

    time.sleep(2)

    for chan in [1,2]:
        params = bswv.set_RAMP(SYM=25)
        print_BSWV(bswv, params)
    print()

    time.sleep(2)

    # --- PULSE ---

    for bswv in bswvs:
        bswv.WVTP = 'PULSE'
        bswv.DUTY = 25
        bswv.RISE = 15    # [%]
        bswv.FALL = 16    # [%]
        print(f'C{bswv.chan}:BSWV:', bswv)
        print(f"        WVTP    {bswv.WVTP}\t{BasicWaveParams.unit('WVTP')}")
        print(f"        DUTY    {bswv.DUTY}\t{BasicWaveParams.unit('DUTY')}")
        print(f"        RISE    {bswv.RISE}\t{BasicWaveParams.unit('RISE')}")
        print(f"        FALL    {bswv.FALL}\t{BasicWaveParams.unit('FALL')}")
    print()

    time.sleep(2)

    for chan in [1,2]:
        params = bswv.set_PULSE(RISE=25, FALL=90, DLY=1.5)
        print_BSWV(bswv, params)
    print()

    time.sleep(2)

    # --- ARB ---

    for bswv in bswvs:
        bswv.WVTP = 'ARB'
        print(f'C{chan}:BSWV:', bswv)
        print(f'C{bswv.chan}:BSWV:', bswv)
        print(f"        WVTP    {bswv.WVTP}\t{BasicWaveParams.unit('WVTP')}")
    print()

    time.sleep(2)

    # --- DC ---

    for bswv in bswvs:
        bswv.WVTP = 'DC'
        print(f'C{chan}:BSWV:', bswv)
        print(f'C{bswv.chan}:BSWV:', bswv)
        print(f"        WVTP    {bswv.WVTP}\t{BasicWaveParams.unit('WVTP')}")
    print()

    time.sleep(2)

    # --- NOISE ---

    for bswv in bswvs:
        bswv.WVTP  = 'NOISE'
        bswv.MEAN  = 1.0
        bswv.STDEV = 0.5
        print(f'C{chan}:BSWV:', bswv)
        print(f'C{bswv.chan}:BSWV:', bswv)
        print(f"        WVTP    {bswv.WVTP}\t{BasicWaveParams.unit('WVTP')}")
        print(f"        MEAN    {bswv.MEAN}\t{BasicWaveParams.unit('MEAN')}")
        print(f"        STDEV   {bswv.STDEV}\t{BasicWaveParams.unit('STDEV')}")
    print()

    time.sleep(2)

    # Restore inital parameters of the instrument that were saved earlier
    for bswv in bswvs:
        bswv.restore(bswv_params[bswv.chan])
        print(f'C{bswv.chan}:BSWV:', bswv)

if __name__ == '__main__':
    main()
