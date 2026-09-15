# step 1: Install OpenSSH server
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0

# step 2: Start service of sshd and set it start-up automatically
Start-Service sshd
Set-Service -Name sshd -StartupType Automatic

# step 3: Allow port 22 by firewall
New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH Server' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22

# step 4: Check the service status 
Get-Service sshd
