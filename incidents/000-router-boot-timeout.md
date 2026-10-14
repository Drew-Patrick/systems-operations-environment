# 000: router did not respond to SSH after vagrant reload

Symptom: vagrant reload timed out waiting for router at 127.0.0.1:2222.
Checked: VirtualBox console showed "router login:" prompt (VM had booted).
Checked: vagrant ssh router succeeded on retry.
Cause: boot took longer than Vagrant's default 300 s boot_timeout.
Fix: none needed. Consider raising config.vm.boot_timeout if it recurs.