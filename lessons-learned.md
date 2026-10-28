LESSON 1

Before starting the project, I had a wifi driver issue. 
The machine would dissconnect for some odd reason & I couldn't narrow down what could be causing this issue.

Currently, I have Lubuntu running on the machine and I have updated its systems.
I haven's started with the SSH phase of the project.

I will start by identifying the chip & driver by running "Ispci -nnk | grep -iA3 network"
This command outputs the chip name, which is "Qualcomm Atheros QCA9565"
Kernal driver in use: ath9k
Outputs can be found on /lessons-learned/Chip name & Driver.png

The following command "sudo dmesg | grep -iE "wlp|wlan|firmware|rtl|brcm|ath" checks for errors from the last session.
Outputs can be found on /lessons-learned/Last Session Errors.png

LESSON 2 

No router available, so I used an Android hotspot. Constraints were a dynamic IP and possible client isolation. I solved it with mDNS (avahi) and set the hotspot to 2.4 GHz.

LESSON 3

the error message, the cause (entered a folder path instead of accepting the default file name), and the fix. It’s a small one, but it shows the kind of mistake that quietly breaks key authentication, and why checking each step’s output matters.
