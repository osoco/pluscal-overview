----------------------------- MODULE contestia -----------------------------
EXTENDS TLC, Integers, Sequences, FiniteSets
CONSTANTS Applications, NULL

ApplicationStates == { "PENDING", "CONFIRMED" }
MessageType == { "create_application", "application_created" }
MessageSet == [ type: MessageType, application: Applications ]
Valid_Application_Data == [ Applications -> ApplicationStates \union { NULL } ]
        
(*--fair algorithm pass_applications_to_round
    
    variables
        core_queue = <<>>,
        backoffice_queue = <<>>,
        backoffice_data = [ application \in Applications |-> NULL ],
        core_data = [ application \in Applications |-> NULL ],        
        backoffice_commited_data = [ application \in Applications |-> NULL ];

    define
        Type_Invariant ==
            /\ backoffice_data \in Valid_Application_Data
            /\ backoffice_commited_data \in Valid_Application_Data
            /\ core_data \in Valid_Application_Data
            /\ (\A index \in DOMAIN core_queue: core_queue[index] \in MessageSet)
            /\ (\A index \in DOMAIN backoffice_queue: backoffice_queue[index] \in MessageSet)
                
        ApplicationsCreatedAtCore == { app \in Applications: core_data[app] = "CONFIRMED" }
        ApplicationsCreatedAtBackoffice == { app \in Applications: backoffice_data[app] /= NULL }
        ApplicationsToCreateAtBackoffice == Applications \ ApplicationsCreatedAtBackoffice
        
        Liveness ==
            \A application \in Applications:
                <>[](core_data[application] = "CONFIRMED" => backoffice_commited_data[application] = "CONFIRMED")
    end define;

    macro save_application_in_db(database, application, state)
        begin
            database[application] := state;
    end macro;

    macro publish_message(queue, type, application) 
        begin
            queue := Append(queue, [ type |-> type, application |-> application ]); 
    end macro;
    
    macro commit(application)
        begin   
            backoffice_commited_data[application] := backoffice_data[application];
    end macro;
    
    macro consume_message(queue, message) 
        begin
            if Len(queue) > 0 then
                message := Head(queue);
                queue := Tail(queue);
            else
                message := NULL;
            end if;
    end macro;
    
    macro update_application(application, state)
        begin
            backoffice_commited_data[application] := state;
    end macro;    

    process backoffice_producer = "Backoffice application creation process"
    variables current_application = NULL;
    begin
        Producer:
            while ApplicationsToCreateAtBackoffice /= {} do
                Create: 
                    with application \in ApplicationsToCreateAtBackoffice do
                        save_application_in_db(backoffice_data, application, "PENDING");
                        publish_message(core_queue, "create_application", application);
                        current_application := application;
                    end with;
                Finish:
                    commit(current_application);
            end while;
    end process;
    
    process core = "Core"
    variables request_consumed = NULL, consumed_requests = 0;
    begin
        Core:
            while consumed_requests < Cardinality(Applications) do
                \* await Len(core_queue) > 0;
                consume_message(core_queue, request_consumed);
                if request_consumed /= NULL /\ request_consumed.type = "create_application" then
                    consumed_requests := consumed_requests + 1;
                    save_application_in_db(core_data, request_consumed.application, "CONFIRMED");
                    publish_message(backoffice_queue, "application_created", request_consumed.application);
                else
                    skip;
                end if;
            end while;
    end process; 
        
    process backoffice_consumer = "Backoffice event consumer process"
    variables event_consumed = NULL, application_received = NULL, consumed_events = 0;
    begin
        Consumer:
            while consumed_events < Cardinality(Applications) do
                \* await Len(backoffice_queue) > 0;
                consume_message(backoffice_queue, event_consumed);
                if event_consumed /= NULL /\ event_consumed.type = "application_created" then
                    application_received := event_consumed.application;
                    consumed_events := consumed_events + 1;
                    if backoffice_commited_data[application_received] /= NULL then
                        update_application(application_received, "CONFIRMED");
                    else
                        skip;
                    end if;
                else
                    skip;
                end if;
            end while;
    end process;
    
       
    
    end algorithm; *)
\* BEGIN TRANSLATION
VARIABLES core_queue, backoffice_queue, backoffice_data, core_data, 
          backoffice_commited_data, pc

(* define statement *)
Type_Invariant ==
    /\ backoffice_data \in Valid_Application_Data
    /\ backoffice_commited_data \in Valid_Application_Data
    /\ core_data \in Valid_Application_Data
    /\ (\A index \in DOMAIN core_queue: core_queue[index] \in MessageSet)
    /\ (\A index \in DOMAIN backoffice_queue: backoffice_queue[index] \in MessageSet)

ApplicationsCreatedAtCore == { app \in Applications: core_data[app] = "CONFIRMED" }
ApplicationsCreatedAtBackoffice == { app \in Applications: backoffice_data[app] /= NULL }
ApplicationsToCreateAtBackoffice == Applications \ ApplicationsCreatedAtBackoffice

Liveness ==
    \A application \in Applications:
        <>[](core_data[application] = "CONFIRMED" => backoffice_commited_data[application] = "CONFIRMED")

VARIABLES current_application, request_consumed, consumed_requests, 
          event_consumed, application_received, consumed_events

vars == << core_queue, backoffice_queue, backoffice_data, core_data, 
           backoffice_commited_data, pc, current_application, 
           request_consumed, consumed_requests, event_consumed, 
           application_received, consumed_events >>

ProcSet == {"Backoffice application creation process"} \cup {"Core"} \cup {"Backoffice event consumer process"}

Init == (* Global variables *)
        /\ core_queue = <<>>
        /\ backoffice_queue = <<>>
        /\ backoffice_data = [ application \in Applications |-> NULL ]
        /\ core_data = [ application \in Applications |-> NULL ]
        /\ backoffice_commited_data = [ application \in Applications |-> NULL ]
        (* Process backoffice_producer *)
        /\ current_application = NULL
        (* Process core *)
        /\ request_consumed = NULL
        /\ consumed_requests = 0
        (* Process backoffice_consumer *)
        /\ event_consumed = NULL
        /\ application_received = NULL
        /\ consumed_events = 0
        /\ pc = [self \in ProcSet |-> CASE self = "Backoffice application creation process" -> "Producer"
                                        [] self = "Core" -> "Core"
                                        [] self = "Backoffice event consumer process" -> "Consumer"]

Producer == /\ pc["Backoffice application creation process"] = "Producer"
            /\ IF ApplicationsToCreateAtBackoffice /= {}
                  THEN /\ pc' = [pc EXCEPT !["Backoffice application creation process"] = "Create"]
                  ELSE /\ pc' = [pc EXCEPT !["Backoffice application creation process"] = "Done"]
            /\ UNCHANGED << core_queue, backoffice_queue, backoffice_data, 
                            core_data, backoffice_commited_data, 
                            current_application, request_consumed, 
                            consumed_requests, event_consumed, 
                            application_received, consumed_events >>

Create == /\ pc["Backoffice application creation process"] = "Create"
          /\ \E application \in ApplicationsToCreateAtBackoffice:
               /\ backoffice_data' = [backoffice_data EXCEPT ![application] = "PENDING"]
               /\ core_queue' = Append(core_queue, [ type |-> "create_application", application |-> application ])
               /\ current_application' = application
          /\ pc' = [pc EXCEPT !["Backoffice application creation process"] = "Finish"]
          /\ UNCHANGED << backoffice_queue, core_data, 
                          backoffice_commited_data, request_consumed, 
                          consumed_requests, event_consumed, 
                          application_received, consumed_events >>

Finish == /\ pc["Backoffice application creation process"] = "Finish"
          /\ backoffice_commited_data' = [backoffice_commited_data EXCEPT ![current_application] = backoffice_data[current_application]]
          /\ pc' = [pc EXCEPT !["Backoffice application creation process"] = "Producer"]
          /\ UNCHANGED << core_queue, backoffice_queue, backoffice_data, 
                          core_data, current_application, request_consumed, 
                          consumed_requests, event_consumed, 
                          application_received, consumed_events >>

backoffice_producer == Producer \/ Create \/ Finish

Core == /\ pc["Core"] = "Core"
        /\ IF consumed_requests < Cardinality(Applications)
              THEN /\ IF Len(core_queue) > 0
                         THEN /\ request_consumed' = Head(core_queue)
                              /\ core_queue' = Tail(core_queue)
                         ELSE /\ request_consumed' = NULL
                              /\ UNCHANGED core_queue
                   /\ IF request_consumed' /= NULL /\ request_consumed'.type = "create_application"
                         THEN /\ consumed_requests' = consumed_requests + 1
                              /\ core_data' = [core_data EXCEPT ![(request_consumed'.application)] = "CONFIRMED"]
                              /\ backoffice_queue' = Append(backoffice_queue, [ type |-> "application_created", application |-> (request_consumed'.application) ])
                         ELSE /\ TRUE
                              /\ UNCHANGED << backoffice_queue, core_data, 
                                              consumed_requests >>
                   /\ pc' = [pc EXCEPT !["Core"] = "Core"]
              ELSE /\ pc' = [pc EXCEPT !["Core"] = "Done"]
                   /\ UNCHANGED << core_queue, backoffice_queue, core_data, 
                                   request_consumed, consumed_requests >>
        /\ UNCHANGED << backoffice_data, backoffice_commited_data, 
                        current_application, event_consumed, 
                        application_received, consumed_events >>

core == Core

Consumer == /\ pc["Backoffice event consumer process"] = "Consumer"
            /\ IF consumed_events < Cardinality(Applications)
                  THEN /\ IF Len(backoffice_queue) > 0
                             THEN /\ event_consumed' = Head(backoffice_queue)
                                  /\ backoffice_queue' = Tail(backoffice_queue)
                             ELSE /\ event_consumed' = NULL
                                  /\ UNCHANGED backoffice_queue
                       /\ IF event_consumed' /= NULL /\ event_consumed'.type = "application_created"
                             THEN /\ application_received' = event_consumed'.application
                                  /\ consumed_events' = consumed_events + 1
                                  /\ IF backoffice_commited_data[application_received'] /= NULL
                                        THEN /\ backoffice_commited_data' = [backoffice_commited_data EXCEPT ![application_received'] = "CONFIRMED"]
                                        ELSE /\ TRUE
                                             /\ UNCHANGED backoffice_commited_data
                             ELSE /\ TRUE
                                  /\ UNCHANGED << backoffice_commited_data, 
                                                  application_received, 
                                                  consumed_events >>
                       /\ pc' = [pc EXCEPT !["Backoffice event consumer process"] = "Consumer"]
                  ELSE /\ pc' = [pc EXCEPT !["Backoffice event consumer process"] = "Done"]
                       /\ UNCHANGED << backoffice_queue, 
                                       backoffice_commited_data, 
                                       event_consumed, application_received, 
                                       consumed_events >>
            /\ UNCHANGED << core_queue, backoffice_data, core_data, 
                            current_application, request_consumed, 
                            consumed_requests >>

backoffice_consumer == Consumer

Next == backoffice_producer \/ core \/ backoffice_consumer
           \/ (* Disjunct to prevent deadlock on termination *)
              ((\A self \in ProcSet: pc[self] = "Done") /\ UNCHANGED vars)

Spec == /\ Init /\ [][Next]_vars
        /\ WF_vars(Next)

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION

=============================================================================
\* Modification History
\* Last modified Wed Sep 11 16:56:27 GMT 2019 by luque
\* Created Wed Sep 11 10:08:23 GMT 2019 by luque
