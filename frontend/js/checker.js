/* Symptom checker view (forward chaining) */
import { state, $, $$, esc, api, chip, ruleTag, traceHTML, diagnosisHTML, noticeHTML } from "./core.js";

function build() {
  const { categories, symptoms } = state.kb;
  $("#symptom-groups").innerHTML = categories.map((c) => {
    const items = symptoms.filter((s) => s.category === c.id);
    return `<section class="card group"><h3>${esc(c.label)} <span class="count">${items.length} symptoms</span></h3>
      ${items.map((s) => `
        <div class="sym-row">
          <span class="sym-label" title="${esc(s.question)}">${esc(s.label)}</span>
          <span class="seg" role="group" aria-label="${esc(s.label)}">
            <button data-id="${esc(s.id)}" data-v="yes">Yes</button>
            <button data-id="${esc(s.id)}" data-v="no">No</button>
            <button data-id="${esc(s.id)}" data-v="unknown">?</button>
          </span>
        </div>`).join("")}
    </section>`;
  }).join("");
  paint();
}

function paint() {
  $$(".seg button").forEach((b) => {
    const v = state.forward[b.dataset.id] || "unknown";
    b.setAttribute("aria-pressed", String(v === b.dataset.v));
  });
  const n = Object.values(state.forward).filter((v) => v !== "unknown").length;
  $("#forward-count").textContent = n ? `${n} symptom${n > 1 ? "s" : ""} marked` : "No symptoms marked yet";
}

function cyclesTable(cycles) {
  if (!cycles.length) return `<p class="muted">No rule could fire with these facts.</p>`;
  return `<div class="table-wrap"><table>
      <thead><tr><th>Cycle</th><th>Rules that matched</th><th>Rule fired</th><th>New fact added</th></tr></thead>
      <tbody>${cycles.map((c) => `<tr><td>${c.cycle}</td><td>${c.conflict_set.map(esc).join(", ")}</td>
        <td class="fired">${esc(c.fired)}</td><td>${esc(c.new_fact_label)}</td></tr>`).join("")}</tbody>
    </table></div>`;
}

async function run() {
  const r = await api("/api/forward", { known: state.forward });
  const out = $("#forward-result");
  if (!r.input.length) {
    out.innerHTML = noticeHTML("Nothing to analyse yet", "Mark at least one symptom as Yes or No, then run the diagnosis.");
    return;
  }
  const confirmed = r.input.filter((i) => i.answer === "yes").length;
  out.innerHTML = `<div class="result-grid">
    <div class="diag-list">
      ${r.faults.length ? r.faults.map(diagnosisHTML).join("") : noticeHTML("No diagnosis found",
        "These symptoms do not complete any rule. Mark more symptoms, or use guided diagnosis so the system can ask for what it is missing.")}
    </div>
    <div class="card">
      <div class="card-head"><h3>How this was concluded</h3></div>
      ${traceHTML([
        { name: "User input", body: `<ul>${r.input.map((i) => `<li>${esc(i.label)} ${chip(i.answer)}</li>`).join("")}</ul>` },
        { name: "Facts in working memory", body: `${confirmed} confirmed symptoms` +
            (r.derived.length ? `, plus derived: <ul>${r.derived.map((d) => `<li>${esc(d.label)}</li>`).join("")}</ul>` : "") },
        { name: "Rules applied (recognise-act cycles)", kind: "rule", body: cyclesTable(r.cycles) },
        { name: "Conclusion", kind: "end", body: r.faults.length ? r.faults.map((f) => esc(f.name)).join("<br>") : "No diagnosis" },
      ])}
    </div></div>`;
  out.scrollIntoView({ behavior: matchMedia("(prefers-reduced-motion: reduce)").matches ? "auto" : "smooth" });
}

export function initChecker() {
  build();
  $("#symptom-groups").addEventListener("click", (e) => {
    const b = e.target.closest("button[data-v]");
    if (!b) return;
    state.forward[b.dataset.id] = b.dataset.v;
    paint();
  });
  $("#run-forward").addEventListener("click", run);
  $("#clear-forward").addEventListener("click", () => {
    state.forward = {};
    paint();
    $("#forward-result").innerHTML = "";
  });
}
