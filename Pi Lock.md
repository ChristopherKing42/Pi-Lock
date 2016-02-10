This is a project to secure a lock using a raspberry pi. So we don’t break it, it will follow the KISS principle.

Usage

There will be a Raspberry Pi. It will have two users, masterHand and taboo. Mrs. Stetts will normally use masterHand account, and I will be responsible for taboo.

The Pi will be running an sFTP server. MasterHand will have a folder called “Keys”. In this will be files of the form “Chris.lock”, “Dan.lock”, “Jonah.Lock”, etc… There can also be a file called “#Admin.lock”, which will be explained later.

MasterHand can issue keys by creating files of the form, “@*.lock”. A program running on the server will detect this and populate it with random data and then remove the “@” symbol.

To allow a usb to have access to a key, simply put the file on the key at the top level.

To revoke access, simply place a hashtag in front of the file name. The software will automatically ignore files with hashtags in front. To permanently revoke access, delete the file.

For a worked example, masterHand could create a file called “@Admin.lock”. The software will populate this with random data and rename it “Admin.lock”. Now masterHand may rename this to “#Admin.lock”. The file “Admin.lock” may now be distributed to admins when they request access to the cabinet. They will not be able to access the cabinet. When the admin complains, a techie will notify masterHand or taboo. Once the techie is in the tech booth, the techie will give masterHand or taboo the signal, who will then rename the file “Admin.lock”. The techie will ask what is the problem, and when the admin attempts to open the door, it will work (this is safe, since the techie is present). The techie will then doubt the admin’s sanity. After the admin is gone, the file will be renamed “#Admin.lock”.

Someone with a valid usb key will be able to plug their usb into the door to unlock it. As soon as the usb is removed, the door will be relocked.

The door can also be unlocked by adding a file called “unlock.lock” to the Key folder, but this should only be used if an admin attacks and disables the USB ports on the PI.
Key Rerandomization Protocol
Before the locking mechanism is activated, the key on both the usb and the pi will be given a new file. This prevents two valid copies of a key being used in sequence.

Notification Protocol
The pi will send a text message to taboo and masterHand anytime a usb key is inserted into the pi, with information about the key used.

Physical Openness Protocol (Optional)
The pi will detect when the door is physically opened, and give a warning if it is open for too long without being closed (so that no one props the door open.) This will allow auditing how long a user has the door open, and when physical keys are used to open it.

Vengeance Protocol
If a usb is inserted that is not present on the pi, all files will be moved off of the usb on the pi, and a notice will be placed on the usb informing them that their malice has been thwarted, and that if they want their files back, they will need to contact us. This will not occur if the key is valid but disabled (since that will presumably happen frequently). The files will be put in a time stamped folder.

Creation
A raspberry pi will be connected to a locking mechanism. Two user accounts will be made: taboo and masterHand. masterHand’s access will be an unprivileged user. taboo will be a super user. An ssh and ftp server will be installed. The ftp server will share a folder called Keys in masterHand’s home folder. Software will be created will the following specification. It will constantly monitor for connected USB devices. If any valid key file on the top level of the usb matches a key file in the Key folder, the locking mechanism will unlock the door. As soon as the usb key is removed, the door will be locked. A valid key file is a file of the form “*.key” that does not begin with “#”. The software will also monitor the folder for a files of the form “@*.key”. It will file the file with N bytes of random data

Locking Mechanism
The locking mechanism will be a servo attached to a string, which will turn the door knob down for 5 seconds.

Materials
I have given links to element14. Adafruit is respected in this business. Also, getting all the parts from the same place may save on shipping. We could explore cheaper options though.
Raspberry Pi 1 model B+ https://www.raspberrypi.org/products/model-b-plus/
Model A+ will not suffice because it has only one usb port and no ethernet ports. We need either two usb ports or a usb port and ethernet port. B+ satisfies both requirements.
Wifi Dongle (https://www.raspberrypi.org/products/usb-wifi-dongle/) OR Ethernet Cable
Servo
String
Optional: USB Extender
This will protect the PI from unauthorized percussive maintenance. (Only taboo has authorization to administer percussive maintenance).
Optional: Breadboard
Miscellaneous Electronic Parts (wires, resistors, etc…)

Software
All software will be free.
Raspbian OS will probably be used for the operating system
An sFTP and ssh server
An FTP client (Here are some web based ones)
Software to Control Locking Mechanism
Software will be created to monitor the usb port for lock files
This will involve randomness. (See here.)
Creation, Renaming, and Deletion of Key Files will be logged.
Any unlock events will be logged (including failed ones (a.k.a. with invalid key files).
Language will most likely be Python or Bash.
Software will be released under an open source license and hosted on GitHub.
This GitHub repo will contain documentation for the project (which will presumably be based on this document).
The KEYS folder will be encrypted with something like this.

Ideas
Each USB could also contain a log file of that key’s activity for the last 7 days.

There could be LEDs that light up or flash depending on what status they are giving off. For example, if there is an error, it could flash. If the door is opening, it could blink twice. Then we could use the codes to diagnose errors. Another solution would be to get a simple display (like this one) and write the status to it.

Open Problems
Which humans will have access to the masterHand account? Should different humans use different accounts so we can audit them separately?

How to prevent admins from mistaking Raspberry Pi for food item?

Can the Raspberry Pi Zero be used instead? (https://www.adafruit.com/product/2817)

How will the USB port be accessible when the door is closed without making a hole in the door? If we use a USB extension cable, where would the cable be run? Where should the USB receptacle be?
