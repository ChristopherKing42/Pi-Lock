import pyudev, glob
context = pyudev.Context()
monitor = pyudev.Monitor.from_netlink(context)
monitor.filter_by('block')
dvItr = iter(monitor.poll, None)

directory = "."

def waitForUsb():
    for dev in dvItr:
        if dev.action == "add" and dev["DEVTYPE"] == "partition":
            yield dev.device_node

def CheckAccess(usb):
    for key in glob.glob(directory + "/*.key"):
        for maykey in glob.glob(usb + "/*.key"):
            print key,maykey
