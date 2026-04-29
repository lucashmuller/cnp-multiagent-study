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
      .println("[", Me, "/", Idx, "] CFP service=", Svc, " budget=", Budget);
      .broadcast(tell, cfp(ConvId, Svc, Budget));
      // Wait for proposals to arrive (3 seconds)
      .wait(3000);
      // Collect all proposals received for this ConvId
      .findall(p(Price, Sender), propose(ConvId, Price)[source(Sender)], Proposals);
      .length(Proposals, NP);
      .println("[", Me, "/", Idx, "] received ", NP, " proposals: ", Proposals);
      !evaluate_proposals(ConvId, Proposals);
      // Cleanup beliefs for this conversation
      .abolish(propose(ConvId, _));
      .abolish(refuse(ConvId)).

// =============================================================================
// No proposals -- CNP fails
// =============================================================================
+!evaluate_proposals(ConvId, [])
   <- .println("[FAIL] ", ConvId, " -- no proposals received").

// =============================================================================
// At least one proposal -- pick winner (lowest price) and close
// =============================================================================
+!evaluate_proposals(ConvId, Proposals) : Proposals \== []
   <- !find_winner(Proposals, p(999999, none), p(WinPrice, WinAgent));
      .println("[WIN]  ", ConvId, " -> ", WinAgent, " price=", WinPrice);
      .send(WinAgent, tell, accept_proposal(ConvId, WinPrice));
      !reject_others(ConvId, Proposals, WinAgent);
      // Wait up to 10 seconds for task completion
      .wait(inform_done(ConvId), 10000, _);
      !check_done(ConvId, WinAgent);
      .abolish(inform_done(ConvId)).

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
+!check_done(ConvId, Agent) : inform_done(ConvId)
   <- .println("[DONE] ", ConvId, " completed by ", Agent).
+!check_done(ConvId, _)
   <- .println("[WARN] ", ConvId, " -- timeout waiting for inform_done").

// =============================================================================
// Log incoming refusals (belief added automatically by Jason tell)
// =============================================================================
+refuse(ConvId)[source(S)]
   <- .println("[REFUSAL] ", S, " refused ", ConvId).

{ include("$jacamoJar/templates/common-cartago.asl") }
{ include("$jacamoJar/templates/common-moise.asl") }
