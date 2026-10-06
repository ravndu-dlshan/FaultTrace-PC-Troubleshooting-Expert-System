/*  =====================================================================
    CONSOLE INTERFACE  (console.pl)
    ---------------------------------------------------------------------
    A text-only interface that runs inside SWI-Prolog, useful for
    showing the engine without the web UI.

       ?- [console].
       ?- start.

    Answer questions with:  yes.  no.  unknown.  why.
    (every answer ends with a full stop, as usual in Prolog)
    ===================================================================== */

:- ensure_loaded(engine).

start :-
    nl, writeln('=== PC Troubleshooting Expert System ==='),
    writeln('1. Guided diagnosis (backward chaining)'),
    writeln('2. Symptom checker  (forward chaining)'),
    writeln('3. Quit'),
    write('Choose 1, 2 or 3: '), read(C),
    menu(C).

menu(1) :- !, all_fault_ids(Goals), bc_loop(Goals, []), start.
menu(2) :- !, fc_console, start.
menu(3) :- !, writeln('Goodbye.').
menu(_) :- writeln('Please type 1, 2 or 3 followed by a full stop.'), start.

/* ---------------- backward chaining session ---------------- */
bc_loop(Goals, Known) :-
    backward_chain(Goals, Known, Result),
    bc_step(Result, Goals, Known).

bc_step(ask(S, Stack), Goals, Known) :-
    symptom(S, _, Q, _),
    nl, format('Q: ~w~n', [Q]),
    write('   (yes / no / unknown / why): '), read(A),
    (   A == why
    ->  explain_why(Stack), bc_step(ask(S, Stack), Goals, Known)
    ;   memberchk(A, [yes, no, unknown])
    ->  bc_loop(Goals, [S-A|Known])
    ;   writeln('Please answer yes, no, unknown or why.'),
        bc_step(ask(S, Stack), Goals, Known)
    ).
bc_step(found(F, Proof), _, _) :-
    fault(F, Name, Expl, Steps, Sev),
    nl, format('DIAGNOSIS: ~w  (severity: ~w)~n', [Name, Sev]),
    format('Reason: ~w~n', [Expl]),
    writeln('Recommended steps:'),
    forall(member(St, Steps), format('   * ~w~n', [St])),
    nl, writeln('HOW this was concluded:'),
    print_proof(Proof, 2).
bc_step(none, _, _) :-
    nl, writeln('No diagnosis could be reached from your answers.'),
    writeln('Please consult a qualified technician.').

explain_why(Stack) :-
    nl, writeln('WHY: I am asking because I am trying to use these rules:'),
    forall(member(Id, Stack),
           ( rule_text(Id, T), format('   ~w: ~w~n', [Id, T]) )).

/* ---------------- forward chaining session ----------------- */
fc_console :-
    findall(S, symptom(S, _, _, _), Ss),
    nl, writeln('Symptoms:'),
    forall(nth1(I, Ss, S), ( symptom(S, L, _, _), format('  ~w. ~w~n', [I, L]) )),
    write('Numbers you can CONFIRM, e.g. [1,3,4]. : '), read(Ys),
    write('Numbers you can RULE OUT, e.g. [2].  : '), read(Ns),
    findall(S-yes, (member(I, Ys), nth1(I, Ss, S)), K1),
    findall(S-no,  (member(I, Ns), nth1(I, Ss, S)), K2),
    append(K1, K2, Known),
    forward_chain(Known, Cycles, WM),
    nl, writeln('Inference cycles:'),
    forall(member(cycle(N, CS, Id, Concl), Cycles),
           ( term_label(Concl, L),
             format('  Cycle ~w  conflict set ~w  -> fired ~w  => ~w~n', [N, CS, Id, L]) )),
    faults_in(WM, Fs),
    (   Fs == []
    ->  writeln('No diagnosis reached.')
    ;   nl, writeln('Diagnoses:'),
        forall(member(F, Fs), ( fault(F, Name, _, _, _), format('  * ~w~n', [Name]) ))
    ).
