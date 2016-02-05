import pyudev
context = pyudev.Context()
monitor = pyudev.Monitor.from_netlink(context)
monitor.filter_by('block')
dvItr = iter(monitor.poll, None)

def waitForUsb():
    for dev in dvItr:
        if dev.action == "add" and dev["DEVTYPE"] == "partition":
            yield dev.device_node
