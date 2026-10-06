/* Entry point: navigation and start-up */
import { state, $, $$, api } from "./core.js";
import { initGuided } from "./guided.js";
import { initChecker } from "./checker.js";
import { initKB } from "./kb.js";

function initNav() {
  const tabs = $$(".nav-item");
  tabs.forEach((tab) => tab.addEventListener("click", () => {
    tabs.forEach((t) => t.setAttribute("aria-selected", String(t === tab)));
    $$(".view").forEach((v) => v.classList.toggle("active", v.id === "view-" + tab.dataset.view));
    window.scrollTo({ top: 0 });
  }));
}

function setEngine(ok, text, detail) {
  $("#engine-dot").className = "dot " + (ok ? "ok" : "bad");
  $("#engine-status").textContent = text;
  if (detail) $("#engine-detail").textContent = detail;
}

(async function init() {
  initNav();
  try {
    state.kb = await api("/api/knowledge");
    setEngine(true, "Engine online",
      `${state.kb.rules.length} rules, ${state.kb.faults.length} faults loaded from SWI-Prolog`);
    initChecker();
    initKB();
    await initGuided();
  } catch (err) {
    setEngine(false, "Engine unreachable", "Check that SWI-Prolog is installed and the server is running.");
    $("#q-text").textContent = "Could not reach the reasoning engine. Check that SWI-Prolog is installed and the server is running.";
    console.error(err);
  }
})();
