import pyudev, glob
context = pyudev.Context()
monitor = pyudev.Monitor.from_netlink(context)
monitor.filter_by('block')
dvItr = iter(monitor.poll, None)

directory = "."

def waitForUsb():
    for dev in dvItr:
        if dev.action == "add" and dev["DEVTYPE"] == "partition":
            for i in dev.device_links:
                yield i

def CheckAccess(usb):
    for key in glob.glob(directory + "/*.key"):
        for maykey in glob.glob(usb + "/*.key"):
            print key,maykey

for i in waitForUsb():
    print i
    CheckAccess(i)
