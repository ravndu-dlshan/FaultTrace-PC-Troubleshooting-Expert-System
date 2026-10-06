/* Knowledge base view: tabbed, searchable tables */
import { state, $, $$, esc, categoryLabel, ruleTag } from "./core.js";

const table = (head, rows) => `<div class="table-wrap"><table>
  <thead><tr>${head.map((h) => `<th>${h}</th>`).join("")}</tr></thead>
  <tbody>${rows.join("")}</tbody></table></div>`;

function sections() {
  const kb = state.kb;
  const cond = (c) => c.negated ? `<span class="cond-not">NOT</span> ${esc(c.label)}` : esc(c.label);
  return {
    rules: {
      label: `Rules (${kb.rules.length})`,
      html: table(["Rule", "IF", "THEN", "Source"], kb.rules.map((r) =>
        `<tr data-search="${esc([r.id, r.conclusion_label, r.reference, ...r.conditions.map((c) => c.label)].join(" ").toLowerCase())}">
          <td>${ruleTag(r.id)}</td><td>${r.conditions.map(cond).join("<br>AND ")}</td>
          <td>${esc(r.conclusion_label)}</td><td>${esc(r.reference)}</td></tr>`)),
    },
    symptoms: {
      label: `Symptoms (${kb.symptoms.length})`,
      html: table(["Fact", "Question asked", "Area"], kb.symptoms.map((s) =>
        `<tr data-search="${esc([s.id, s.question, categoryLabel(s.category)].join(" ").toLowerCase())}">
          <td class="mono">${esc(s.id)}</td><td>${esc(s.question)}</td><td>${esc(categoryLabel(s.category))}</td></tr>`)),
    },
    faults: {
      label: `Faults (${kb.faults.length})`,
      html: table(["Fault", "Explanation", "Severity"], kb.faults.map((f) =>
        `<tr data-search="${esc([f.name, f.explanation, f.severity].join(" ").toLowerCase())}">
          <td><strong>${esc(f.name)}</strong></td><td>${esc(f.explanation)}</td><td><span class="tag">${esc(f.severity)}</span></td></tr>`)),
    },
    sources: {
      label: `Sources (${kb.references.length})`,
      html: `<ul class="refs">${kb.references.map((r) =>
        `<li data-search="${esc((r.id + " " + r.text).toLowerCase())}"><strong>${esc(r.id)}</strong>: ${esc(r.text)}</li>`).join("")}</ul>`,
    },
  };
}

export function initKB() {
  const kb = state.kb;
  const tabs = sections();
  const keys = Object.keys(tabs);
  let current = keys[0];

  $("#kb-content").innerHTML = `
    <div class="stat-row">
      <div class="stat"><strong>${kb.symptoms.length}</strong><span>symptom facts</span></div>
      <div class="stat"><strong>${kb.faults.length}</strong><span>fault facts</span></div>
      <div class="stat"><strong>${kb.derived.length}</strong><span>intermediate facts</span></div>
      <div class="stat"><strong>${kb.rules.length}</strong><span>rules</span></div>
      <div class="stat"><strong>${kb.references.length}</strong><span>sources</span></div>
    </div>
    <div class="card">
      <div class="kb-tools">
        <div class="kb-tabs" role="tablist">${keys.map((k) =>
          `<button class="kb-tab" role="tab" data-kb="${k}" aria-selected="${k === current}">${tabs[k].label}</button>`).join("")}</div>
        <input class="search" id="kb-search" type="search" placeholder="Filter this list..." aria-label="Filter knowledge base">
      </div>
      <div id="kb-body"></div>
    </div>`;

  const show = () => {
    $("#kb-body").innerHTML = tabs[current].html;
    $$(".kb-tab").forEach((b) => b.setAttribute("aria-selected", String(b.dataset.kb === current)));
    filter();
  };
  const filter = () => {
    const q = $("#kb-search").value.trim().toLowerCase();
    $$("#kb-body [data-search]").forEach((el) => { el.hidden = q !== "" && !el.dataset.search.includes(q); });
  };

  $(".kb-tabs").addEventListener("click", (e) => {
    const b = e.target.closest("[data-kb]");
    if (b) { current = b.dataset.kb; show(); }
  });
  $("#kb-search").addEventListener("input", filter);
  show();
}
