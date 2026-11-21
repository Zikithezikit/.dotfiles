# Stream this machine's audio over the LAN. Bind to the IP this PC currently uses
# to reach the network, resolved at launch so a DHCP/VPN change can't leave us on a
# stale address. The hostname is no use here: /etc/hosts maps it to 127.0.1.1.
function audio_server --description "Start the PipeWire audio share server on this PC's LAN IP"
    # source address of the default route; falls back to the first address the host reports
    set -l bind_ip (ip -4 -o route get 1.1.1.1 2>/dev/null | string match -rg 'src (\S+)')
    test -z "$bind_ip"; and set bind_ip (hostname -I 2>/dev/null | string split -f1 ' ')
    if test -z "$bind_ip"
        echo "audio_server: no network address found" >&2
        return 1
    end
    as-cmd --bind=$bind_ip --encoding=f32 --channels=2 --sample-rate=48000 $argv
end
