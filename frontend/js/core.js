/* Shared foundations: state, API access, DOM helpers and reusable HTML pieces.
   All reasoning happens in Prolog; the front end only sends answers to FastAPI
   and displays what the engine returns. */

export const state = {
  kb: null,                              // knowledge base loaded from Prolog
  guided: { goal: "any", answers: [] },  // answers: [{id, answer}]
  forward: {},                           // symptom id -> "yes" | "no" | "unknown"
};

export const $ = (sel, root = document) => root.querySelector(sel);
export const $$ = (sel, root = document) => [...root.querySelectorAll(sel)];

export const esc = (s) => String(s ?? "").replace(/[&<>"']/g, (c) =>
  ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));

export const answerWord = { yes: "Yes", no: "No", unknown: "Don't know" };

export async function api(path, body) {
  const res = await fetch(path, body === undefined ? {} : {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
  const data = await res.json();
  if (!res.ok) throw new Error(data.detail || "The server returned an error.");
  return data;
}

export const symptomById = (id) => state.kb.symptoms.find((s) => s.id === id);
export const categoryLabel = (id) => (state.kb.categories.find((c) => c.id === id) || {}).label || "";
export const ruleText = (id) => (state.kb.rules.find((r) => r.id === id) || {}).text || "";

export const chip = (answer) => `<span class="chip ${esc(answer)}">${answerWord[answer] ?? esc(answer)}</span>`;
export const ruleTag = (id) => `<span class="rule-id">${esc(id)}</span>`;

/* Reasoning trace, always: User input -> Facts -> Rules applied -> Reasoning -> Conclusion */
export function traceHTML(stages) {
  return `<ol class="trace">${stages.map((s) => `
    <li class="stage-${s.kind || "fact"}">
      <div class="stage-name">${esc(s.name)}</div>
      <div class="stage-body">${s.body}</div>
    </li>`).join("")}</ol>`;
}

export function diagnosisHTML(f) {
  return `<article class="diagnosis sev-${esc(f.severity)}">
      <span class="sev-pill">Severity: ${esc(f.severity)}</span>
      <h4>${esc(f.name)}</h4>
      <p>${esc(f.explanation)}</p>
      <span class="todo">What to do</span>
      <ol>${f.steps.map((s) => `<li>${esc(s)}</li>`).join("")}</ol>
    </article>`;
}

export const noticeHTML = (title, text, action = "") =>
  `<div class="notice"><h3>${esc(title)}</h3><p>${text}</p>${action}</div>`;
