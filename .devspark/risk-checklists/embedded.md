# Embedded / Firmware Risk Checklist

## Memory & Resources

- [ ] **Static memory budget per subsystem** (no surprise heap growth); stack high-water mark tracked
- [ ] **No dynamic allocation in hot/real-time paths** unless from a bounded pool
- [ ] **Buffer bounds checked at every external interface** (UART, BLE, network, USB)

## Safety & Recovery

- [ ] **Watchdog enabled and serviced** from a known-live task, not the main loop unconditionally
- [ ] **Power-loss recovery tested** for any persistent state (filesystem, EEPROM, flash)
- [ ] **Fail-safe defaults on sensor/comms loss** — actuator goes to known-safe position

## OTA & Update

- [ ] **OTA image signed and verified before flash**; rollback slot maintained
- [ ] **A/B partitioning or equivalent** so a failed boot reverts to last known good
- [ ] **Brick-resistance**: bootloader is never overwritten by application update path
- [ ] **Flash wear leveling considered** for write-heavy regions

## Real-Time & Determinism

- [ ] **Worst-case execution time bounded on real-time deadlines**
- [ ] **Interrupt priorities and shared-state locking reviewed** (no priority inversion)
- [ ] **No blocking calls inside ISRs**

## Build & Provenance

- [ ] **Reproducible firmware build** with toolchain version captured in artifact
- [ ] **Symbol files retained per release** for crash decoding
