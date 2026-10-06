/* Guided diagnosis view (backward chaining) */
import {
  state, $, $$, esc, api, answerWord, symptomById, categoryLabel, ruleText,
  chip, ruleTag, traceHTML, diagnosisHTML, noticeHTML,
} from "./core.js";

const knownObject = (list) => Object.fromEntries(list.map((a) => [a.id, a.answer]));

async function step() {
  const r = await api("/api/backward", {
    goal: state.guided.goal,
    known: knownObject(state.guided.answers),
  });
  renderHistory();
  $("#why-box").hidden = true;
  $("#why-toggle").setAttribute("aria-expanded", "false");

  const n = state.guided.answers.length;
  $("#step-count").textContent = r.status === "ask" ? `Question ${n + 1}` : `${n} answered`;
  $("#step-bar").style.width = r.status === "ask" ? `${Math.min(90, 8 + n * 9)}%` : "100%";

  if (r.status === "ask") {
    $("#question-card").hidden = false;
    $("#result-box").hidden = true;
    $("#q-category").textContent = categoryLabel(r.symptom.category);
    $("#q-text").textContent = r.symptom.question;
    $("#q-text").dataset.id = r.symptom.id;
    $("#why-box").innerHTML = `
      <p>To prove the goal, I am testing this rule:</p>
      <p>${ruleTag(r.why.rule)}${esc(r.why.text)}</p>
      ${r.why.chain.length > 1 ? `<p>which is needed for:</p><ol>${
        r.why.chain.slice(1).map((c) => `<li>${ruleTag(c.rule)}${esc(c.text)}</li>`).join("")}</ol>` : ""}`;
    const card = $("#question-card");
    card.classList.remove("flash"); void card.offsetWidth; card.classList.add("flash");
  } else {
    $("#question-card").hidden = true;
    $("#result-box").hidden = false;
    $("#result-box").innerHTML = r.status === "found" ? resultHTML(r) : noneHTML();
  }
}

const restartButton = (label) => `<button class="btn primary" data-action="restart">${label}</button>`;

const noneHTML = () => noticeHTML(
  "No diagnosis found",
  "None of the faults in the knowledge base matches your answers. Try the symptom checker, choose a different fault to look for, or ask a qualified technician.",
  restartButton("Start over"));

function proofLeaves(p, out = []) {
  if (p.type === "fact") out.push(p);
  else p.children.forEach((c) => proofLeaves(c, out));
  return out;
}

function proofTreeHTML(p) {
  if (p.type === "fact") return `<li>You answered ${chip(p.answer)} to "${esc(p.label)}"</li>`;
  return `<li>${ruleTag(p.rule)}<strong>${esc(p.label)}</strong>
      <span class="src">${esc(p.text)}<br>Source: ${esc(p.reference)}</span>
      <ul class="proof">${p.children.map(proofTreeHTML).join("")}</ul></li>`;
}

function resultHTML(r) {
  const leaves = proofLeaves(r.proof);
  return diagnosisHTML(r.fault) + `
    <div class="card">
      <div class="card-head"><h3>How this was concluded</h3></div>
      ${traceHTML([
        { name: "User input", body: `${state.guided.answers.length} questions answered` },
        { name: "Facts used", body: `<ul>${leaves.map((l) => `<li>${esc(l.label)} ${chip(l.answer)}</li>`).join("")}</ul>` },
        { name: "Rules applied", kind: "rule", body: `<ul>${r.rules_used.map((id) => `<li>${ruleTag(id)}${esc(ruleText(id))}</li>`).join("")}</ul>` },
        { name: "Reasoning (proof tree)", kind: "rule", body: `<ul class="proof">${proofTreeHTML(r.proof)}</ul>` },
        { name: "Conclusion", kind: "end", body: esc(r.fault.name) },
      ])}
    </div>
    <div>${restartButton("Diagnose another problem")}</div>`;
}

function renderHistory() {
  const answers = state.guided.answers;
  $("#answer-list").innerHTML = answers.map((a) =>
    `<li><span>${esc(symptomById(a.id).label)}</span>${chip(a.answer)}</li>`).join("");
  $("#answers-empty").hidden = answers.length > 0;
  $("#undo-btn").disabled = answers.length === 0;
}

function restart() {
  state.guided.answers = [];
  return step();
}

function answer(value) {
  const id = $("#q-text").dataset.id;
  if (!id || $("#question-card").hidden) return;
  state.guided.answers.push({ id, answer: value });
  step();
}

export function initGuided() {
  const keys = { y: "yes", n: "no", d: "unknown" };
  $$(".answer-btn").forEach((b) => b.addEventListener("click", () => answer(b.dataset.answer)));
  document.addEventListener("keydown", (e) => {
    if (e.ctrlKey || e.metaKey || e.altKey) return;
    if (/^(INPUT|SELECT|TEXTAREA)$/.test(document.activeElement.tagName)) return;
    if (!$("#view-guided").classList.contains("active")) return;
    const v = keys[e.key.toLowerCase()];
    if (v) answer(v);
  });
  $("#why-toggle").addEventListener("click", (e) => {
    const box = $("#why-box");
    box.hidden = !box.hidden;
    e.currentTarget.setAttribute("aria-expanded", String(!box.hidden));
  });
  $("#undo-btn").addEventListener("click", () => { state.guided.answers.pop(); step(); });
  $("#restart-btn").addEventListener("click", restart);
  $("#result-box").addEventListener("click", (e) => { if (e.target.closest("[data-action=restart]")) restart(); });
  $("#goal-select").addEventListener("change", (e) => { state.guided.goal = e.target.value; restart(); });

  $("#goal-select").insertAdjacentHTML("beforeend",
    state.kb.faults.map((f) => `<option value="${esc(f.id)}">${esc(f.name)}</option>`).join(""));
  return restart();
}
