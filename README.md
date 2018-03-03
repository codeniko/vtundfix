# Vtundfix / Vtundctl
Vtundfix is a service written in bash to keep Vtund up and running. Occasionally, the tunnel between Rutgers LCSR and CBIM would go down for an unknown reason and would require a manual restart. Vtundfix is a general solution which detects if any component of the tunnel (bridge/vlan/tap interfaces, processes) is not working, and fixes the problem that is detected. 

Vtundctl is a control script that merges the commands and init commands of Vtund and Vtundfix. Usage of Vtundctl can be found in subsection **Using Vtundfix and Vtundctl**.


## Installation
Vtundfix needs to be installed on both the Vtund server and client machines. Download or pull a copy of this repo and just run make. `make install` will put all of the files in the correct locations.
> make install

## Configuration
Vtundfix configuration. Here are the contents of the template file:
> cat /etc/vtundfix.conf

<pre>
DIRECTORY /usr/local/vtundfix/
DELAY_BETWEENCHECK 300
DELAY_PARENTCHECK 300
SERVER 192.168.10.5
MACHINE client
EMAIL example@example.com

<tap> <tun name> <client ip> <bridge> <vlan for bridge>

tap0 lcsr 192.168.1.100 br0 eth0.763
tap1 lcsr2 192.168.1.101 br1 eth0.764
</pre>

### General Settings

Here is a description of all the settings:
<pre>
DIRECTORY - Directory containing the actual files for Vtundfix. Avoid changing the default value of 
this if possible.
</pre><pre>
DELAY_BETWEENCHECK - Delay between checks of whether or not Vtund and its components are working. 
The value is in seconds. The default is 300 seconds.
</pre><pre>
DELAY_PARENTCHECK - Delay between checks of whether or not children processes of Vtundfix are running. 
If not, that child is restarted to ensure that everything is working correctly. Each child of Vtundfix 
performs detection/correction checking for a unique TAP interface. The value is in seconds. The default
is 300 seconds.
</pre><pre>
SERVER - The IP address of the Vtund server machine. For consistancy, have this setting in the Server 
machine too.
</pre><pre>
MACHINE - Specify if the local machine is a Vtund "server" or "client". The valid values for this are 
"server" and "client".
</pre><pre>
EMAIL - The e-mail address to send a notification to when the TAP interface has been restarted. An 
e-mail is only sent if it is related to the TAP interface. This excludes bridge or process problems.
</pre>

### TAP Interface Configuration
The format for configuring the TAP interfaces at the bottom of the configuration file is as follows.
<pre>
&lt;tap&gt; &lt;tunnel/session name&gt; &lt;client ip&gt; &lt;bridge&gt; &lt;vlan for bridge&gt;
</pre>
The following are examples. Each new TAP configuration should be on a separate line.
<pre>
tap0 lcsr 192.168.1.100 br0 eth0.763
tap1 lcsr2 192.168.1.101 br1 eth0.764
</pre>

What I just configured was a TAP interface with *identifier 0*, with a tunnel name of *lcsr*. This TAP interface is bridged with *vlan 763* on eth0 through the *br0* br
idge. Finally, the IP address of the client that establishes this connection is 192.168.1.100.
Tap1 is similar but with just different values. Of course, replace these values with your existing Vtund values. When doing these configurations, each of these values should remain constant. For example, the client configured to connect as tap0 shouldn't be assigned tap1. In **/etc/vtund.conf** of **both** Vtund server and client, make sure that the lcsr session is to be assigned a specific tap interface and that the persist settings are set. The persist and multi settings are required to be on for Vtundfix to work properly. Apply these settings for **every** tunnel name in **/etc/vtund.conf**.
<pre>
Portion of /etc/vtund.conf to make sure it's set (add if it's not): 
</pre>
<pre>
lcsr {
    persist yes;
    device tap0;
    multi killold;
}
</pre>

### Setup SSH Authentication with Keys
In order for Vtundfix to work, create the *vtundfix* user on each machine and set it up to SSH into the *vtundfix* user on the other machine without the password prompt. Do the following commands on both machines

Create the *vtundfix* user and maybe send the password:
> useradd vtundfix <br>
> passwd vtundfix

Create a key for the **vtundfix** users (first switch user):
> su vtundfix
> ssh-keygen -t rsa


Once you have a key for both machines, copy the key from one into the authorized file of the other. Do so for both:
> cat ~/.ssh/id_rsa.pub | ssh vtundfix@IP_OF_OTHER_MACHINE "cat >> ~/.ssh/authorized_keys"

Next, change permissions of the following files/directories in each *vtundfix* user:
> chmod 700 ~/.ssh <br>
> chmod 600 ~/.ssh/id_rsa <br>
> chmod 600 ~/.ssh/authorized_keys

Test to see if you can SSH successfully without the password prompt from the *vtundfix* users.
> ssh vtundfix@IP_OF_OTHER_MACHINE

If it is still not working, edit **/etc/ssh/sshd_config** and make sure the following is uncommented. Add it if it's not there.
<pre>
RSAAuthentication yes
PubkeyAuthentication yes
</pre>
Finally, restart the SSH service:
> /etc/init.d/sshd restart

## Setup Cron
If a linux machine can't start any new processes because there are too many processes running, processes start to die randomly. If the parent process of Vtundfix is ever killed, the children die and there will be nothing to check and make sure that the Vtund tunnels are up and running. Vtundfix comes with a small script, **/usr/local/vtundfix/vtundfix_cron**, that restarts Vtundfix if it *should* be running. Although this step might seem optional, it is recommended for the longevity of the program.

The cron script is by default already set up when you untar *vtundfix.tgz* and the script is set to run every 5 minutes. When you untar, you should restart the cron daemon.
> /etc/init.d/crond stop<br>
> /etc/init.d/crond start

If you want to change how often the script runs or remove it, the crontab file is located in **/usr/local/vtundfix/vtundfix_crontab** and is linked from **/etc/cron.d/vtundfix**

## Using Vtundfix and Vtundctl
This section will show you the basic commands. To get more specific information on Vtundfix commands, take a look at `man vtundfix`

**Starting Vtundfix** <br>
Starting Vtundfix will start the tunnel checks for all TAP interfaces specified in */etc/vtundfix.conf*. You can start Vtundfix from one of the following methods (Vtundctl commands will be further explained in the next section): 
> vtundctl fix start

**Stopping Vtundfix** <br>
Stopping Vtundfix will stop the tunnel checks for *all* TAP interfaces. To stop Vtundfix, type:
> vtundctl fix stop

Ideally, starting and stopping is all you really need to manage Vtundfix. However, you might need more control sometimes. Suppose you have two TAP interfaces configured, tap0 and tap1, and you want to have Vtundfix only check tap0 temporarily. You can turn off Vtundfix for tap1 by doing this:
> vtundctl fix off tap1

This will turn off checking on **both** the Vtund server and client machines. To turn it back on, do this
> vtundctl fix on tap1


Vtundctl merges the commands for Vtund and Vtundfix, along with their init script commands.
Here is an example of calling a command for **Vtund** through Vtundctl and what it does:
> vtundctl vtund lcsr 192.168.1.100  # *start Vtund client process that will attempt to connect to Vtund server*

## Inside Vtundfix (How it works)
This section will cover how Vtundfix works on the inside incase changes need to be made or something weird is happening.

**NOTE** Vtundfix requires the ability to SSH to **server <---> client** as the *vtundfix* user in both directions and with an SSH authentication key (there should be no password prompt). The client and server require data from each other to function correctly.

Whenever Vtundfix is run, it first reads the configuration file. All of the settings in the example configuration file **MUST** be there. Do not omit any of the settings or else something unknown might happen. When Vtundfix is started, the main parent process spawns a child for every TAP interface configured in the configuraiton file. Each child is responsible for it's unique TAP interface. It does checks, and fixes any problems that might arise for that specific interface. Therefore, if something was to happen to one TAP interface, the other TAP interfaces are still being looked after. They are independent.

The parent process has one main responsibility. It is to make sure that its child processes are running. If a child randomly dies, it will be respawned with the correct TAP interface. If the parent ever dies when it is *SUPPOSED* to be running, the **vtundfix_cron** script is designed to bring it back up.

The child processes are what actually do all of the work for Vtundfix. The first thing that a child does is check if its parent is still alive. If the child is actually a zombie, it will terminate itself. If that's ok, the child follows a sequence of checks based on whether the local machine is a *server* or a *client*. This is looped with a delay specified in the configuration file.

1. If the machine is a client, check if the Vtund TAP connection process is running. <br>
2. On both server/client, check if VLAN exists locally.<br>
3. On both server/client, check if the Bridge exists locally.<br>
4. On client, check if the TAP interface exists.<br>
5. On both server/client, check if the TAP interface is working. If server and the TAP isn't working, do not continue (bridge will show up as not working). If client, restart the tap interface.<br>
6. On both server/client, check if the Bridge is working locally.<br>
7. If the machine is a server, check if the Vtund listener process is running<br><br>

If a problem is detected as Vtundfix does those checks in order, the problem is fixed and the check sequence restarts after another delay. It will not continue down the checks until that problem is resolved.

Checking if the VLAN exists is done as follows. First, check if the actual interface itself exists (eth0.763). Then check if this interface is up. Finally, check if this interface (eth0.763) is tied to the correct Device name (eth0) and correct VLAN ID (763)

Checking if the Bridge exists is done as follows. First, check if the actual interface itself exists (br0). Then check if this interface is up. Finally, check if this bridge (br0) is configured correctly and actually bridges the TAP interface (tap0) and the VLAN interface (eth0.763).

To determine if the TAP interfaces are working and data is actually flowing through the tunnel, Vtundfix checks the TX/RX packet counts that can be found when running *ifconfig*. Both the vtundfix client and server check these numbers both locally, and on the remote server. A copy of these numbers is then stored in the data files for each TAP interface to be used as the *previous* numbers to compare to. The idea behind Vtundfix is: if a packet was sent from one end and increased the TX count, then the RX count on the reciever should increase. It has been decided that the TAP interface is considered **NOT** working if data is not flowing through both directions of the tunnel. In other words, The tunnel is considered working if the TX/RX count increases on any side within *two* Vtundfix checks (delayed by the setting in the configuration file). There is a difference in how the client performs and how the server performs if there is an issue. When an issue rises, the client will restart the tunnel, but the server will simply ignore it and NOT check the bridge (the bridge will show up *broken* in this case, and this avoids an unnecessary restart).

## Files Associated With Vtundfix
/usr/local/vtundfix/vtundfix.conf
<pre>The  configuration  file  for  Vtundfix.  Should  be linked from /etc/vtundfix.conf.</pre>
/usr/local/vtundfix/vtundfix_init
<pre>The init script. Should be linked from /etc/init.d/vtundfix.</pre>
/usr/local/vtundfix/vtundfix
<pre>The  main  script  for   vtundfix.   Should   be   linked   from /usr/sbin/vtundfix.</pre>
/usr/local/vtundfix/vtundctl
<pre>The  control  script  which merges vtundfix and vtund. Should be linked from /usr/sbin/vtundctl</pre>
/var/vtundfix/vtundfix.log
<pre>The log file</pre>
/usr/local/vtundfix/vtundfix_cron
<pre>The cron file that makes sure the vtundfix daemon is running  as it’s supposed to. Should be linked from /etc/cron.d/vtundfix</pre>
/usr/local/vtundfix/vtundfix_logrotate
<pre>The logrotate file. Should be linked from /etc/logrotate.d/vtundfix</pre>
/var/vtundfix/data_tap#
<pre>The data files used by Vtundfix. If Vtundfix is configured with tap0 and tap1, there will be two data files. One data_tap0 and the other data_tap1</pre>
/var/run/vtundfix.pid
<pre>The PID file for vtundfix.</pre>

## Tunnel Notes
Vtund client triggers connection to server. When you start a client, a connector process is created that attempts to connect to the server every couple of seconds. When the server is started, a process is created that only listens for incoming client connections. Once a connection is triggered by the client and the connection becomes active, the TAP interface is created. The server will also spawn a new process that looks similar to the process in the client, which has a description of the connection. The only difference is if the connection ever goes goes down, the server's TAP process dies, but the client's process attempts to re-establish a connection again.

When a connection is established, there is about a 16-18 packet handshake that Vtund does before traffic can actually flow through the tunnel.

When a connection is broken, but the processes are still running, Vtund does nothing for a random amount of minutes and it appears as if the connection is still active. After the random timeout ends, Vtund client turns off the TAP interface and attempts to reconnect. When the Vtund server times out, the TAP process is just killed. Something to note is that the server and clients are independent and could timeout at random times. Prior to Vtundfix, the Vtund configuration could cause further delays when this happens, because you can't wait for one to timeout; they both have to timeout and they do this randomly. The Vtund configuration change that comes with Vtundfix utilizes the "killold" option which allows the server to terminate the old connection if a new client attempts to reconnect (Ex: if the client times out first).
The random timeout could range from 2 minutes to 15 minutes.

The killold option added by the addition of Vtundfix brings a new possible problem to be aware of: two client processes battling for the same connection. If by accident two client processes are created (even if they are created months apart), they will start to fight for the connection by killing each other's connection. It will be a never ending loop. This is something to be aware of, even though Vtundfix handles duplicate client processes.
