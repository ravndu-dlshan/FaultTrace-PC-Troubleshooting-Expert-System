/*  =====================================================================
    PC TROUBLESHOOTING EXPERT SYSTEM  -  INFERENCE ENGINE  (engine.pl)
    ---------------------------------------------------------------------
    Works on the knowledge in kb.pl. Provides:

      backward_chain(+Goals, +Known, -Result)   goal-driven reasoning
      forward_chain(+Known, -Cycles, -WM)       data-driven reasoning

    Known is the user's answers: a list of Symptom-Answer pairs where
    Answer is yes, no or unknown.   Example:  [no_power-yes, outlet_works-no]

    Unknown answers make a condition false in BOTH directions, so the
    system never concludes anything the user did not confirm.
    ===================================================================== */

:- ensure_loaded(kb).

/* =====================================================================
   PART A - BACKWARD CHAINING (goal driven)
   ---------------------------------------------------------------------
   Start from a hypothesis such as fault(psu_failure) and work
   backwards through the rules that could conclude it.
   When a condition is a symptom the user has not answered yet, the
   engine stops and throws  ask(Symptom, RuleStack)  so the interface
   can ask the question and explain WHY it is being asked.
   The interface then re-runs the query with the new answer added.
   ===================================================================== */

%  backward_chain(+Goals, +Known, -Result)
%  Result is one of:
%     found(FaultId, Proof)          a hypothesis was proved
%     ask(Symptom, RuleStack)        more information is needed
%     none                           no hypothesis could be proved
backward_chain(Goals, Known, Result) :-
    catch(first_proved(Goals, Known, Result),
          ask(S, Stack),
          Result = ask(S, Stack)).

first_proved(Goals, Known, found(F, Proof)) :-
    member(F, Goals),
    prove(fault(F), Known, [], Proof), !.
first_proved(_, _, none).

%  prove(+Goal, +Known, +RuleStack, -Proof)
%  Proof records HOW the goal was established (used for explanations).

% A negated symptom: true only if the user answered "no".
prove(not(S), Known, Stack, user(S, no)) :- !,
    answer(S, Known, Stack, A),
    A == no.

% A symptom: true only if the user answered "yes".
prove(S, Known, Stack, user(S, yes)) :-
    symptom(S, _, _, _), !,
    answer(S, Known, Stack, A),
    A == yes.

% A derived fact or fault: find a rule that concludes it and prove
% every condition of that rule (depth-first, left to right).
prove(Goal, Known, Stack, by(Id, Goal, SubProofs)) :-
    rule(Id, Conditions, Goal, _),
    prove_all(Conditions, Known, [Id|Stack], SubProofs).

prove_all([], _, _, []).
prove_all([C|Cs], Known, Stack, [P|Ps]) :-
    prove(C, Known, Stack, P),
    prove_all(Cs, Known, Stack, Ps).

%  answer(+S, +Known, +Stack, -A): look up the user's answer or ask.
answer(S, Known, _, A) :-
    memberchk(S-A0, Known), !,
    A = A0.
answer(S, _, Stack, _) :-
    throw(ask(S, Stack)).

%  all_fault_ids(-Ids): every fault in knowledge-base order.
all_fault_ids(Ids) :-
    findall(F, fault(F, _, _, _, _), Ids).


/* =====================================================================
   PART B - FORWARD CHAINING (data driven)
   ---------------------------------------------------------------------
   Start from the facts the user supplied (working memory) and keep
   firing rules until nothing new can be concluded.

   Recognise-act cycle:
     1. MATCH    find every rule whose conditions are all true and whose
                 conclusion is not yet in working memory (conflict set)
     2. RESOLVE  pick one rule - the lowest rule number (rule order)
     3. ACT      add its conclusion to working memory
     4. repeat until the conflict set is empty
   ===================================================================== */

%  forward_chain(+Known, -Cycles, -FinalWM)
%  Cycles = [cycle(N, ConflictSet, FiredRule, NewFact), ...]
forward_chain(Known, Cycles, FinalWM) :-
    findall(S, member(S-yes, Known), WM0),
    fc_loop(1, WM0, Known, Cycles, FinalWM).

fc_loop(N, WM, Known, [cycle(N, Conflict, Id, Concl) | Rest], FinalWM) :-
    conflict_set(WM, Known, Conflict),
    Conflict = [Id|_], !,                       % resolution: first rule
    rule(Id, _, Concl, _),
    N1 is N + 1,
    fc_loop(N1, [Concl|WM], Known, Rest, FinalWM).
fc_loop(_, WM, _, [], WM).                      % nothing left to fire

conflict_set(WM, Known, Ids) :-
    findall(Id,
            ( rule(Id, Conds, Concl, _),
              \+ memberchk(Concl, WM),
              holds_all(Conds, WM, Known) ),
            Ids).

holds_all([], _, _).
holds_all([C|Cs], WM, Known) :-
    holds(C, WM, Known),
    holds_all(Cs, WM, Known).

holds(not(S), _, Known) :- !, memberchk(S-no, Known).
holds(C, WM, _)         :- memberchk(C, WM).

%  faults_in(+WM, -Faults): the final diagnoses in working memory.
faults_in(WM, Faults) :-
    findall(F, ( fault(F, _, _, _, _), memberchk(fault(F), WM) ), Faults).


/* =====================================================================
   PART C - EXPLANATION HELPERS
   ===================================================================== */

%  rule_text(+Id, -Text): "IF a AND b THEN c" in plain English.
rule_text(Id, Text) :-
    rule(Id, Conds, Concl, _),
    maplist(condition_text, Conds, CondTexts),
    atomic_list_concat(CondTexts, ' AND ', IfPart),
    term_label(Concl, ThenPart),
    format(atom(Text), 'IF ~w THEN ~w', [IfPart, ThenPart]).

condition_text(not(S), T) :- !, symptom(S, L, _, _), format(atom(T), 'NOT (~w)', [L]).
condition_text(C, T)      :- term_label(C, T).

term_label(fault(F), L) :- !, fault(F, Name, _, _, _), format(atom(L), 'diagnosis: ~w', [Name]).
term_label(S, L)        :- symptom(S, L, _, _), !.
term_label(D, L)        :- derived(D, L), !.
term_label(X, X).

%  print_proof(+Proof, +Indent): readable HOW explanation for the console.
print_proof(user(S, A), I) :-
    symptom(S, L, _, _),
    tab(I), format('- You answered ~w to: ~w~n', [A, L]).
print_proof(by(Id, Goal, Subs), I) :-
    term_label(Goal, GL), rule_text(Id, RT),
    tab(I), format('+ ~w was concluded by rule ~w~n', [GL, Id]),
    I2 is I + 4,
    tab(I2), format('(~w)~n', [RT]),
    forall(member(P, Subs), print_proof(P, I2)).
