# Read the manual for the instrument at:
# https://siglentna.com/wp-content/uploads/dlm_uploads/2017/10/ProgrammingGuide_forSDS-1-1.pdf
# https://pyvisa.readthedocs.io/en/latest/introduction/example.html
import matplotlib.pyplot as plt
import pyvisa
import sys
import time

def identify():
    rm = pyvisa.ResourceManager()
    print(rm.list_resources())
    # ('TCPIP0::192.168.0.21::inst0::INSTR',)
    
    #inst = rm.open_resource('TCPIP0::192.168.0.21::inst0::INSTR')
    inst = rm.open_resource('TCPIP0::192.168.0.21')
    print("session:", inst.session)

    print("default timeout [ms]:", inst.timeout)
    inst.timeout = 2 * inst.timeout

    # Normally you needn’t worry about it. However, some devices
    # don’t like to send data in chunks. So, we have to increase
    # this. See details at:
    # https://pyvisa.readthedocs.io/en/latest/introduction/resources.html#chunk-length

    print("default chunk_size [bytes]:", inst.chunk_size)
    inst.chunk_size = 100 * inst.chunk_size

    print(inst.query("*IDN?"))
    # *SIGLENT,SDS1102X,SDS1XDCC1L4001,1.1.2.15 R10

    # This reset the instrument to the initial state
    inst.write("*RST")
    inst.write("*CLS")
    inst.write("STATUS:PRESET")

    # This causes troubls with ACQUIRE_WAY
    # inst.write("AUTO_SETUP")
    print(inst.query("ACQUIRE_WAY?"))
    # SAMPLING

    print(inst.query("ALL_STATUS?"))
    # STB,96,ESR,160,INR,0,DDR,0,CMR,0,EXR,0,URR,0

    print(inst.query("C1:ATTN?"))
    # 1
    print(inst.query("C2:ATTN?"))
    # 1


    # That works - clears the grid, and then enables it back
    #time.sleep(2)
    #inst.write("GRID_DISPLAY OFF")
    #time.sleep(2)
    #inst.write("GRID_DISPLAY FULL")

    # That won't work as it requires some additional setting
    #print(inst.query("SCREEN_DUMP"))

    # That on eworks, but it's not clear where the file gest stored
    #inst.write("STore_PaNel DISK,UDSK,FILE,'SEAN.SET'")

    # These two enable channels
    inst.write("C1:ATTN 1")
    inst.write("C2:ATTN 1")
    # This one controls the time grid (20 microseconds per cell
    inst.write("TIME_DIV 50NS")

    # This controls vertical sensitivity of the channels
    inst.write("C1:VDIV 0.5V")
    inst.write("C2:VDIV 0.5V")

    # Stop measurements before capturing a waveform
    # Note the timeout. It's required for the device to finish the req
    inst.write("STOP")
    time.sleep(1)
    print(inst.query("ACQUIRE_WAY?"))

    # Query the waveform setup
    print(inst.query("WAVEFORM_SETUP?"))

    # SP,1,NP,0,FP,0,SN,0
    # Initially, that means:
    #   SU(sparsing) 1
    #   NP(number of points) 0 (to send all points)
    #   FP(first point) 0

    # Reading binary data is explained in:
    # https://pyvisa.readthedocs.io/en/latest/introduction/rvalues.html#reading-binary-values

    for chan in ["C1", "C2"]:
        # This returns an array
        data = inst.query_binary_values("{}:WF? DESC".format(chan), datatype='b')
        print(len(data))
        print(data)


        # Read bytes
        #data = inst.query_binary_values("C1:WF? DAT2", datatype='b')
        print(inst.write("{}:WF? DAT2".format(chan)))
        data = inst.read_raw()

        print("total wfLen, including hader [bytes]:", len(data))
        print("21 bytes header:", str(data[0:21]))
        wfLen = int(data[12:21])
        print("wfLen [bytes]:", wfLen)
        wfD = []
        wfV = []
        for i in range(0, wfLen):
            d = int(data[21 + i])
            if d > 127: d = d - 255
            v = d * (0.5/25)
            wfD.append(d)
            wfV.append(v)
 
        plt.plot(wfV)

    # Resume measurements 
    inst.write("RUN")

    plt.show()

def main():
    identify()
    sys.exit(0)

if __name__ == '__main__':
    main()
