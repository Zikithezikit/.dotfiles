#!/bin/bash
# fix-aic8800.sh - Repair AIC8800D80 (1111:1111 "88M80"/"AX900") driver install on kernel 7.0
#
# Fixes two problems in the original install.sh:
#   1. Kernel-compat patches (6.17/6.19) were being skipped -> build failed on kernel 7.0
#      because of in_irq() removal and get_tx_power signature change.
#   2. dkms.conf MAKE line never passed KBUILD_EXTRA_SYMBOLS, so aic8800_fdrv.ko
#      could not resolve symbols exported by aic_load_fw at modpost time.
#
# Run with:  sudo bash fix-aic8800.sh

set -e

KVER=$(uname -r)
KSRC="/lib/modules/$KVER/build"
DKMS_SRC="/usr/src/aic8800-radxa"
RADXA_DIR="/tmp/radxa-aic-fix"

echo "============================================"
echo " AIC8800D80 repair script"
echo " Kernel: $KVER"
echo "============================================"

if [ "$EUID" -ne 0 ]; then
    echo "ERROR: run with sudo."
    exit 1
fi

# ---- 1. Get fresh radxa source (sparse) ----
run_radxa_clone() {
    rm -rf "$RADXA_DIR"
    git clone --depth 1 --filter=blob:none --sparse \
        https://github.com/radxa-pkg/aic8800.git "$RADXA_DIR" 2>&1
    cd "$RADXA_DIR"
    git sparse-checkout set \
        src/USB/driver_fw/drivers/aic8800/aic_load_fw \
        src/USB/driver_fw/drivers/aic8800/aic8800_fdrv \
        src/USB/driver_fw/drivers/aic_btusb \
        src/USB/driver_fw/fw/aic8800D80 \
        debian/patches 2>&1
    cd - >/dev/null
}

if [ -d "$RADXA_DIR/src/USB/driver_fw/drivers/aic8800" ]; then
    echo "Using existing radxa clone at $RADXA_DIR"
else
    echo "Cloning radxa aic8800 source..."
    run_radxa_clone
fi

USB_BASE="$RADXA_DIR/src/USB/driver_fw/drivers/aic8800"
BTUSB_SRC="$RADXA_DIR/src/USB/driver_fw/drivers/aic_btusb"

# ---- 2. Rebuild the DKMS source cleanly ----
echo "  -> Cleaning old DKMS state..."
rm -rf "$DKMS_SRC"
dkms remove aic8800/radxa --all 2>/dev/null || true

echo "  -> Installing fresh source to $DKMS_SRC"
mkdir -p "$DKMS_SRC"
cp -r "$USB_BASE/aic_load_fw" "$DKMS_SRC/aic_load_fw"
cp -r "$USB_BASE/aic8800_fdrv" "$DKMS_SRC/aic8800_fdrv"

# ---- 3. dkms.conf with KBUILD_EXTRA_SYMBOLS fix ----
cat > "$DKMS_SRC/dkms.conf" << 'DKMS_EOF'
PACKAGE_NAME="aic8800"
PACKAGE_VERSION="radxa"

MAKE[0]="make -C ${kernel_source_dir} M=${dkms_tree}/aic8800/radxa/build/aic_load_fw modules && make -C ${kernel_source_dir} KBUILD_EXTRA_SYMBOLS=${dkms_tree}/aic8800/radxa/build/aic_load_fw/Module.symvers M=${dkms_tree}/aic8800/radxa/build/aic8800_fdrv modules"
CLEAN="make -C ${kernel_source_dir} M=${dkms_tree}/aic8800/radxa/build/aic_load_fw clean; make -C ${kernel_source_dir} M=${dkms_tree}/aic8800/radxa/build/aic8800_fdrv clean"

BUILT_MODULE_NAME[0]="aic_load_fw"
BUILT_MODULE_LOCATION[0]="aic_load_fw"
DEST_MODULE_LOCATION[0]="/updates/dkms"

BUILT_MODULE_NAME[1]="aic8800_fdrv"
BUILT_MODULE_LOCATION[1]="aic8800_fdrv"
DEST_MODULE_LOCATION[1]="/updates/dkms"

AUTOINSTALL="yes"
DKMS_EOF

# ---- 4. Apply kernel-7.0 fixes to the copied source ----
echo "  -> Applying kernel 7.0 compatibility fixes..."
cd "$DKMS_SRC"
python3 - << 'PYEOF'
p='aic8800_fdrv/rwnx_rx.c'
s=open(p).read()
old='''\t\tAICWFDBG(LOGINFO, "reord dinit in_irq():%d in_atomic:%d in_softirq:%d\\r\\n", (int)in_irq()
\t\t\t,(int)in_atomic(), (int)in_softirq());'''
new='''#if (LINUX_VERSION_CODE <= KERNEL_VERSION(6, 18, 0))
\t\tAICWFDBG(LOGINFO, "reord dinit in_irq():%d in_atomic:%d in_softirq:%d\\r\\n", (int)in_irq()
#else
\t\tAICWFDBG(LOGINFO, "reord dinit in_irq():%d in_atomic:%d in_softirq:%d\\r\\n", (int)in_hardirq()
#endif
\t\t\t,(int)in_atomic(), (int)in_softirq());'''
assert old in s, "in_irq pattern not found"
open(p,'w').write(s.replace(old,new))
print("  -> rwnx_rx.c: in_irq() -> in_hardirq() (kernel 6.19+)")

p='aic8800_fdrv/rwnx_main.c'
s=open(p).read()
old='''static int rwnx_cfg80211_get_tx_power(struct wiphy *wiphy,
#if LINUX_VERSION_CODE >= KERNEL_VERSION(3, 8, 0)
 struct wireless_dev *wdev,
#endif
\tint *mbm)'''
new='''static int rwnx_cfg80211_get_tx_power(struct wiphy *wiphy,
#if LINUX_VERSION_CODE >= KERNEL_VERSION(3, 8, 0)
 struct wireless_dev *wdev,
#if LINUX_VERSION_CODE >= KERNEL_VERSION (6, 14, 0)
#if LINUX_VERSION_CODE < KERNEL_VERSION (6, 17, 0)
 unsigned int link_id,
#else
 int radio_idx, unsigned int link_id,
#endif
#endif
#endif
\tint *mbm)'''
assert old in s, "get_tx_power pattern not found"
open(p,'w').write(s.replace(old,new))
print("  -> rwnx_main.c: get_tx_power gains radio_idx (kernel 6.17+)")
PYEOF
cd "$DKMS_SRC"

# Add a69c:8d83 to WiFi USB ID table if missing
WIFI_SRC="$DKMS_SRC/aic8800_fdrv/aicwf_usb.c"
if ! grep -q "0x8d83" "$WIFI_SRC"; then
    sed -i '/USB_DEVICE_ID_AIC_8800D80/a\\t{USB_DEVICE(0xa69c, 0x8d83)},   /* Pandora clone post-switch */' "$WIFI_SRC"
    echo "  -> Added a69c:8d83 to WiFi USB ID table."
fi

# ---- 5. Copy firmware ----
echo "  -> Copying firmware..."
FW_SRC="$RADXA_DIR/src/USB/driver_fw/fw/aic8800D80"
FW_DEST="/lib/firmware/aic8800D80"
if [ -d "$FW_SRC" ]; then
    mkdir -p "$FW_DEST"
    cp -v "$FW_SRC"/*.bin "$FW_DEST/" 2>/dev/null || true
else
    echo "  !! Firmware source missing; driver may not work."
fi

# ---- 6. Register + build + install DKMS ----
echo "  -> Registering DKMS..."
dkms add aic8800/radxa 2>&1 || true
echo "  -> Building DKMS (this takes a while)..."
dkms build aic8800/radxa -k "$KVER"
echo "  -> Installing DKMS..."
dkms install aic8800/radxa -k "$KVER" --force
echo "  -> DKMS build successful!"

# ---- 7. Build & install aic_btusb ----
echo "  -> Building aic_btusb (Bluetooth)..."
rmmod aic_btusb 2>/dev/null || true
BT_WORK="/tmp/aic_btusb_repair"
rm -rf "$BT_WORK"
mkdir -p "$BT_WORK"
cp -r "$BTUSB_SRC" "$BT_WORK/aic_btusb"
cd "$BT_WORK/aic_btusb"

# BlueZ mode (0) instead of Android BlueDroid (1)
sed -i 's/CONFIG_BLUEDROID        1/CONFIG_BLUEDROID        0/g' aic_btusb.h

# Add PID 0x8d83 if missing
if ! grep -q '0x8d83' aic_btusb.c; then
    sed -i '/USB_PRODUCT_ID_AIC8800D80/a\\t{USB_DEVICE_AND_INTERFACE_INFO(USB_VENDOR_ID_AIC, 0x8d83, 0xe0, 0x01, 0x01)},' aic_btusb.c
fi

make KDIR="$KSRC" CONFIG_PLATFORM_UBUNTU=y 2>&1 | tail -5
if [ ! -f aic_btusb.ko ]; then
    echo "  !! aic_btusb build failed"
else
    MODDIR="/lib/modules/$KVER/kernel/drivers/bluetooth"
    mkdir -p "$MODDIR"
    cp aic_btusb.ko "$MODDIR/"
    depmod -a "$KVER"
    echo "  -> aic_btusb.ko installed to $MODDIR/"
fi
cd /
rm -rf "$BT_WORK"

# ---- 8. usb_modeswitch config (auto switch on plug-in) ----
echo "  -> Installing usb_modeswitch config..."
mkdir -p /etc/usb_modeswitch.d
cat > /etc/usb_modeswitch.d/1111:1111 << 'EOF'
# AIC8800D80 "Pandora" clone (VID:PID 1111:1111)
# vendor-specific SCSI CDB to switch Mass Storage -> WiFi+BT
# F3 -> F2 sequence (works on AX900 / 88M80)
DefaultVendor=0x1111
DefaultProduct=0x1111
TargetVendor=0xa69c
TargetProduct=0x8d80
MessageContent="555342438765432100000000000010fd0000000000000000000000000000f3"
MessageContent2="555342438765432100000000000010fd0000000000000000000000000000f2"
EOF
echo "  -> /etc/usb_modeswitch.d/1111:1111"

# ---- 9. udev rules ----
echo "  -> Installing udev rules..."
cat > /etc/udev/rules.d/41-aic8800d80-modeswitch.rules << 'EOF'
ACTION=="add", ATTRS{idVendor}=="1111", ATTRS{idProduct}=="1111", RUN+="/usr/sbin/usb_modeswitch -c /etc/usb_modeswitch.d/1111:1111"
ACTION=="add", ATTRS{idVendor}=="a69c", ATTRS{idProduct}=="8d81", RUN+="/bin/sh -c 'echo a69c 8d81 > /sys/bus/usb/drivers/aic8800_fdrv/new_id 2>/dev/null || true'"
ACTION=="add", ATTRS{idVendor}=="a69c", ATTRS{idProduct}=="8d83", RUN+="/bin/sh -c 'echo a69c 8d83 > /sys/bus/usb/drivers/aic8800_fdrv/new_id 2>/dev/null || true'"
ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="a69c", ATTRS{idProduct}=="8d81", ATTR{bInterfaceClass}=="e0", ATTR{bInterfaceSubClass}=="01", ATTR{bInterfaceProtocol}=="01", RUN+="/bin/sh -c 'echo a69c 8d81 > /sys/bus/usb/drivers/aic_btusb/new_id 2>/dev/null || true'"
ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="a69c", ATTRS{idProduct}=="8d81", RUN+="/bin/sh -c 'rfkill unblock bluetooth 2>/dev/null || true'"
EOF
udevadm control --reload-rules
echo "  -> udev rules reloaded"

# ---- 10. modprobe config (prevent generic btusb) ----
echo "  -> Installing modprobe config..."
mkdir -p /etc/modprobe.d
cat > /etc/modprobe.d/aic8800-bt.conf << 'EOF'
softdep btusb pre: aic_btusb
alias usb:v0A69Cp8D83d*dc*dsc*dp*icE0isc01ip01in* aic_btusb
alias usb:v0A69Cp8D81d*dc*dsc*dp*icE0isc01ip01in* aic_btusb
EOF

# ---- 11. Module autoload ----
echo "  -> Configuring module autoload..."
mkdir -p /etc/modules-load.d
grep -qs '^aic_btusb' /etc/modules-load.d/aic8800.conf 2>/dev/null || echo "aic_btusb" >> /etc/modules-load.d/aic8800.conf

# ---- 12. Reload ----
echo "  -> Reloading modules..."
rmmod btusb 2>/dev/null || true
rmmod aic_btusb 2>/dev/null || true
rmmod aic8800_fdrv 2>/dev/null || true
rmmod aic_load_fw 2>/dev/null || true

modprobe aic_load_fw 2>&1 || echo "  !! modprobe aic_load_fw failed"
modprobe aic_btusb 2>&1 || echo "  !! modprobe aic_btusb failed"
sleep 1

# ---- 13. Verify ----
echo
echo "============================================"
echo " Installation / repair complete!"
echo "============================================"
echo
echo "Loaded modules:"
lsmod | grep -iE 'aic|btusb' || echo "  (none yet - replug the adapter to trigger)"
echo
echo "Current AIC device:"
lsusb | grep -iE 'a69c|aicsemi' || echo "  (not in network mode yet)"
echo
echo "Next steps:"
echo "  1. UNPLUG the adapter, then PLUG IT BACK IN"
echo "  2. Check WiFi:  ip link show"
echo "  3. Check BT:    bluetoothctl list"
echo
echo "If it still shows 1111:1111 after replug:"
echo "  sudo usb_modeswitch -v 1111 -p 1111 -c /etc/usb_modeswitch.d/1111:1111"
echo
echo "Manual driver bind if needed:"
echo "  sudo modprobe aic_load_fw aic8800_fdrv aic_btusb"
echo "  echo a69c 8d80 | sudo tee /sys/bus/usb/drivers/aic_load_fw/new_id"
echo "  echo a69c 8d81 | sudo tee /sys/bus/usb/drivers/aic8800_fdrv/new_id"