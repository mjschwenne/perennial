(* autogenerated from github.com/mit-pdos/gokv/vrsm/replica *)
From Perennial.goose_lang Require Import prelude.
From Goose Require github_com.goose_lang.std.
From Goose Require github_com.mit_pdos.gokv.reconnectclient.
From Goose Require github_com.mit_pdos.gokv.urpc.
From Goose Require github_com.mit_pdos.gokv.vrsm.configservice.
From Goose Require github_com.mit_pdos.gokv.vrsm.e.
From Goose Require github_com.tchajed.marshal.

From Perennial.goose_lang Require Import ffi.grove_prelude.

(* 0_marshal.go *)

Definition Op: ty := slice.T byteT.

Definition ApplyAsBackupArgs := struct.decl [
  "epoch" :: uint64T;
  "index" :: uint64T;
  "op" :: slice.T byteT
].

Definition EncodeApplyAsBackupArgs: val :=
  rec: "EncodeApplyAsBackupArgs" "args" :=
    let: "enc" := ref_to (slice.T byteT) (NewSliceWithCap byteT #0 ((#8 + #8) + (slice.len (struct.loadF ApplyAsBackupArgs "op" "args")))) in
    "enc" <-[slice.T byteT] (marshal.WriteInt (![slice.T byteT] "enc") (struct.loadF ApplyAsBackupArgs "epoch" "args"));;
    "enc" <-[slice.T byteT] (marshal.WriteInt (![slice.T byteT] "enc") (struct.loadF ApplyAsBackupArgs "index" "args"));;
    "enc" <-[slice.T byteT] (marshal.WriteBytes (![slice.T byteT] "enc") (struct.loadF ApplyAsBackupArgs "op" "args"));;
    ![slice.T byteT] "enc".

Definition DecodeApplyAsBackupArgs: val :=
  rec: "DecodeApplyAsBackupArgs" "enc_args" :=
    let: "enc" := ref_to (slice.T byteT) "enc_args" in
    let: "args" := struct.alloc ApplyAsBackupArgs (zero_val (struct.t ApplyAsBackupArgs)) in
    let: ("0_ret", "1_ret") := marshal.ReadInt (![slice.T byteT] "enc") in
    struct.storeF ApplyAsBackupArgs "epoch" "args" "0_ret";;
    "enc" <-[slice.T byteT] "1_ret";;
    let: ("0_ret", "1_ret") := marshal.ReadInt (![slice.T byteT] "enc") in
    struct.storeF ApplyAsBackupArgs "index" "args" "0_ret";;
    "enc" <-[slice.T byteT] "1_ret";;
    struct.storeF ApplyAsBackupArgs "op" "args" (![slice.T byteT] "enc");;
    "args".

Definition SetStateArgs := struct.decl [
  "Epoch" :: uint64T;
  "NextIndex" :: uint64T;
  "CommittedNextIndex" :: uint64T;
  "State" :: slice.T byteT
].

Definition EncodeSetStateArgs: val :=
  rec: "EncodeSetStateArgs" "args" :=
    let: "enc" := ref_to (slice.T byteT) (NewSliceWithCap byteT #0 (#8 + (slice.len (struct.loadF SetStateArgs "State" "args")))) in
    "enc" <-[slice.T byteT] (marshal.WriteInt (![slice.T byteT] "enc") (struct.loadF SetStateArgs "Epoch" "args"));;
    "enc" <-[slice.T byteT] (marshal.WriteInt (![slice.T byteT] "enc") (struct.loadF SetStateArgs "NextIndex" "args"));;
    "enc" <-[slice.T byteT] (marshal.WriteInt (![slice.T byteT] "enc") (struct.loadF SetStateArgs "CommittedNextIndex" "args"));;
    "enc" <-[slice.T byteT] (marshal.WriteBytes (![slice.T byteT] "enc") (struct.loadF SetStateArgs "State" "args"));;
    ![slice.T byteT] "enc".

Definition DecodeSetStateArgs: val :=
  rec: "DecodeSetStateArgs" "enc_args" :=
    let: "enc" := ref_to (slice.T byteT) "enc_args" in
    let: "args" := struct.alloc SetStateArgs (zero_val (struct.t SetStateArgs)) in
    let: ("0_ret", "1_ret") := marshal.ReadInt (![slice.T byteT] "enc") in
    struct.storeF SetStateArgs "Epoch" "args" "0_ret";;
    "enc" <-[slice.T byteT] "1_ret";;
    let: ("0_ret", "1_ret") := marshal.ReadInt (![slice.T byteT] "enc") in
    struct.storeF SetStateArgs "NextIndex" "args" "0_ret";;
    "enc" <-[slice.T byteT] "1_ret";;
    let: ("0_ret", "1_ret") := marshal.ReadInt (![slice.T byteT] "enc") in
    struct.storeF SetStateArgs "CommittedNextIndex" "args" "0_ret";;
    "enc" <-[slice.T byteT] "1_ret";;
    struct.storeF SetStateArgs "State" "args" (![slice.T byteT] "enc");;
    "args".

Definition GetStateArgs := struct.decl [
  "Epoch" :: uint64T
].

Definition EncodeGetStateArgs: val :=
  rec: "EncodeGetStateArgs" "args" :=
    let: "enc" := ref_to (slice.T byteT) (NewSliceWithCap byteT #0 #8) in
    "enc" <-[slice.T byteT] (marshal.WriteInt (![slice.T byteT] "enc") (struct.loadF GetStateArgs "Epoch" "args"));;
    ![slice.T byteT] "enc".

Definition DecodeGetStateArgs: val :=
  rec: "DecodeGetStateArgs" "enc" :=
    let: "args" := struct.alloc GetStateArgs (zero_val (struct.t GetStateArgs)) in
    let: ("0_ret", "1_ret") := marshal.ReadInt "enc" in
    struct.storeF GetStateArgs "Epoch" "args" "0_ret";;
    "1_ret";;
    "args".

Definition GetStateReply := struct.decl [
  "Err" :: e.Error;
  "NextIndex" :: uint64T;
  "CommittedNextIndex" :: uint64T;
  "State" :: slice.T byteT
].

Definition EncodeGetStateReply: val :=
  rec: "EncodeGetStateReply" "reply" :=
    let: "enc" := ref_to (slice.T byteT) (NewSliceWithCap byteT #0 (#8 + (slice.len (struct.loadF GetStateReply "State" "reply")))) in
    "enc" <-[slice.T byteT] (marshal.WriteInt (![slice.T byteT] "enc") (struct.loadF GetStateReply "Err" "reply"));;
    "enc" <-[slice.T byteT] (marshal.WriteInt (![slice.T byteT] "enc") (struct.loadF GetStateReply "NextIndex" "reply"));;
    "enc" <-[slice.T byteT] (marshal.WriteInt (![slice.T byteT] "enc") (struct.loadF GetStateReply "CommittedNextIndex" "reply"));;
    "enc" <-[slice.T byteT] (marshal.WriteBytes (![slice.T byteT] "enc") (struct.loadF GetStateReply "State" "reply"));;
    ![slice.T byteT] "enc".

Definition DecodeGetStateReply: val :=
  rec: "DecodeGetStateReply" "enc_reply" :=
    let: "enc" := ref_to (slice.T byteT) "enc_reply" in
    let: "reply" := struct.alloc GetStateReply (zero_val (struct.t GetStateReply)) in
    let: ("0_ret", "1_ret") := marshal.ReadInt (![slice.T byteT] "enc") in
    struct.storeF GetStateReply "Err" "reply" "0_ret";;
    "enc" <-[slice.T byteT] "1_ret";;
    let: ("0_ret", "1_ret") := marshal.ReadInt (![slice.T byteT] "enc") in
    struct.storeF GetStateReply "NextIndex" "reply" "0_ret";;
    "enc" <-[slice.T byteT] "1_ret";;
    let: ("0_ret", "1_ret") := marshal.ReadInt (![slice.T byteT] "enc") in
    struct.storeF GetStateReply "CommittedNextIndex" "reply" "0_ret";;
    "enc" <-[slice.T byteT] "1_ret";;
    struct.storeF GetStateReply "State" "reply" (![slice.T byteT] "enc");;
    "reply".

Definition BecomePrimaryArgs := struct.decl [
  "Epoch" :: uint64T;
  "Replicas" :: slice.T grove_ffi.Address
].

Definition EncodeBecomePrimaryArgs: val :=
  rec: "EncodeBecomePrimaryArgs" "args" :=
    let: "enc" := ref_to (slice.T byteT) (NewSliceWithCap byteT #0 ((#8 + #8) + (#8 * (slice.len (struct.loadF BecomePrimaryArgs "Replicas" "args"))))) in
    "enc" <-[slice.T byteT] (marshal.WriteInt (![slice.T byteT] "enc") (struct.loadF BecomePrimaryArgs "Epoch" "args"));;
    "enc" <-[slice.T byteT] (marshal.WriteInt (![slice.T byteT] "enc") (slice.len (struct.loadF BecomePrimaryArgs "Replicas" "args")));;
    ForSlice uint64T <> "h" (struct.loadF BecomePrimaryArgs "Replicas" "args")
      ("enc" <-[slice.T byteT] (marshal.WriteInt (![slice.T byteT] "enc") "h"));;
    ![slice.T byteT] "enc".

Definition DecodeBecomePrimaryArgs: val :=
  rec: "DecodeBecomePrimaryArgs" "enc_args" :=
    let: "enc" := ref_to (slice.T byteT) "enc_args" in
    let: "args" := struct.alloc BecomePrimaryArgs (zero_val (struct.t BecomePrimaryArgs)) in
    let: ("0_ret", "1_ret") := marshal.ReadInt (![slice.T byteT] "enc") in
    struct.storeF BecomePrimaryArgs "Epoch" "args" "0_ret";;
    "enc" <-[slice.T byteT] "1_ret";;
    let: "replicasLen" := ref (zero_val uint64T) in
    let: ("0_ret", "1_ret") := marshal.ReadInt (![slice.T byteT] "enc") in
    "replicasLen" <-[uint64T] "0_ret";;
    "enc" <-[slice.T byteT] "1_ret";;
    struct.storeF BecomePrimaryArgs "Replicas" "args" (NewSlice grove_ffi.Address (![uint64T] "replicasLen"));;
    ForSlice uint64T "i" <> (struct.loadF BecomePrimaryArgs "Replicas" "args")
      (let: ("0_ret", "1_ret") := marshal.ReadInt (![slice.T byteT] "enc") in
      SliceSet uint64T (struct.loadF BecomePrimaryArgs "Replicas" "args") "i" "0_ret";;
      "enc" <-[slice.T byteT] "1_ret");;
    "args".

Definition ApplyReply := struct.decl [
  "Err" :: e.Error;
  "Reply" :: slice.T byteT
].

Definition EncodeApplyReply: val :=
  rec: "EncodeApplyReply" "reply" :=
    let: "enc" := ref_to (slice.T byteT) (NewSliceWithCap byteT #0 (#8 + (slice.len (struct.loadF ApplyReply "Reply" "reply")))) in
    "enc" <-[slice.T byteT] (marshal.WriteInt (![slice.T byteT] "enc") (struct.loadF ApplyReply "Err" "reply"));;
    "enc" <-[slice.T byteT] (marshal.WriteBytes (![slice.T byteT] "enc") (struct.loadF ApplyReply "Reply" "reply"));;
    ![slice.T byteT] "enc".

Definition DecodeApplyReply: val :=
  rec: "DecodeApplyReply" "enc_reply" :=
    let: "enc" := ref_to (slice.T byteT) "enc_reply" in
    let: "reply" := struct.alloc ApplyReply (zero_val (struct.t ApplyReply)) in
    let: ("0_ret", "1_ret") := marshal.ReadInt (![slice.T byteT] "enc") in
    struct.storeF ApplyReply "Err" "reply" "0_ret";;
    "enc" <-[slice.T byteT] "1_ret";;
    struct.storeF ApplyReply "Reply" "reply" (![slice.T byteT] "enc");;
    "reply".

Definition IncreaseCommitArgs: ty := uint64T.

Definition EncodeIncreaseCommitArgs: val :=
  rec: "EncodeIncreaseCommitArgs" "args" :=
    marshal.WriteInt slice.nil "args".

Definition DecodeIncreaseCommitArgs: val :=
  rec: "DecodeIncreaseCommitArgs" "args" :=
    let: ("a", <>) := marshal.ReadInt "args" in
    "a".

(* 1_statemachine.go *)

Definition StateMachine := struct.decl [
  "StartApply" :: (Op -> ((slice.T byteT) * (unitT -> unitT)%ht))%ht;
  "ApplyReadonly" :: (Op -> (uint64T * (slice.T byteT)))%ht;
  "SetStateAndUnseal" :: ((slice.T byteT) -> uint64T -> uint64T -> unitT)%ht;
  "GetStateAndSeal" :: (unitT -> (slice.T byteT))%ht
].

Definition SyncStateMachine := struct.decl [
  "Apply" :: (Op -> (slice.T byteT))%ht;
  "ApplyReadonly" :: (Op -> (uint64T * (slice.T byteT)))%ht;
  "SetStateAndUnseal" :: ((slice.T byteT) -> uint64T -> uint64T -> unitT)%ht;
  "GetStateAndSeal" :: (unitT -> (slice.T byteT))%ht
].

(* clerk.go *)

Definition Clerk := struct.decl [
  "cl" :: ptrT
].

Definition RPC_APPLYASBACKUP : expr := #0.

Definition RPC_SETSTATE : expr := #1.

Definition RPC_GETSTATE : expr := #2.

Definition RPC_BECOMEPRIMARY : expr := #3.

Definition RPC_PRIMARYAPPLY : expr := #4.

Definition RPC_ROPRIMARYAPPLY : expr := #6.

Definition RPC_INCREASECOMMIT : expr := #7.

Definition MakeClerk: val :=
  rec: "MakeClerk" "host" :=
    struct.new Clerk [
      "cl" ::= reconnectclient.MakeReconnectingClient "host"
    ].

Definition Clerk__ApplyAsBackup: val :=
  rec: "Clerk__ApplyAsBackup" "ck" "args" :=
    let: "reply" := ref (zero_val (slice.T byteT)) in
    let: "err" := reconnectclient.ReconnectingClient__Call (struct.loadF Clerk "cl" "ck") RPC_APPLYASBACKUP (EncodeApplyAsBackupArgs "args") "reply" #1000 in
    (if: "err" ≠ #0
    then e.Timeout
    else e.DecodeError (![slice.T byteT] "reply")).

Definition Clerk__SetState: val :=
  rec: "Clerk__SetState" "ck" "args" :=
    let: "reply" := ref (zero_val (slice.T byteT)) in
    let: "err" := reconnectclient.ReconnectingClient__Call (struct.loadF Clerk "cl" "ck") RPC_SETSTATE (EncodeSetStateArgs "args") "reply" #10000 in
    (if: "err" ≠ #0
    then e.Timeout
    else e.DecodeError (![slice.T byteT] "reply")).

Definition Clerk__GetState: val :=
  rec: "Clerk__GetState" "ck" "args" :=
    let: "reply" := ref (zero_val (slice.T byteT)) in
    let: "err" := reconnectclient.ReconnectingClient__Call (struct.loadF Clerk "cl" "ck") RPC_GETSTATE (EncodeGetStateArgs "args") "reply" #10000 in
    (if: "err" ≠ #0
    then
      struct.new GetStateReply [
        "Err" ::= e.Timeout
      ]
    else DecodeGetStateReply (![slice.T byteT] "reply")).

Definition Clerk__BecomePrimary: val :=
  rec: "Clerk__BecomePrimary" "ck" "args" :=
    let: "reply" := ref (zero_val (slice.T byteT)) in
    let: "err" := reconnectclient.ReconnectingClient__Call (struct.loadF Clerk "cl" "ck") RPC_BECOMEPRIMARY (EncodeBecomePrimaryArgs "args") "reply" #100 in
    (if: "err" ≠ #0
    then e.Timeout
    else e.DecodeError (![slice.T byteT] "reply")).

Definition Clerk__Apply: val :=
  rec: "Clerk__Apply" "ck" "op" :=
    let: "reply" := ref (zero_val (slice.T byteT)) in
    let: "err" := reconnectclient.ReconnectingClient__Call (struct.loadF Clerk "cl" "ck") RPC_PRIMARYAPPLY "op" "reply" #5000 in
    (if: "err" = #0
    then
      let: "r" := DecodeApplyReply (![slice.T byteT] "reply") in
      (struct.loadF ApplyReply "Err" "r", struct.loadF ApplyReply "Reply" "r")
    else (e.Timeout, slice.nil)).

Definition Clerk__ApplyRo: val :=
  rec: "Clerk__ApplyRo" "ck" "op" :=
    let: "reply" := ref (zero_val (slice.T byteT)) in
    let: "err" := reconnectclient.ReconnectingClient__Call (struct.loadF Clerk "cl" "ck") RPC_ROPRIMARYAPPLY "op" "reply" #1000 in
    (if: "err" = #0
    then
      let: "r" := DecodeApplyReply (![slice.T byteT] "reply") in
      (struct.loadF ApplyReply "Err" "r", struct.loadF ApplyReply "Reply" "r")
    else (e.Timeout, slice.nil)).

Definition Clerk__IncreaseCommitIndex: val :=
  rec: "Clerk__IncreaseCommitIndex" "ck" "n" :=
    reconnectclient.ReconnectingClient__Call (struct.loadF Clerk "cl" "ck") RPC_INCREASECOMMIT (EncodeIncreaseCommitArgs "n") (ref (zero_val (slice.T byteT))) #100.

(* server.go *)

Definition Server := struct.decl [
  "mu" :: ptrT;
  "epoch" :: uint64T;
  "sealed" :: boolT;
  "sm" :: ptrT;
  "nextIndex" :: uint64T;
  "canBecomePrimary" :: boolT;
  "isPrimary" :: boolT;
  "clerks" :: slice.T (slice.T ptrT);
  "isPrimary_cond" :: ptrT;
  "opAppliedConds" :: mapT ptrT;
  "leaseExpiration" :: uint64T;
  "leaseValid" :: boolT;
  "committedNextIndex" :: uint64T;
  "committedNextIndex_cond" :: ptrT;
  "confCk" :: ptrT
].

(* Applies the RO op immediately, but then waits for it to be committed before
   replying to client. *)
Definition Server__ApplyRoWaitForCommit: val :=
  rec: "Server__ApplyRoWaitForCommit" "s" "op" :=
    let: "reply" := struct.alloc ApplyReply (zero_val (struct.t ApplyReply)) in
    struct.storeF ApplyReply "Reply" "reply" slice.nil;;
    struct.storeF ApplyReply "Err" "reply" e.None;;
    lock.acquire (struct.loadF Server "mu" "s");;
    (if: (~ (struct.loadF Server "leaseValid" "s"))
    then
      lock.release (struct.loadF Server "mu" "s");;
      (* log.Printf("Lease invalid") *)
      struct.storeF ApplyReply "Err" "reply" e.LeaseExpired;;
      "reply"
    else
      (if: ((rand.RandomUint64 #()) `rem` #10000) = #0
      then
        (* log.Printf("Server nextIndex=%d commitIndex=%d", s.nextIndex, s.committedNextIndex) *)
        #()
      else #());;
      let: "lastModifiedIndex" := ref (zero_val uint64T) in
      let: ("0_ret", "1_ret") := (struct.loadF StateMachine "ApplyReadonly" (struct.loadF Server "sm" "s")) "op" in
      "lastModifiedIndex" <-[uint64T] "0_ret";;
      struct.storeF ApplyReply "Reply" "reply" "1_ret";;
      let: "epoch" := struct.loadF Server "epoch" "s" in
      let: (<>, "h") := grove_ffi.GetTimeRange #() in
      (if: (struct.loadF Server "leaseExpiration" "s") ≤ "h"
      then
        lock.release (struct.loadF Server "mu" "s");;
        (* log.Printf("Lease expired because %d < %d", s.leaseExpiration, h) *)
        struct.storeF ApplyReply "Err" "reply" e.LeaseExpired;;
        "reply"
      else
        Skip;;
        (for: (λ: <>, #true); (λ: <>, Skip) := λ: <>,
          (if: (struct.loadF Server "epoch" "s") ≠ "epoch"
          then
            struct.storeF ApplyReply "Err" "reply" e.Stale;;
            Break
          else
            (if: (![uint64T] "lastModifiedIndex") ≤ (struct.loadF Server "committedNextIndex" "s")
            then
              struct.storeF ApplyReply "Err" "reply" e.None;;
              Break
            else
              lock.condWait (struct.loadF Server "committedNextIndex_cond" "s");;
              Continue)));;
        lock.release (struct.loadF Server "mu" "s");;
        "reply")).

(* precondition:
   is_epoch_lb epoch ∗ committed_by epoch log ∗ is_pb_log_lb log *)
Definition Server__IncreaseCommitIndex: val :=
  rec: "Server__IncreaseCommitIndex" "s" "newCommittedNextIndex" :=
    lock.acquire (struct.loadF Server "mu" "s");;
    (if: ("newCommittedNextIndex" > (struct.loadF Server "committedNextIndex" "s")) && ("newCommittedNextIndex" ≤ (struct.loadF Server "nextIndex" "s"))
    then
      struct.storeF Server "committedNextIndex" "s" "newCommittedNextIndex";;
      lock.condBroadcast (struct.loadF Server "committedNextIndex_cond" "s")
    else #());;
    lock.release (struct.loadF Server "mu" "s");;
    #().

(* called on the primary server to apply a new operation. *)
Definition Server__Apply: val :=
  rec: "Server__Apply" "s" "op" :=
    let: "reply" := struct.alloc ApplyReply (zero_val (struct.t ApplyReply)) in
    struct.storeF ApplyReply "Reply" "reply" slice.nil;;
    lock.acquire (struct.loadF Server "mu" "s");;
    (if: (~ (struct.loadF Server "isPrimary" "s"))
    then
      lock.release (struct.loadF Server "mu" "s");;
      struct.storeF ApplyReply "Err" "reply" e.Stale;;
      "reply"
    else
      (if: struct.loadF Server "sealed" "s"
      then
        lock.release (struct.loadF Server "mu" "s");;
        struct.storeF ApplyReply "Err" "reply" e.Stale;;
        "reply"
      else
        let: ("ret", "waitForDurable") := (struct.loadF StateMachine "StartApply" (struct.loadF Server "sm" "s")) "op" in
        struct.storeF ApplyReply "Reply" "reply" "ret";;
        let: "opIndex" := struct.loadF Server "nextIndex" "s" in
        struct.storeF Server "nextIndex" "s" (std.SumAssumeNoOverflow (struct.loadF Server "nextIndex" "s") #1);;
        let: "nextIndex" := struct.loadF Server "nextIndex" "s" in
        let: "epoch" := struct.loadF Server "epoch" "s" in
        let: "clerks" := struct.loadF Server "clerks" "s" in
        lock.release (struct.loadF Server "mu" "s");;
        let: "wg" := waitgroup.New #() in
        let: "args" := struct.new ApplyAsBackupArgs [
          "epoch" ::= "epoch";
          "index" ::= "opIndex";
          "op" ::= "op"
        ] in
        let: "clerks_inner" := SliceGet (slice.T ptrT) "clerks" ((rand.RandomUint64 #()) `rem` (slice.len "clerks")) in
        let: "errs" := NewSlice e.Error (slice.len "clerks_inner") in
        ForSlice ptrT "i" "clerk" "clerks_inner"
          (let: "clerk" := "clerk" in
          let: "i" := "i" in
          waitgroup.Add "wg" #1;;
          Fork (Skip;;
                (for: (λ: <>, #true); (λ: <>, Skip) := λ: <>,
                  let: "err" := Clerk__ApplyAsBackup "clerk" "args" in
                  (if: ("err" = e.OutOfOrder) || ("err" = e.Timeout)
                  then Continue
                  else
                    SliceSet uint64T "errs" "i" "err";;
                    Break));;
                waitgroup.Done "wg"));;
        waitgroup.Wait "wg";;
        "waitForDurable" #();;
        let: "err" := ref_to uint64T e.None in
        let: "i" := ref_to uint64T #0 in
        Skip;;
        (for: (λ: <>, (![uint64T] "i") < (slice.len "clerks_inner")); (λ: <>, Skip) := λ: <>,
          let: "err2" := SliceGet uint64T "errs" (![uint64T] "i") in
          (if: "err2" ≠ e.None
          then "err" <-[uint64T] "err2"
          else #());;
          "i" <-[uint64T] ((![uint64T] "i") + #1);;
          Continue);;
        struct.storeF ApplyReply "Err" "reply" (![uint64T] "err");;
        (if: (![uint64T] "err") = e.None
        then Server__IncreaseCommitIndex "s" "nextIndex"
        else
          lock.acquire (struct.loadF Server "mu" "s");;
          (if: (struct.loadF Server "epoch" "s") = "epoch"
          then struct.storeF Server "isPrimary" "s" #false
          else #());;
          lock.release (struct.loadF Server "mu" "s"));;
        "reply")).

Definition Server__leaseRenewalThread: val :=
  rec: "Server__leaseRenewalThread" "s" :=
    let: "latestEpoch" := ref (zero_val uint64T) in
    Skip;;
    (for: (λ: <>, #true); (λ: <>, Skip) := λ: <>,
      let: ("leaseErr", "leaseExpiration") := configservice.Clerk__GetLease (struct.loadF Server "confCk" "s") (![uint64T] "latestEpoch") in
      lock.acquire (struct.loadF Server "mu" "s");;
      (if: ((struct.loadF Server "epoch" "s") = (![uint64T] "latestEpoch")) && ("leaseErr" = e.None)
      then
        struct.storeF Server "leaseExpiration" "s" "leaseExpiration";;
        struct.storeF Server "leaseValid" "s" #true;;
        lock.release (struct.loadF Server "mu" "s");;
        time.Sleep (#250 * #1000000);;
        Continue
      else
        (if: (![uint64T] "latestEpoch") ≠ (struct.loadF Server "epoch" "s")
        then
          "latestEpoch" <-[uint64T] (struct.loadF Server "epoch" "s");;
          lock.release (struct.loadF Server "mu" "s");;
          Continue
        else
          lock.release (struct.loadF Server "mu" "s");;
          time.Sleep (#50 * #1000000);;
          Continue)));;
    #().

Definition Server__sendIncreaseCommitThread: val :=
  rec: "Server__sendIncreaseCommitThread" "s" :=
    Skip;;
    (for: (λ: <>, #true); (λ: <>, Skip) := λ: <>,
      lock.acquire (struct.loadF Server "mu" "s");;
      Skip;;
      (for: (λ: <>, (~ (struct.loadF Server "isPrimary" "s")) || ((slice.len (SliceGet (slice.T ptrT) (struct.loadF Server "clerks" "s") #0)) = #0)); (λ: <>, Skip) := λ: <>,
        lock.condWait (struct.loadF Server "isPrimary_cond" "s");;
        Continue);;
      let: "newCommittedNextIndex" := struct.loadF Server "committedNextIndex" "s" in
      let: "clerks" := struct.loadF Server "clerks" "s" in
      lock.release (struct.loadF Server "mu" "s");;
      let: "clerks_inner" := SliceGet (slice.T ptrT) "clerks" ((rand.RandomUint64 #()) `rem` (slice.len "clerks")) in
      let: "wg" := waitgroup.New #() in
      ForSlice ptrT <> "clerk" "clerks_inner"
        (let: "clerk" := "clerk" in
        waitgroup.Add "wg" #1;;
        Fork (Skip;;
              (for: (λ: <>, #true); (λ: <>, Skip) := λ: <>,
                let: "err" := Clerk__IncreaseCommitIndex "clerk" "newCommittedNextIndex" in
                (if: "err" = e.None
                then Break
                else Continue));;
              waitgroup.Done "wg"));;
      waitgroup.Wait "wg";;
      time.Sleep #5000000;;
      Continue);;
    #().

(* requires that we've already at least entered this epoch
   returns true iff stale *)
Definition Server__isEpochStale: val :=
  rec: "Server__isEpochStale" "s" "epoch" :=
    (struct.loadF Server "epoch" "s") ≠ "epoch".

(* called on backup servers to apply an operation so it is replicated and
   can be considered committed by primary. *)
Definition Server__ApplyAsBackup: val :=
  rec: "Server__ApplyAsBackup" "s" "args" :=
    lock.acquire (struct.loadF Server "mu" "s");;
    Skip;;
    (for: (λ: <>, (((struct.loadF ApplyAsBackupArgs "index" "args") > (struct.loadF Server "nextIndex" "s")) && ((struct.loadF Server "epoch" "s") = (struct.loadF ApplyAsBackupArgs "epoch" "args"))) && (~ (struct.loadF Server "sealed" "s"))); (λ: <>, Skip) := λ: <>,
      let: ("cond", "ok") := MapGet (struct.loadF Server "opAppliedConds" "s") (struct.loadF ApplyAsBackupArgs "index" "args") in
      (if: (~ "ok")
      then
        let: "cond" := lock.newCond (struct.loadF Server "mu" "s") in
        MapInsert (struct.loadF Server "opAppliedConds" "s") (struct.loadF ApplyAsBackupArgs "index" "args") "cond";;
        Continue
      else
        lock.condWait "cond";;
        Continue));;
    (if: struct.loadF Server "sealed" "s"
    then
      lock.release (struct.loadF Server "mu" "s");;
      e.Stale
    else
      (if: Server__isEpochStale "s" (struct.loadF ApplyAsBackupArgs "epoch" "args")
      then
        lock.release (struct.loadF Server "mu" "s");;
        e.Stale
      else
        (if: (struct.loadF ApplyAsBackupArgs "index" "args") ≠ (struct.loadF Server "nextIndex" "s")
        then
          lock.release (struct.loadF Server "mu" "s");;
          e.OutOfOrder
        else
          let: (<>, "waitFn") := (struct.loadF StateMachine "StartApply" (struct.loadF Server "sm" "s")) (struct.loadF ApplyAsBackupArgs "op" "args") in
          struct.storeF Server "nextIndex" "s" ((struct.loadF Server "nextIndex" "s") + #1);;
          let: ("cond", "ok") := MapGet (struct.loadF Server "opAppliedConds" "s") (struct.loadF Server "nextIndex" "s") in
          (if: "ok"
          then
            lock.condSignal "cond";;
            MapDelete (struct.loadF Server "opAppliedConds" "s") (struct.loadF Server "nextIndex" "s")
          else #());;
          lock.release (struct.loadF Server "mu" "s");;
          "waitFn" #();;
          e.None))).

Definition Server__SetState: val :=
  rec: "Server__SetState" "s" "args" :=
    lock.acquire (struct.loadF Server "mu" "s");;
    (if: (struct.loadF Server "epoch" "s") > (struct.loadF SetStateArgs "Epoch" "args")
    then
      lock.release (struct.loadF Server "mu" "s");;
      e.Stale
    else
      (if: (struct.loadF Server "epoch" "s") = (struct.loadF SetStateArgs "Epoch" "args")
      then
        lock.release (struct.loadF Server "mu" "s");;
        e.None
      else
        (* log.Print("Entered new epoch") *)
        struct.storeF Server "isPrimary" "s" #false;;
        struct.storeF Server "canBecomePrimary" "s" #true;;
        struct.storeF Server "epoch" "s" (struct.loadF SetStateArgs "Epoch" "args");;
        struct.storeF Server "leaseValid" "s" #false;;
        struct.storeF Server "sealed" "s" #false;;
        struct.storeF Server "nextIndex" "s" (struct.loadF SetStateArgs "NextIndex" "args");;
        (struct.loadF StateMachine "SetStateAndUnseal" (struct.loadF Server "sm" "s")) (struct.loadF SetStateArgs "State" "args") (struct.loadF SetStateArgs "NextIndex" "args") (struct.loadF SetStateArgs "Epoch" "args");;
        MapIter (struct.loadF Server "opAppliedConds" "s") (λ: <> "cond",
          lock.condSignal "cond");;
        lock.condBroadcast (struct.loadF Server "committedNextIndex_cond" "s");;
        struct.storeF Server "opAppliedConds" "s" (NewMap uint64T ptrT #());;
        lock.release (struct.loadF Server "mu" "s");;
        Server__IncreaseCommitIndex "s" (struct.loadF SetStateArgs "CommittedNextIndex" "args");;
        e.None)).

(* XXX: probably should rename to GetStateAndSeal *)
Definition Server__GetState: val :=
  rec: "Server__GetState" "s" "args" :=
    lock.acquire (struct.loadF Server "mu" "s");;
    (if: (struct.loadF GetStateArgs "Epoch" "args") < (struct.loadF Server "epoch" "s")
    then
      lock.release (struct.loadF Server "mu" "s");;
      struct.new GetStateReply [
        "Err" ::= e.Stale;
        "State" ::= slice.nil
      ]
    else
      struct.storeF Server "sealed" "s" #true;;
      let: "ret" := (struct.loadF StateMachine "GetStateAndSeal" (struct.loadF Server "sm" "s")) #() in
      let: "nextIndex" := struct.loadF Server "nextIndex" "s" in
      let: "committedNextIndex" := struct.loadF Server "committedNextIndex" "s" in
      MapIter (struct.loadF Server "opAppliedConds" "s") (λ: <> "cond",
        lock.condSignal "cond");;
      struct.storeF Server "opAppliedConds" "s" (NewMap uint64T ptrT #());;
      lock.condBroadcast (struct.loadF Server "committedNextIndex_cond" "s");;
      lock.release (struct.loadF Server "mu" "s");;
      struct.new GetStateReply [
        "Err" ::= e.None;
        "State" ::= "ret";
        "NextIndex" ::= "nextIndex";
        "CommittedNextIndex" ::= "committedNextIndex"
      ]).

Definition Server__BecomePrimary: val :=
  rec: "Server__BecomePrimary" "s" "args" :=
    lock.acquire (struct.loadF Server "mu" "s");;
    (if: ((struct.loadF BecomePrimaryArgs "Epoch" "args") ≠ (struct.loadF Server "epoch" "s")) || (~ (struct.loadF Server "canBecomePrimary" "s"))
    then
      (* log.Printf("Wrong epoch in BecomePrimary request (in %d, got %d)", s.epoch, args.Epoch) *)
      lock.release (struct.loadF Server "mu" "s");;
      e.Stale
    else
      (* log.Println("Became Primary") *)
      struct.storeF Server "isPrimary" "s" #true;;
      lock.condSignal (struct.loadF Server "isPrimary_cond" "s");;
      struct.storeF Server "canBecomePrimary" "s" #false;;
      let: "numClerks" := #32 in
      struct.storeF Server "clerks" "s" (NewSlice (slice.T ptrT) "numClerks");;
      let: "j" := ref_to uint64T #0 in
      Skip;;
      (for: (λ: <>, (![uint64T] "j") < "numClerks"); (λ: <>, Skip) := λ: <>,
        let: "clerks" := NewSlice ptrT ((slice.len (struct.loadF BecomePrimaryArgs "Replicas" "args")) - #1) in
        let: "i" := ref_to uint64T #0 in
        Skip;;
        (for: (λ: <>, (![uint64T] "i") < (slice.len "clerks")); (λ: <>, Skip) := λ: <>,
          SliceSet ptrT "clerks" (![uint64T] "i") (MakeClerk (SliceGet uint64T (struct.loadF BecomePrimaryArgs "Replicas" "args") ((![uint64T] "i") + #1)));;
          "i" <-[uint64T] ((![uint64T] "i") + #1);;
          Continue);;
        SliceSet (slice.T ptrT) (struct.loadF Server "clerks" "s") (![uint64T] "j") "clerks";;
        "j" <-[uint64T] ((![uint64T] "j") + #1);;
        Continue);;
      lock.release (struct.loadF Server "mu" "s");;
      e.None).

Definition MakeServer: val :=
  rec: "MakeServer" "sm" "confHosts" "nextIndex" "epoch" "sealed" :=
    let: "s" := struct.alloc Server (zero_val (struct.t Server)) in
    struct.storeF Server "mu" "s" (lock.new #());;
    struct.storeF Server "epoch" "s" "epoch";;
    struct.storeF Server "sealed" "s" "sealed";;
    struct.storeF Server "sm" "s" "sm";;
    struct.storeF Server "nextIndex" "s" "nextIndex";;
    struct.storeF Server "isPrimary" "s" #false;;
    struct.storeF Server "canBecomePrimary" "s" #false;;
    struct.storeF Server "leaseValid" "s" #false;;
    struct.storeF Server "canBecomePrimary" "s" #false;;
    struct.storeF Server "opAppliedConds" "s" (NewMap uint64T ptrT #());;
    struct.storeF Server "confCk" "s" (configservice.MakeClerk "confHosts");;
    struct.storeF Server "committedNextIndex_cond" "s" (lock.newCond (struct.loadF Server "mu" "s"));;
    struct.storeF Server "isPrimary_cond" "s" (lock.newCond (struct.loadF Server "mu" "s"));;
    "s".

Definition Server__Serve: val :=
  rec: "Server__Serve" "s" "me" :=
    let: "handlers" := NewMap uint64T ((slice.T byteT) -> ptrT -> unitT)%ht #() in
    MapInsert "handlers" RPC_APPLYASBACKUP (λ: "args" "reply",
      "reply" <-[slice.T byteT] (e.EncodeError (Server__ApplyAsBackup "s" (DecodeApplyAsBackupArgs "args")));;
      #()
      );;
    MapInsert "handlers" RPC_SETSTATE (λ: "args" "reply",
      "reply" <-[slice.T byteT] (e.EncodeError (Server__SetState "s" (DecodeSetStateArgs "args")));;
      #()
      );;
    MapInsert "handlers" RPC_GETSTATE (λ: "args" "reply",
      "reply" <-[slice.T byteT] (EncodeGetStateReply (Server__GetState "s" (DecodeGetStateArgs "args")));;
      #()
      );;
    MapInsert "handlers" RPC_BECOMEPRIMARY (λ: "args" "reply",
      "reply" <-[slice.T byteT] (e.EncodeError (Server__BecomePrimary "s" (DecodeBecomePrimaryArgs "args")));;
      #()
      );;
    MapInsert "handlers" RPC_PRIMARYAPPLY (λ: "args" "reply",
      "reply" <-[slice.T byteT] (EncodeApplyReply (Server__Apply "s" "args"));;
      #()
      );;
    MapInsert "handlers" RPC_ROPRIMARYAPPLY (λ: "args" "reply",
      "reply" <-[slice.T byteT] (EncodeApplyReply (Server__ApplyRoWaitForCommit "s" "args"));;
      #()
      );;
    MapInsert "handlers" RPC_INCREASECOMMIT (λ: "args" "reply",
      Server__IncreaseCommitIndex "s" (DecodeIncreaseCommitArgs "args");;
      #()
      );;
    let: "rs" := urpc.MakeServer "handlers" in
    urpc.Server__Serve "rs" "me";;
    Fork (Server__leaseRenewalThread "s");;
    Fork (Server__sendIncreaseCommitThread "s");;
    #().
