/sbin/ifconfig | grep "inet .*10\." | head -n 1 | awk '{print $2}' > /home/shawnghu/.bean_inet_ip.txt
scp -i /home/shawnghu/.ssh/ender-auth /home/shawnghu/.bean_inet_ip.txt ender:~
