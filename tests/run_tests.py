"""
Test cases for the PC Troubleshooting Expert System.

Each case gives the user's answers, the expected diagnosis and the rules
that must fire. The script runs every case through BOTH inference methods
(backward and forward chaining) and checks:
  * the expected diagnosis is produced          (correct conclusion)
  * the expected rules appear in the reasoning  (correct rules triggered)
  * the proof/explanation contains those rules  (explanation is correct)

Run from the project folder:   python tests/run_tests.py
Results are also written to tests/test_results.md for the report.
"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from backend.main import ask_prolog  # noqa: E402

CASES = [
    # id, description, answers, expected fault, rules that must fire
    ("TC01", "Dead PC, outlet does not work",
     {"no_power": "yes", "outlet_works": "no"}, "faulty_outlet", ["r1", "r2"]),
    ("TC02", "Dead PC, outlet fine, PSU switch off",
     {"no_power": "yes", "outlet_works": "yes", "psu_switch_on": "no"}, "loose_power_connection", ["r1", "r3"]),
    ("TC03", "Dead PC, power reaching it, no smell",
     {"no_power": "yes", "outlet_works": "yes", "psu_switch_on": "yes", "burning_smell": "no"},
     "psu_failure", ["r1", "r4", "r6"]),
    ("TC04", "Dead PC with burning smell (safety warning)",
     {"no_power": "yes", "outlet_works": "yes", "psu_switch_on": "yes", "burning_smell": "yes"},
     "electrical_damage", ["r1", "r4", "r5"]),
    ("TC05", "Black screen, monitor switched off",
     {"no_power": "no", "fans_spin": "yes", "no_display": "yes", "monitor_power_on": "no"},
     "monitor_power_issue", ["r7", "r8"]),
    ("TC06", "Black screen, loose video cable",
     {"no_power": "no", "fans_spin": "yes", "no_display": "yes", "monitor_power_on": "yes", "cable_loose": "yes"},
     "video_cable_issue", ["r7", "r9"]),
    ("TC07", "Beeps after adding RAM",
     {"no_power": "no", "fans_spin": "yes", "no_display": "yes", "monitor_power_on": "yes",
      "cable_loose": "no", "beep_codes": "yes", "recent_ram_change": "yes"},
     "ram_not_seated", ["r7", "r10"]),
    ("TC08", "Beeps, no RAM change",
     {"no_power": "no", "fans_spin": "yes", "no_display": "yes", "monitor_power_on": "yes",
      "cable_loose": "no", "beep_codes": "yes", "recent_ram_change": "no"},
     "ram_failure", ["r7", "r11"]),
    ("TC09", "Black screen, everything else fine",
     {"no_power": "no", "fans_spin": "yes", "no_display": "yes", "monitor_power_on": "yes",
      "cable_loose": "no", "beep_codes": "no"},
     "gpu_failure", ["r7", "r12"]),
    ("TC10", "Hot shutdowns with dust",
     {"no_power": "no", "fans_spin": "no", "shuts_down": "yes", "case_hot": "yes", "dust_buildup": "yes"},
     "dust_blocked_cooling", ["r13", "r15"]),
    ("TC11", "Loud fans and heat, clean PC (alternative rule r14)",
     {"no_power": "no", "fans_spin": "no", "shuts_down": "no", "loud_fans": "yes", "case_hot": "yes",
      "dust_buildup": "no"},
     "cooler_or_thermal_paste", ["r14", "r16"]),
    ("TC12", "Clicking hard drive",
     {"no_power": "no", "fans_spin": "no", "shuts_down": "no", "loud_fans": "no", "clicking_noise": "yes"},
     "failing_hard_drive", ["r17", "r19"]),
    ("TC13", "No boot device, drive visible in BIOS",
     {"no_power": "no", "fans_spin": "no", "shuts_down": "no", "loud_fans": "no", "clicking_noise": "no",
      "file_errors": "no", "boot_device_error": "yes", "drive_in_bios": "yes"},
     "corrupted_bootloader", ["r21"]),
    ("TC14", "Slow with pop-ups",
     {"no_power": "no", "fans_spin": "no", "shuts_down": "no", "loud_fans": "no", "clicking_noise": "no",
      "file_errors": "no", "boot_device_error": "no", "popups_ads": "yes", "slow_performance": "yes"},
     "malware_infection", ["r22", "r24"]),
    ("TC15", "Blue screens after driver update",
     {"blue_screen": "yes", "recent_driver_update": "yes"}, "faulty_driver_update", ["r27"]),
    ("TC16", "Clock resets when unplugged",
     {"time_resets": "yes"}, "cmos_battery", ["r29"]),
    ("TC17", "No internet anywhere on the network",
     {"no_internet": "yes", "other_devices_online": "no"}, "router_or_isp", ["r30"]),
    ("TC18", "Only this PC offline, adapter warning",
     {"no_internet": "yes", "other_devices_online": "yes", "adapter_warning": "yes"},
     "network_driver", ["r31", "r32"]),
]

# Cases where NO diagnosis should be reached (the system must not guess)
NEGATIVE = [
    ("TC19", "Only one symptom of a two-condition rule",
     {"slow_performance": "yes"}),
    ("TC20", "User unsure about a key symptom",
     {"no_power": "yes", "outlet_works": "unknown"}),
]


def run_backward(answers):
    """Simulate a user: answer each question from the table, 'unknown' if not listed."""
    known = {}
    for _ in range(60):
        r = ask_prolog({"action": "backward", "goal": "any", "known": known})
        if r["status"] != "ask":
            return r
        sid = r["symptom"]["id"]
        known[sid] = answers.get(sid, "unknown")
    raise RuntimeError("too many questions")


def proof_rules(p, out):
    if p["type"] == "rule":
        out.add(p["rule"])
        for c in p["children"]:
            proof_rules(c, out)
    return out


def main():
    rows, passed, total = [], 0, 0
    for tid, desc, answers, fault, rules in CASES:
        total += 1
        b = run_backward(answers)
        b_fault = b["fault"]["id"] if b["status"] == "found" else "none"
        b_rules = proof_rules(b["proof"], set()) if b["status"] == "found" else set()
        f = ask_prolog({"action": "forward", "known": answers})
        f_faults = [x["id"] for x in f["faults"]]
        f_rules = {c["fired"] for c in f["cycles"]}
        ok = (b_fault == fault and set(rules) <= b_rules
              and fault in f_faults and set(rules) <= f_rules)
        passed += ok
        rows.append((tid, desc, fault, b_fault, ", ".join(f_faults) or "none",
                     ", ".join(rules), "PASS" if ok else "FAIL"))

    for tid, desc, answers in NEGATIVE:
        total += 1
        f = ask_prolog({"action": "forward", "known": answers})
        ok = not f["faults"]
        passed += ok
        rows.append((tid, desc, "none", "-", ", ".join(x["id"] for x in f["faults"]) or "none",
                     "-", "PASS" if ok else "FAIL"))

    header = ("ID", "Scenario", "Expected", "Backward result", "Forward result", "Rules checked", "Result")
    md = ["| " + " | ".join(header) + " |", "|" + "---|" * len(header)]
    md += ["| " + " | ".join(r) + " |" for r in rows]
    Path(__file__).with_name("test_results.md").write_text(
        "# Test results\n\n" + "\n".join(md) + f"\n\n**{passed}/{total} passed**\n", encoding="utf-8")

    for r in rows:
        print(f"{r[0]}  {r[6]}  {r[1]}  -> backward: {r[3]} | forward: {r[4]}")
    print(f"\n{passed}/{total} test cases passed")


if __name__ == "__main__":
    main()
