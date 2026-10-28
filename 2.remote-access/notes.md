To create the SSH server I ran "sudo apt install openssh-server" to install the SSH server on the machine.
Then I ran "sudo systemctl enable --now ssh" so that the server starts on every boot from then on.
Then I ran "systemctl status ssh" so that i could see that the server is active

Then I ran "hostname -I" to get the IP address. I also ran "whoami" to confirm the username.
Both machines were on the same network so i opened my client machine and ran "ssh yourusername@IP"
I created a password then I was logged into the server from the client machine.

I then tried to create a Key based login so that i could log in without typing in the server password on every login attempt.
So I ran "ssh-keygen -t key" the it asked for a file path, i just pressed enter to set it to default for easier access later.
Then it asked me to create a paraphrase, i pressed enter for no paraphrase.
The private key stays on my client machine & isn't supposed to be shared
The public key is safe to share.

I was using a phone hotspot & it doesn't offer DHCP reservations because there's no router admin page to set one in.
So i used a hostname instead of an IP.
I ran "sudo apt install avahi-daemon" to install avahi.
Then I ran "sudo systemctl enable --now avahi-daemon" to enable avahi.
then I ran "hostnamectl" to see the hostname for the server machine.
So now if i want to log into the server I can run "ssh yourusername@lab-server.local" 
If the IP address changes i can still use the this command to login to the server.

