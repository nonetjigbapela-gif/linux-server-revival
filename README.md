# linux-server-revival
Reviving a 2014 Celeron laptop (2 GB RAM) into an automated Linux home server: installation, backups, monitoring, and Samba/nginx services, fully documented.

I started by taking screenshots of the machine's current condition. These can be found in \benchmarks.
I downloaded a 64-bit ISO of the latest LTS relese from the official Lubuntu website. I used LTS because it's support ends in 2029.
I used Rufus to flash the USB drive I will be using to install this ISO onto the machine.
I then booted the Lubuntu ISO onto the machine. An image on the Installation Summary can be fount in \1. Installation

After setup, I ran "sudo apt update && sudo apt upgrade". This command line performs a system update for the software packages on Lubuntu. This line contains 2 commands that are separated by the && sign. This tells the machine to run the first command and if it's successful it will also run the second command. The screenshot "Command Line 1", found in /1. Installation, shows evidence of this.

Next, I will be setting up SSH, letting me log into the machine and run it from another device over the network. This will make the machine headless, running it like a server from my main machine. It will also save RAM for Samba & nginx. This will also act as a foundation for later phases of this project, such as writing & testing backup.sh & monitor.sh or checking cron logs to see if automatons run. 

The machine will be running openssh-server, listening for connections. My main machine will be running an SSH client & will connect using the laptop's IP address & username. This makes the whole process encrypted.

After creating the SSH server, I created some test data to practice on so I ran "mkdir -p ~/test-data" to create a new directory folder, then i ran "echo "important notes" > ~/test-data/notes.txt" prints a string into a file, I then ran "echo "more data" > ~/test-data/report.txt" which works identically to the previous command. Finally, I ran "mkdir -p ~/scripts && nano ~/scripts/backup.sh" to create a directory in my home directory and opens the nano terminal-based text editor to load a file inside a folder, allowing me to write or edit a shell script interacively.
