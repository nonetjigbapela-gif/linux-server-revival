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

I had to setup a DHCP reservation for the machine so that the IP adress of the machine doesnt change on the next boot.
I use my phone to provide my devices with internet connection so there was no way I could could do this as there was no router dashboard.
So the solution to this was using the hostname instead of an IP adress.
