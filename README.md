# iptables-myvpn
VPS上に建てたVPNサーバーでのiptables設定のメモです。

基本ポリシーの設定に始まり、VPSからVPNクライアントにパケットを転送する設定や、ポート別の通信許可設定などがあります。

将来的にこの設定の一部を他のデバイスで利用する可能性があるため、メモといった形で記録しています。

/etc/rc.localなどにこのスクリプトを読み込むように記述すると起動時に自動的に設定が適用されます。

> sudo sh /home/vps/ipt.sh
> 
> echo 1 > /proc/sys/net/ipv4/ip_forward
