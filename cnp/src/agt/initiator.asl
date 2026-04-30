// =============================================================================
// CNP Initiator Agent
//
// Beliefs injected from cnp.jcm:
//   contracts([1,..,i])  -- list of contract indices (length = i parallel CNPs)
//   service(Type)        -- requested service: compute | storage | network
//
// Protocol:
//   1. Broadcast CFP to all agents
//   2. Wait 3 seconds for proposals
//   3. Select lowest price winner
//   4. Accept winner, reject others
//   5. Wait for inform_done confirmation
// =============================================================================

!start.

+!start
   <- ?contracts(Indices);
      ?service(Svc);
      .my_name(Me);
      .length(Indices, N);
      .println("[", Me, "] launching ", N, " parallel CNP(s) for service: ", Svc);
      !launch_all(Indices).

// Spawn one new intention per contract index (concurrent execution)
+!launch_all([]).
+!launch_all([Idx | Rest])
   <- !!run_cnp(Idx);
      !launch_all(Rest).

// =============================================================================
// Main CNP round for a single contract index
// =============================================================================
+!run_cnp(Idx)
   <- .my_name(Me);
      ConvId = cnp(Me, Idx);
      ?service(Svc);
      Budget = 150;
      !now(T0);
      .println("[", Me, "/", Idx, "] CFP service=", Svc, " budget=", Budget);
      .broadcast(tell, cfp(ConvId, Svc, Budget));
      .wait(3000);
      .findall(p(Price, Sender), propose(ConvId, Price)[source(Sender)], Proposals);
      .length(Proposals, NP);
      .println("[", Me, "/", Idx, "] received ", NP, " proposals: ", Proposals);
      +cfp_time(ConvId, T0);
      !evaluate_proposals(ConvId, Svc, Proposals);
      .abolish(propose(ConvId, _));
      .abolish(refuse(ConvId)).

// =============================================================================
// No proposals -- CNP fails
// =============================================================================
+!evaluate_proposals(ConvId, Svc, [])
   <- ?cfp_time(ConvId, T0);
      !now(T1); Elapsed = T1 - T0;
      .println("[FAIL] ", ConvId, " -- no proposals received");
      .println("[METRIC] result=fail conv=", ConvId, " service=", Svc, " proposals=0 elapsed_ms=", Elapsed);
      .abolish(cfp_time(ConvId, _)).

// =============================================================================
// At least one proposal -- pick winner (lowest price) and close
// =============================================================================
+!evaluate_proposals(ConvId, Svc, Proposals) : Proposals \== []
   <- !find_winner(Proposals, p(999999, none), p(WinPrice, WinAgent));
      .length(Proposals, NP);
      .println("[WIN]  ", ConvId, " -> ", WinAgent, " price=", WinPrice);
      .send(WinAgent, tell, accept_proposal(ConvId, WinPrice));
      !reject_others(ConvId, Proposals, WinAgent);
      .wait(inform_done(ConvId), 10000, _);
      !check_done(ConvId, Svc, NP, WinPrice, WinAgent);
      .abolish(inform_done(ConvId)).

// =============================================================================
// Helper: current time in milliseconds (epoch-of-day)
// =============================================================================
+!now(T)
   <- .time(H, M, S, Ms);
      T = H*3600000 + M*60000 + S*1000 + Ms.

// =============================================================================
// Iterative minimum-price winner selection (no arithmetic needed)
// =============================================================================
+!find_winner([], Best, Best).
+!find_winner([p(P, A) | Rest], p(Best, _), Winner) : P < Best
   <- !find_winner(Rest, p(P, A), Winner).
+!find_winner([_ | Rest], Current, Winner)
   <- !find_winner(Rest, Current, Winner).

// =============================================================================
// Send reject to all proposers except the winner
// =============================================================================
+!reject_others(_, [], _).
+!reject_others(ConvId, [p(_, WinAgent) | Rest], WinAgent)
   <- !reject_others(ConvId, Rest, WinAgent).
+!reject_others(ConvId, [p(_, Agent) | Rest], WinAgent)
   <- .send(Agent, tell, reject_proposal(ConvId));
      !reject_others(ConvId, Rest, WinAgent).

// =============================================================================
// Check outcome by querying the belief base directly after .wait
// Guard on inform_done(ConvId) tells us if the task completed in time
// =============================================================================
+!check_done(ConvId, Svc, NP, WinPrice, WinAgent) : inform_done(ConvId)
   <- ?cfp_time(ConvId, T0);
      !now(T1); Elapsed = T1 - T0;
      .println("[DONE] ", ConvId, " completed by ", WinAgent);
      .println("[METRIC] result=done conv=", ConvId, " service=", Svc,
               " proposals=", NP, " winner=", WinAgent,
               " price=", WinPrice, " elapsed_ms=", Elapsed);
      .abolish(cfp_time(ConvId, _)).
+!check_done(ConvId, Svc, NP, WinPrice, WinAgent)
   <- ?cfp_time(ConvId, T0);
      !now(T1); Elapsed = T1 - T0;
      .println("[WARN] ", ConvId, " -- timeout waiting for inform_done");
      .println("[METRIC] result=timeout conv=", ConvId, " service=", Svc,
               " proposals=", NP, " winner=", WinAgent,
               " price=", WinPrice, " elapsed_ms=", Elapsed);
      .abolish(cfp_time(ConvId, _)).

// =============================================================================
// Log incoming refusals (belief added automatically by Jason tell)
// =============================================================================
+refuse(ConvId)[source(S)]
   <- .println("[REFUSAL] ", S, " refused ", ConvId).

{ include("$jacamoJar/templates/common-cartago.asl") }
{ include("$jacamoJar/templates/common-moise.asl") }

