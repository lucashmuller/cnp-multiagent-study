// =============================================================================
// CNP Participant Agent
//
// Beliefs injected from cnp.jcm:
//   service(Type)   -- service offered: compute | storage | network
//   strategy(S)     -- pricing strategy: random | fixed | aggressive | conservative
//
// Protocol:
//   - Receive CFP: if service matches, compute price and propose; otherwise refuse
//   - Receive accept_proposal: simulate task execution and send inform_done
//   - Receive reject_proposal: log and clean up
// =============================================================================

// CFP matches our service -- compute price and propose
+cfp(ConvId, Svc, Budget)[source(Initiator)]
   : service(Svc)
   <- ?strategy(S);
      !compute_price(S, Price);
      .my_name(Me);
      .println("[", Me, "] propose ", Price, " for ", ConvId, " to ", Initiator);
      .send(Initiator, tell, propose(ConvId, Price));
      .abolish(cfp(ConvId, _, _)).

// CFP does not match our service type -- refuse
+cfp(ConvId, Svc, _)[source(Initiator)]
   : not service(Svc)
   <- .send(Initiator, tell, refuse(ConvId));
      .abolish(cfp(ConvId, _, _)).

// =============================================================================
// Pricing strategies
// .random(R) is called once in the parent plan, then guards dispatch to a price.
// Using separate sub-goals so the random draw happens once per CFP.
// =============================================================================

// random: prices in [55, 80, 100, 120, 145]
+!compute_price(random, Price)
   <- .random(R); !pick_price_random(R, Price).
+!pick_price_random(R, 55)  : R < 0.2.
+!pick_price_random(R, 80)  : R >= 0.2 & R < 0.4.
+!pick_price_random(R, 100) : R >= 0.4 & R < 0.6.
+!pick_price_random(R, 120) : R >= 0.6 & R < 0.8.
+!pick_price_random(_, 145).

// fixed: always 80
+!compute_price(fixed, 80) <- true.

// aggressive: prices in [30, 35, 40, 45, 50] -- undercuts others to win
+!compute_price(aggressive, Price)
   <- .random(R); !pick_price_aggressive(R, Price).
+!pick_price_aggressive(R, 30) : R < 0.2.
+!pick_price_aggressive(R, 35) : R >= 0.2 & R < 0.4.
+!pick_price_aggressive(R, 40) : R >= 0.4 & R < 0.6.
+!pick_price_aggressive(R, 45) : R >= 0.6 & R < 0.8.
+!pick_price_aggressive(_, 50).

// conservative: prices in [100, 110, 120, 135, 150] -- rarely wins
+!compute_price(conservative, Price)
   <- .random(R); !pick_price_conservative(R, Price).
+!pick_price_conservative(R, 100) : R < 0.2.
+!pick_price_conservative(R, 110) : R >= 0.2 & R < 0.4.
+!pick_price_conservative(R, 120) : R >= 0.4 & R < 0.6.
+!pick_price_conservative(R, 135) : R >= 0.6 & R < 0.8.
+!pick_price_conservative(_, 150).

// =============================================================================
// Execute accepted task -- simulate work and notify initiator
// =============================================================================
+accept_proposal(ConvId, Price)[source(Initiator)]
   <- .my_name(Me);
      .println("[", Me, "] ACCEPTED ", ConvId, " price=", Price, " -- executing...");
      .random(R);
      !exec_timed(Me, ConvId, Initiator, R).

// Execution time tiers chosen by guard on the random value
+!exec_timed(Me, ConvId, Initiator, R) : R < 0.33
   <- .wait(500);
      .println("[", Me, "] done ", ConvId, " (500ms)");
      .send(Initiator, tell, inform_done(ConvId));
      .abolish(accept_proposal(ConvId, _)).
+!exec_timed(Me, ConvId, Initiator, R) : R >= 0.33 & R < 0.67
   <- .wait(1000);
      .println("[", Me, "] done ", ConvId, " (1000ms)");
      .send(Initiator, tell, inform_done(ConvId));
      .abolish(accept_proposal(ConvId, _)).
+!exec_timed(Me, ConvId, Initiator, _)
   <- .wait(2000);
      .println("[", Me, "] done ", ConvId, " (2000ms)");
      .send(Initiator, tell, inform_done(ConvId));
      .abolish(accept_proposal(ConvId, _)).

// =============================================================================
// Handle rejection -- log and clean up
// =============================================================================
+reject_proposal(ConvId)[source(_)]
   <- .my_name(Me);
      .println("[", Me, "] rejected for ", ConvId);
      .abolish(reject_proposal(ConvId)).

{ include("$jacamoJar/templates/common-cartago.asl") }
{ include("$jacamoJar/templates/common-moise.asl") }
