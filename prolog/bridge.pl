/*  =====================================================================
    BRIDGE  (bridge.pl)
    ---------------------------------------------------------------------
    Connects the FastAPI backend to the Prolog engine.
    FastAPI starts:   swipl bridge.pl   and writes one JSON request to
    standard input. This file runs the request through the engine and
    prints one JSON reply to standard output.

    Requests
      {"action":"meta"}
      {"action":"forward",  "known":{"no_power":"yes", ...}}
      {"action":"backward", "goal":"any" | <fault id>, "known":{...}}
    ===================================================================== */

:- use_module(library(http/json)).
:- ensure_loaded(engine).

:- initialization(main, main).

main :-
    set_stream(user_input,  encoding(utf8)),
    set_stream(user_output, encoding(utf8)),
    catch(( json_read_dict(user_input, Req),
            handle(Req, Reply) ),
          E,
          ( message_to_codes(E, Msg), Reply = _{error: Msg} )),
    json_write_dict(user_output, Reply, [width(0)]),
    nl.

message_to_codes(E, S) :- format(string(S), '~w', [E]).

/* ----------------------------- dispatch ------------------------------ */
handle(Req, Reply) :-
    atom_string(Action, Req.action),
    handle(Action, Req, Reply).

handle(meta, _, _{categories:Cs, symptoms:Ss, faults:Fs, rules:Rs,
                  derived:Ds, references:Refs}) :-
    findall(_{id:I, label:L}, category(I, L), Cs),
    findall(_{id:I, label:L, question:Q, category:C}, symptom(I, L, Q, C), Ss),
    findall(D, (fault(F,_,_,_,_), fault_json(F, D)), Fs),
    findall(R, (rule(Id,_,_,_), rule_json(Id, R)), Rs),
    findall(_{id:I, label:L}, derived(I, L), Ds),
    findall(_{id:I, text:T}, reference(I, T), Refs).

handle(forward, Req, _{mode:forward, input:Input, cycles:CyJ,
                       derived:DerJ, faults:FJ}) :-
    known(Req, Known),
    forward_chain(Known, Cycles, WM),
    findall(_{id:S, label:L, answer:A},
            (member(S-A, Known), A \== unknown, symptom(S, L, _, _)), Input),
    maplist(cycle_json, Cycles, CyJ),
    findall(_{id:D, label:L}, (derived(D, L), memberchk(D, WM)), DerJ),
    faults_in(WM, Faults),
    findall(J, (member(F, Faults), fault_json(F, J)), FJ).

handle(backward, Req, Reply) :-
    known(Req, Known),
    goals(Req, Goals),
    backward_chain(Goals, Known, Result),
    backward_reply(Result, Reply).

backward_reply(ask(S, Stack), _{status:ask, symptom:SJ, why:Why}) :-
    symptom(S, L, Q, C),
    SJ = _{id:S, label:L, question:Q, category:C},
    why_json(Stack, Why).
backward_reply(found(F, Proof), _{status:found, fault:FJ, proof:PJ, rules_used:Used}) :-
    fault_json(F, FJ),
    proof_json(Proof, PJ),
    findall(Id, sub_proof_rule(Proof, Id), Used).  % bottom-up order
backward_reply(none, _{status:none}).

sub_proof_rule(by(Id, _, Subs), R) :-
    ( member(P, Subs), sub_proof_rule(P, R) ; R = Id ).

/* ----------------------------- inputs -------------------------------- */
known(Req, Known) :-
    (   get_dict(known, Req, K) -> dict_pairs(K, _, Pairs) ; Pairs = [] ),
    findall(S-A, ( member(S-V, Pairs), atom_string(A, V),
                   memberchk(A, [yes, no, unknown]) ), Known).

goals(Req, Goals) :-
    (   get_dict(goal, Req, G), atom_string(GA, G), GA \== any
    ->  Goals = [GA]
    ;   all_fault_ids(Goals)
    ).

/* ----------------------------- outputs ------------------------------- */
fault_json(F, _{id:F, name:N, explanation:E, steps:St, severity:Sev}) :-
    fault(F, N, E, St, Sev).

rule_json(Id, _{id:Id, conditions:CJ, conclusion:Cl, conclusion_label:CL,
                text:T, reference:Ref, source:Src}) :-
    rule(Id, Conds, Concl, Ref),
    maplist(cond_json, Conds, CJ),
    term_string(Concl, Cl),
    term_label(Concl, CL),
    rule_text(Id, T),
    reference(Ref, Src).

cond_json(not(S), _{id:S, negated:true,  label:L}) :- !, term_label(S, L).
cond_json(C,      _{id:C, negated:false, label:L}) :- term_label(C, L).

cycle_json(cycle(N, Conflict, Id, Concl),
           _{cycle:N, conflict_set:Conflict, fired:Id, text:T,
             new_fact:CS, new_fact_label:CL}) :-
    rule_text(Id, T),
    term_string(Concl, CS),
    term_label(Concl, CL).

why_json([], _{rule:null, text:"Checking the next possible fault.", chain:[]}).
why_json([Id|Rest], _{rule:Id, text:T, chain:Chain}) :-
    rule_text(Id, T),
    findall(_{rule:R, text:RT}, (member(R, [Id|Rest]), rule_text(R, RT)), Chain).

proof_json(user(S, A), _{type:fact, id:S, label:L, answer:A}) :-
    symptom(S, L, _, _).
proof_json(by(Id, Goal, Subs), _{type:rule, rule:Id, text:T, conclusion:GS,
                                 label:GL, reference:Src, children:Kids}) :-
    rule_text(Id, T),
    term_string(Goal, GS),
    term_label(Goal, GL),
    rule(Id, _, _, Ref), reference(Ref, Src),
    maplist(proof_json, Subs, Kids).
