#!/bin/sh
# Builds Heltec-Mac SE with arduino-cli and writes a ready-to-flash image (bootloader +
# partition table + app, for writing at 0x0):
#   firmware/Heltec-Mac-V4.bin   Heltec WiFi LoRa 32 V4 (Mac SE, uses the PSRAM)
# Usage: tools/build_firmware.sh
#   ARDUINO_CLI=/path/to/arduino-cli  ARDUINO_CONFIG=/path/to/arduino-cli.yaml  to override
set -e
here=$(cd "$(dirname "$0")/.." && pwd)
CLI=${ARDUINO_CLI:-arduino-cli}
CFG=${ARDUINO_CONFIG:+--config-file $ARDUINO_CONFIG}
EXTRA=${ARDUINO_EXTRA:-}
mkdir -p "$here/firmware"

image() {   # merged.bin -> image trimmed to the end of the app
  python3 - "$1" "$2" "$3" <<'PY'
import sys
merged, app, out = sys.argv[1:]
m = open(merged, 'rb').read(); a = open(app, 'rb').read()
n = (0x10000 + len(a) + 4095) & ~4095
assert m[0] == 0xE9 and m[0x8000:0x8002] == b'\xaa\x50' and m[0x10000:0x10000 + len(a)] == a
open(out, 'wb').write(m[:n]); print(out, n, 'bytes')
PY
}

build_v4() {
  out=$(mktemp -d)
  $CLI $CFG compile --fqbn "esp32:esp32:heltec_wifi_lora_32_V4:PSRAM=enabled,FlashSize=16M,CDCOnBoot=cdc,USBMode=hwcdc" $EXTRA \
      --build-property upload.maximum_size=2097152 \
      --output-dir "$out" "$here/Heltec-Mac"
  image "$out/Heltec-Mac.ino.merged.bin" "$out/Heltec-Mac.ino.bin" "$here/firmware/Heltec-Mac-V4.bin"
}

build_v4
