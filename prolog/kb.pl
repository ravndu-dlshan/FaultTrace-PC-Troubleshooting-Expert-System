/*  =====================================================================
    PC TROUBLESHOOTING EXPERT SYSTEM  -  KNOWLEDGE BASE  (kb.pl)
    ---------------------------------------------------------------------
    The knowledge base holds only KNOWLEDGE (facts and rules).
    The reasoning procedures live separately in engine.pl.

    Contents
      1. reference/2    - sources the knowledge was taken from
      2. category/2     - problem areas used to group symptoms
      3. symptom/4      - observable facts the user can report
      4. derived/2      - intermediate conclusions (hypotheses)
      5. fault/5        - final diagnoses with explanation + repair steps
      6. rule/4         - IF-THEN production rules (with source)
    ===================================================================== */

:- discontiguous symptom/4, fault/5, rule/4.

/* ---------------------------------------------------------------------
   1. REFERENCES  reference(Id, Citation)
   --------------------------------------------------------------------- */
reference(mueller,   'Mueller, S. (2015). Upgrading and Repairing PCs (22nd ed.). Indianapolis: Que Publishing.').
reference(andrews,   'Andrews, J., Dark, J. & West, J. (2020). CompTIA A+ Guide to IT Technical Support (10th ed.). Boston: Cengage Learning.').
reference(meyers,    'Meyers, M. (2022). CompTIA A+ Certification All-in-One Exam Guide, Exams 220-1101 & 220-1102 (11th ed.). New York: McGraw Hill.').
reference(comptia,   'CompTIA (2022). CompTIA A+ Core 1 (220-1101) Exam Objectives, Domain 5.0: Hardware and Network Troubleshooting.').
reference(ms_bsod,   'Microsoft Support. Troubleshooting blue screen errors in Windows. support.microsoft.com').
reference(ms_wifi,   'Microsoft Support. Fix Wi-Fi connection issues in Windows. support.microsoft.com').
reference(ms_malware,'Microsoft Support. Remove malware from your Windows PC. support.microsoft.com').
reference(ms_perf,   'Microsoft Support. Tips to improve PC performance in Windows. support.microsoft.com').

/* ---------------------------------------------------------------------
   2. CATEGORIES  category(Id, Label)
   --------------------------------------------------------------------- */
category(power,       'Power').
category(display,     'Display and startup').
category(heat,        'Heat and shutdowns').
category(storage,     'Storage and booting').
category(performance, 'Speed and software').
category(stability,   'Crashes and settings').
category(network,     'Internet and network').

/* ---------------------------------------------------------------------
   3. SYMPTOMS (FACTS THE USER REPORTS)
      symptom(Id, ShortLabel, Question, Category)
   --------------------------------------------------------------------- */
% Power
symptom(no_power,        'PC is completely dead',
        'When you press the power button, is the PC completely dead (no lights, no fans, no sound)?', power).
symptom(outlet_works,    'Wall outlet works',
        'Does the wall outlet work when you test it with another device, such as a phone charger or lamp?', power).
symptom(psu_switch_on,   'PSU switch on and cable firm',
        'Is the switch on the back of the power supply set to ON, with the power cable pushed in firmly?', power).
symptom(burning_smell,   'Burning smell or popping sound',
        'Did you notice a burning smell or hear a pop from the PC?', power).

% Display and startup
symptom(fans_spin,       'Fans spin and lights come on',
        'When you switch on, do the fans spin and the lights on the PC come on?', display).
symptom(no_display,      'Monitor stays black',
        'Does the monitor stay black or show "No Signal"?', display).
symptom(monitor_power_on,'Monitor power light is on',
        'Is the power light on the monitor itself switched on?', display).
symptom(cable_loose,     'Video cable loose or in wrong port',
        'Is the video cable loose, damaged, or plugged into the motherboard instead of the graphics card?', display).
symptom(beep_codes,      'Repeated beeps at startup',
        'Does the PC give a pattern of repeated beeps when it starts?', display).
symptom(recent_ram_change,'RAM recently added or moved',
        'Was memory (RAM) recently added, removed or moved?', display).

% Heat and shutdowns
symptom(shuts_down,      'Sudden shutdowns under load',
        'Does the PC suddenly switch off or restart, especially during games or heavy work?', heat).
symptom(case_hot,        'Case or vent air very hot',
        'Does the case, or the air coming from the vents, feel very hot?', heat).
symptom(loud_fans,       'Fans very loud',
        'Are the fans unusually loud or running at full speed all the time?', heat).
symptom(dust_buildup,    'Dust in vents or fans',
        'Can you see dust built up in the vents, fans or heatsinks?', heat).

% Storage and booting
symptom(clicking_noise,  'Clicking or grinding drive',
        'Does the hard drive make clicking or grinding noises?', storage).
symptom(file_errors,     'Corrupted files or copy failures',
        'Do files become corrupted, or does copying files freeze or fail?', storage).
symptom(boot_device_error,'"No boot device" message',
        'Does the screen show "No boot device" or "Operating system not found"?', storage).
symptom(drive_in_bios,   'Drive listed in BIOS/UEFI',
        'Is the storage drive listed when you open the BIOS/UEFI setup screen?', storage).

% Speed and software
symptom(slow_performance,'PC much slower than usual',
        'Is the computer much slower than it used to be?', performance).
symptom(popups_ads,      'Pop-ups or browser redirects',
        'Do you see unexpected pop-ups, ads or browser redirects?', performance).
symptom(unknown_programs,'Unknown programs appeared',
        'Have programs or browser extensions appeared that you did not install?', performance).
symptom(high_memory_usage,'Memory use near 100%',
        'Does Task Manager show memory (RAM) usage near 90-100%?', performance).
symptom(low_disk_space,  'C: drive almost full',
        'Is the C: drive almost full (less than about 10% free)?', performance).

% Crashes and settings
symptom(blue_screen,     'Blue screen errors',
        'Does the PC crash with a blue screen (BSOD) error?', stability).
symptom(recent_driver_update,'Started after a driver/Windows update',
        'Did the problem start after installing or updating a driver or a Windows update?', stability).
symptom(time_resets,     'Clock and BIOS settings reset',
        'Do the date, time or BIOS settings reset whenever the PC is unplugged?', stability).

% Internet and network
symptom(no_internet,     'No internet on this PC',
        'Is this PC unable to connect to the internet?', network).
symptom(other_devices_online,'Other devices are online',
        'Can other devices on the same network (phone, laptop) use the internet?', network).
symptom(adapter_warning, 'Network adapter missing or warning',
        'In Device Manager, is the Wi-Fi/Ethernet adapter missing or shown with a yellow warning sign?', network).

/* ---------------------------------------------------------------------
   4. INTERMEDIATE CONCLUSIONS  derived(Id, Label)
   --------------------------------------------------------------------- */
derived(power_problem,        'The PC is not receiving power').
derived(suspect_psu,          'The power supply unit is suspected').
derived(display_problem,      'The PC runs but produces no picture').
derived(overheating,          'The PC is overheating').
derived(storage_hw_problem,   'The storage drive is physically failing').
derived(malware_signs,        'There are signs of malicious software').
derived(network_local_problem,'The fault is inside this PC, not the network').

/* ---------------------------------------------------------------------
   5. FAULTS (FINAL DIAGNOSES)
      fault(Id, Name, Explanation, RepairSteps, Severity)
   --------------------------------------------------------------------- */
fault(faulty_outlet, 'Faulty wall outlet or power strip',
      'The PC gets no power because the outlet or power strip itself is dead.',
      ['Plug the PC into a known-working outlet.', 'Bypass the power strip or UPS to test it.', 'Have an electrician check the outlet.'],
      low).
fault(loose_power_connection, 'Loose power cable or PSU switch off',
      'Power is available at the outlet but is not reaching the power supply.',
      ['Turn the PSU switch at the back to ON (I).', 'Reseat the power cable at both ends.', 'Try a different power cable.'],
      low).
fault(electrical_damage, 'Electrical damage - stop using the PC',
      'A burning smell or pop means a component has failed electrically and may be a fire risk.',
      ['Unplug the PC immediately and do not power it on again.', 'Have a technician inspect the PSU and motherboard.'],
      critical).
fault(psu_failure, 'Failed power supply unit (PSU)',
      'Power reaches the PC but the power supply does not deliver it to the components.',
      ['Test the PSU with a PSU tester or multimeter.', 'Replace the PSU with one of equal or higher wattage.'],
      high).
fault(monitor_power_issue, 'Monitor has no power',
      'The PC is running but the monitor itself is switched off or not powered.',
      ['Press the monitor power button.', 'Check the monitor power cable and outlet.', 'Test with another monitor.'],
      low).
fault(video_cable_issue, 'Video cable or wrong video port',
      'The monitor is on but no video signal arrives because of the cable or port.',
      ['Reseat both ends of the video cable.', 'Plug into the graphics card port, not the motherboard port.', 'Try another cable.'],
      low).
fault(ram_not_seated, 'RAM not seated correctly',
      'Beeps after a RAM change mean the memory module is not making proper contact.',
      ['Power off and unplug the PC.', 'Remove and firmly reinsert each RAM stick until the clips lock.', 'Check that RAM is in the slots the manual recommends.'],
      medium).
fault(ram_failure, 'Failed memory (RAM)',
      'The POST beep pattern shows the firmware cannot initialise memory.',
      ['Look up the beep code in the motherboard manual.', 'Test with one RAM stick at a time.', 'Replace the faulty module.'],
      medium).
fault(gpu_failure, 'Graphics card (GPU) failure',
      'The PC and monitor both work and the connection is fine, so the video output device is suspect.',
      ['Reseat the graphics card and its power connectors.', 'Test using onboard video if available.', 'Replace the graphics card.'],
      high).
fault(dust_blocked_cooling, 'Dust blocking the cooling system',
      'Dust clogs vents and heatsinks so heat cannot escape, causing thermal shutdowns.',
      ['Power off and clean fans, vents and heatsinks with compressed air.', 'Keep the PC off carpets and away from walls.'],
      medium).
fault(cooler_or_thermal_paste, 'CPU cooler fault or dried thermal paste',
      'The PC overheats although it is clean, so heat is not moving from the CPU to the cooler.',
      ['Check that the CPU fan spins.', 'Reseat the CPU cooler.', 'Replace old thermal paste.'],
      medium).
fault(failing_hard_drive, 'Failing hard drive',
      'Noises or data corruption show the drive is physically failing.',
      ['Back up your data immediately.', 'Check drive health (SMART) with a diagnostic tool.', 'Replace the drive.'],
      high).
fault(drive_not_detected, 'Boot drive not detected',
      'The firmware cannot see the drive, so it is disconnected or dead.',
      ['Reseat the SATA/NVMe drive and its cables.', 'Try another SATA port and cable.', 'Replace the drive if still not detected.'],
      high).
fault(corrupted_bootloader, 'Corrupted boot files or wrong boot order',
      'The drive is detected but Windows cannot start from it.',
      ['Check the boot order in BIOS/UEFI.', 'Run Startup Repair from Windows recovery media.', 'Rebuild the boot files (bootrec).'],
      medium).
fault(malware_infection, 'Malware infection',
      'Unwanted programs and pop-ups, together with slowness, point to malicious software.',
      ['Disconnect from the internet.', 'Run a full scan with Microsoft Defender (offline scan).', 'Remove unknown programs and browser extensions.'],
      high).
fault(insufficient_ram, 'Not enough memory (RAM)',
      'Memory is full, so Windows swaps data to disk and slows down.',
      ['Close unused programs and browser tabs.', 'Disable unneeded startup programs.', 'Add more RAM.'],
      low).
fault(storage_full, 'System drive almost full',
      'Windows lacks free space for updates, temporary files and virtual memory.',
      ['Run Disk Cleanup / Storage Sense.', 'Uninstall unused programs.', 'Move files to another drive.'],
      low).
fault(faulty_driver_update, 'Faulty driver or update',
      'Crashes started after a driver or update was installed.',
      ['Roll back the driver in Device Manager.', 'Uninstall the recent update.', 'Use System Restore.'],
      medium).
fault(hardware_stop_error, 'Hardware-related stop errors',
      'Blue screens with no recent software change usually point to memory or other hardware.',
      ['Run Windows Memory Diagnostic.', 'Note the stop code shown on the blue screen.', 'Check drive health.'],
      medium).
fault(cmos_battery, 'Dead CMOS battery',
      'The small motherboard battery can no longer keep the clock and BIOS settings.',
      ['Replace the CR2032 coin battery on the motherboard.', 'Re-enter the date, time and BIOS settings.'],
      low).
fault(router_or_isp, 'Router or internet provider problem',
      'No device can go online, so the problem is outside this PC.',
      ['Restart the modem/router.', 'Check the router lights and cables.', 'Contact your internet provider.'],
      low).
fault(network_driver, 'Network adapter driver problem',
      'Only this PC is offline and its network adapter is missing or faulty.',
      ['Update or reinstall the network adapter driver.', 'Run the Windows Network troubleshooter.'],
      medium).
fault(network_settings, 'PC network settings problem',
      'Only this PC is offline although its adapter works, so its settings are wrong.',
      ['Forget and reconnect to the Wi-Fi network.', 'Run: ipconfig /release, ipconfig /renew, ipconfig /flushdns.', 'Use Network reset in Settings.'],
      low).

/* ---------------------------------------------------------------------
   6. PRODUCTION RULES
      rule(Id, Conditions, Conclusion, ReferenceId)
      Conditions are ANDed.  not(S) means the user answered "no" to S.
      Several rules with the same conclusion act as OR (e.g. r13 / r14).
   --------------------------------------------------------------------- */
% --- Power ---------------------------------------------------------------
rule(r1,  [no_power],                                   power_problem,                 mueller).
rule(r2,  [power_problem, not(outlet_works)],           fault(faulty_outlet),          andrews).
rule(r3,  [power_problem, outlet_works, not(psu_switch_on)],
                                                        fault(loose_power_connection), andrews).
rule(r4,  [power_problem, outlet_works, psu_switch_on], suspect_psu,                   mueller).
rule(r5,  [suspect_psu, burning_smell],                 fault(electrical_damage),      meyers).
rule(r6,  [suspect_psu],                                fault(psu_failure),            mueller).

% --- Display and startup -------------------------------------------------
rule(r7,  [fans_spin, no_display],                      display_problem,               comptia).
rule(r8,  [display_problem, not(monitor_power_on)],     fault(monitor_power_issue),    andrews).
rule(r9,  [display_problem, monitor_power_on, cable_loose],
                                                        fault(video_cable_issue),      andrews).
rule(r10, [display_problem, beep_codes, recent_ram_change],
                                                        fault(ram_not_seated),         meyers).
rule(r11, [display_problem, beep_codes, not(recent_ram_change)],
                                                        fault(ram_failure),            mueller).
rule(r12, [display_problem, monitor_power_on, not(cable_loose), not(beep_codes)],
                                                        fault(gpu_failure),            comptia).

% --- Heat and shutdowns --------------------------------------------------
rule(r13, [shuts_down, case_hot],                       overheating,                   mueller).
rule(r14, [loud_fans, case_hot],                        overheating,                   andrews).
rule(r15, [overheating, dust_buildup],                  fault(dust_blocked_cooling),   mueller).
rule(r16, [overheating, not(dust_buildup)],             fault(cooler_or_thermal_paste), meyers).

% --- Storage and booting -------------------------------------------------
rule(r17, [clicking_noise],                             storage_hw_problem,            mueller).
rule(r18, [file_errors],                                storage_hw_problem,            comptia).
rule(r19, [storage_hw_problem],                         fault(failing_hard_drive),     andrews).
rule(r20, [boot_device_error, not(drive_in_bios)],      fault(drive_not_detected),     andrews).
rule(r21, [boot_device_error, drive_in_bios],           fault(corrupted_bootloader),   meyers).

% --- Speed and software --------------------------------------------------
rule(r22, [popups_ads],                                 malware_signs,                 ms_malware).
rule(r23, [unknown_programs],                           malware_signs,                 ms_malware).
rule(r24, [malware_signs, slow_performance],            fault(malware_infection),      ms_malware).
rule(r25, [slow_performance, high_memory_usage],        fault(insufficient_ram),       ms_perf).
rule(r26, [slow_performance, low_disk_space],           fault(storage_full),           ms_perf).

% --- Crashes and settings ------------------------------------------------
rule(r27, [blue_screen, recent_driver_update],          fault(faulty_driver_update),   ms_bsod).
rule(r28, [blue_screen, not(recent_driver_update)],     fault(hardware_stop_error),    ms_bsod).
rule(r29, [time_resets],                                fault(cmos_battery),           mueller).

% --- Internet and network ------------------------------------------------
rule(r30, [no_internet, not(other_devices_online)],     fault(router_or_isp),          ms_wifi).
rule(r31, [no_internet, other_devices_online],          network_local_problem,         comptia).
rule(r32, [network_local_problem, adapter_warning],     fault(network_driver),         ms_wifi).
rule(r33, [network_local_problem, not(adapter_warning)],fault(network_settings),       ms_wifi).
