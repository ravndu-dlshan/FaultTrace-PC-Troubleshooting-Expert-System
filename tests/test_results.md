# Test results

| ID | Scenario | Expected | Backward result | Forward result | Rules checked | Result |
|---|---|---|---|---|---|---|
| TC01 | Dead PC, outlet does not work | faulty_outlet | faulty_outlet | faulty_outlet | r1, r2 | PASS |
| TC02 | Dead PC, outlet fine, PSU switch off | loose_power_connection | loose_power_connection | loose_power_connection | r1, r3 | PASS |
| TC03 | Dead PC, power reaching it, no smell | psu_failure | psu_failure | psu_failure | r1, r4, r6 | PASS |
| TC04 | Dead PC with burning smell (safety warning) | electrical_damage | electrical_damage | electrical_damage, psu_failure | r1, r4, r5 | PASS |
| TC05 | Black screen, monitor switched off | monitor_power_issue | monitor_power_issue | monitor_power_issue | r7, r8 | PASS |
| TC06 | Black screen, loose video cable | video_cable_issue | video_cable_issue | video_cable_issue | r7, r9 | PASS |
| TC07 | Beeps after adding RAM | ram_not_seated | ram_not_seated | ram_not_seated | r7, r10 | PASS |
| TC08 | Beeps, no RAM change | ram_failure | ram_failure | ram_failure | r7, r11 | PASS |
| TC09 | Black screen, everything else fine | gpu_failure | gpu_failure | gpu_failure | r7, r12 | PASS |
| TC10 | Hot shutdowns with dust | dust_blocked_cooling | dust_blocked_cooling | dust_blocked_cooling | r13, r15 | PASS |
| TC11 | Loud fans and heat, clean PC (alternative rule r14) | cooler_or_thermal_paste | cooler_or_thermal_paste | cooler_or_thermal_paste | r14, r16 | PASS |
| TC12 | Clicking hard drive | failing_hard_drive | failing_hard_drive | failing_hard_drive | r17, r19 | PASS |
| TC13 | No boot device, drive visible in BIOS | corrupted_bootloader | corrupted_bootloader | corrupted_bootloader | r21 | PASS |
| TC14 | Slow with pop-ups | malware_infection | malware_infection | malware_infection | r22, r24 | PASS |
| TC15 | Blue screens after driver update | faulty_driver_update | faulty_driver_update | faulty_driver_update | r27 | PASS |
| TC16 | Clock resets when unplugged | cmos_battery | cmos_battery | cmos_battery | r29 | PASS |
| TC17 | No internet anywhere on the network | router_or_isp | router_or_isp | router_or_isp | r30 | PASS |
| TC18 | Only this PC offline, adapter warning | network_driver | network_driver | network_driver | r31, r32 | PASS |
| TC19 | Only one symptom of a two-condition rule | none | - | none | - | PASS |
| TC20 | User unsure about a key symptom | none | - | none | - | PASS |

**20/20 passed**
