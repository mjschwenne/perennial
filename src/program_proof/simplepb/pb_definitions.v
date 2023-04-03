From Perennial.base_logic Require Import lib.saved_prop.
From Perennial.program_proof Require Import grove_prelude.
From Goose.github_com.mit_pdos.gokv.simplepb Require Export pb.
From Perennial.program_proof.simplepb Require Export pb_protocol primary_protocol.
From Perennial.goose_lang.lib Require Import waitgroup.
From iris.base_logic Require Export lib.ghost_var mono_nat.
From iris.algebra Require Import dfrac_agree mono_list.
From Perennial.goose_lang Require Import crash_borrow.
From Perennial.program_proof.simplepb Require Import pb_marshal_proof fmlist_map.
From Perennial.program_proof Require Import marshal_stateless_proof.
From Perennial.program_proof.reconnectclient Require Import proof.
From RecordUpdate Require Import RecordSet.

(* State-machine record. An instance of Sm.t defines how to compute the reply
   for an op applied to some state and how to encode ops into bytes. *)
Module Sm.
Record t :=
  {
    OpType:Type ;
    OpType_EqDecision:EqDecision OpType;
    has_op_encoding : list u8 → OpType → Prop ;
    has_snap_encoding: list u8 → (list OpType) → Prop ;
    compute_reply : list OpType → OpType → list u8 ;
  }.
End Sm.

Section pb_global_definitions.

Context {pb_record:Sm.t}.
Notation OpType := (pb_record.(Sm.OpType)).
Notation has_op_encoding := (Sm.has_op_encoding pb_record).
Notation has_snap_encoding := (Sm.has_snap_encoding pb_record).
Notation compute_reply := (Sm.compute_reply pb_record).

(* opsfull has all the ghost ops (RO and RW) in it as well as the gname for the
   Q for that op. get_rwops returns the RW ops only with the gnames removed.
   Generalizing it to an arbitrary extra type A instead of gname
   specifically, because sometimes we want to use get_rwops on a list that has
   an iProp predicate instead of the gname (see is_inv). *)
Definition get_rwops {A} (opsfull:list (OpType * A)) : list OpType :=
  fst <$> opsfull.

Definition client_logR := mono_listR (leibnizO OpType).

Class pbG Σ := {
    (*
    pb_ghostG :> pb_ghostG (EntryType:=(OpType * (list OpType → iProp Σ))%type) Σ ;
     *)
    pb_ghostG :> pb_ghostG (EntryType:=(OpType * gname)) Σ ;
    pb_primaryG :> primary_ghostG (EntryType:=(OpType * gname)) Σ ;
    pb_savedG :> savedPredG Σ (list OpType);
    pb_urpcG :> urpcregG Σ ;
    pb_wgG :> waitgroupG Σ ; (* for apply proof *)
    pb_logG :> inG Σ client_logR;
    pb_apply_escrow_tok :> ghost_varG Σ unit ;
}.

Definition pbΣ :=
  #[pb_ghostΣ (EntryType:=(OpType * gname)); savedPredΣ (list OpType) ; urpcregΣ ; waitgroupΣ ;
    GFunctor (client_logR) ; ghost_varΣ unit].
Global Instance subG_pbΣ {Σ} : subG (pbΣ) Σ → (pbG Σ).
Proof. Admitted. (* solve_inG. Qed. *)

Context `{!gooseGlobalGS Σ}.
Context `{!pbG Σ}.

Definition own_log γ σ := own γ (●ML{#1/2} (σ : list (leibnizO OpType))).

(* RPC specs *)

Definition ApplyAsBackup_core_spec γp γ γsrv args opsfull op Q (Φ : u64 -> iProp Σ) : iProp Σ :=
  ("%Hσ_index" ∷ ⌜length (get_rwops opsfull) = (int.nat args.(ApplyAsBackupArgs.index) + 1)%nat⌝ ∗
   "%Hhas_encoding" ∷ ⌜has_op_encoding args.(ApplyAsBackupArgs.op) op⌝ ∗
   "%Hghost_op_σ" ∷ ⌜last opsfull = Some (op, Q)⌝ ∗
   "%Hno_overflow" ∷ ⌜int.nat args.(ApplyAsBackupArgs.index) < int.nat (word.add args.(ApplyAsBackupArgs.index) 1)⌝ ∗
   "#Hepoch_lb" ∷ is_epoch_lb γsrv args.(ApplyAsBackupArgs.epoch) ∗
   "#Hprop_lb" ∷ is_proposal_lb γ args.(ApplyAsBackupArgs.epoch) opsfull ∗
   "#Hprop_facts" ∷ is_proposal_facts γ args.(ApplyAsBackupArgs.epoch) opsfull ∗
   "#Hprim_facts" ∷ is_proposal_facts_prim γp args.(ApplyAsBackupArgs.epoch) opsfull ∗
   "HΨ" ∷ ((is_accepted_lb γsrv args.(ApplyAsBackupArgs.epoch) opsfull -∗ Φ (U64 0)) ∧
           (∀ (err:u64), ⌜err ≠ 0⌝ -∗ Φ err))
    )%I
.

Program Definition ApplyAsBackup_spec γp γ γsrv :=
  λ (encoded_args:list u8), λne (Φ : list u8 -d> iPropO Σ) ,
  (∃ args σ op Q,
    ⌜ApplyAsBackupArgs.has_encoding encoded_args args⌝ ∗
    ApplyAsBackup_core_spec γp γ γsrv args σ op Q (λ err, ∀ reply, ⌜reply = u64_le err⌝ -∗ Φ reply)
    )%I
.
Next Obligation.
  unfold ApplyAsBackup_core_spec.
  solve_proper.
Defined.

Definition SetState_core_spec γp γ γsrv args opsfull :=
  λ (Φ : u64 -> iPropO Σ) ,
  (
    ⌜has_snap_encoding args.(SetStateArgs.state) (get_rwops opsfull)⌝ ∗
    ⌜length (get_rwops opsfull) = int.nat args.(SetStateArgs.nextIndex)⌝ ∗
    is_proposal_lb γ args.(SetStateArgs.epoch) opsfull ∗
    is_proposal_facts γ args.(SetStateArgs.epoch) opsfull ∗
    is_proposal_facts_prim γp args.(SetStateArgs.epoch) opsfull ∗
    (
      (is_epoch_lb γsrv args.(SetStateArgs.epoch) -∗
       Φ 0) ∧
      (∀ err, ⌜err ≠ U64 0⌝ → Φ err))
    )%I
.

Program Definition SetState_spec γp γ γsrv :=
  λ (enc_args:list u8), λne (Φ : list u8 -d> iPropO Σ) ,
  (∃ args σ,
    ⌜SetStateArgs.has_encoding enc_args args⌝ ∗
    SetState_core_spec γp γ γsrv args σ (λ err, ∀ reply, ⌜reply = u64_le err⌝ -∗ Φ reply)
  )%I
.
Next Obligation.
  unfold SetState_core_spec.
  solve_proper.
Defined.

Definition GetState_core_spec γp γ γsrv (epoch:u64) ghost_epoch_lb :=
  λ (Φ : GetStateReply.C -> iPropO Σ) ,
  (
    (is_epoch_lb γsrv ghost_epoch_lb ∗
      (
      (∀ epochacc opsfull snap,
            ⌜int.nat ghost_epoch_lb ≤ int.nat epochacc⌝ -∗
            ⌜int.nat epochacc ≤ int.nat epoch⌝ -∗
            is_accepted_ro γsrv epochacc opsfull -∗
            is_proposal_facts γ epochacc opsfull -∗
            is_proposal_facts_prim γp epochacc opsfull -∗
            is_proposal_lb γ epochacc opsfull -∗
            ⌜has_snap_encoding snap (get_rwops opsfull)⌝ -∗
            ⌜length (get_rwops opsfull) = int.nat (U64 (length (get_rwops opsfull)))⌝ -∗
                 Φ (GetStateReply.mkC 0 (length (get_rwops opsfull)) snap)) ∧
      (∀ err, ⌜err ≠ U64 0⌝ → Φ (GetStateReply.mkC err 0 [])))
    )
    )%I
.

Program Definition GetState_spec γp γ γsrv :=
  λ (enc_args:list u8), λne (Φ : list u8 -d> iPropO Σ) ,
  (∃ args epoch_lb,
    ⌜GetStateArgs.has_encoding enc_args args⌝ ∗
    GetState_core_spec γp γ γsrv args.(GetStateArgs.epoch) epoch_lb (λ reply, ∀ enc_reply, ⌜GetStateReply.has_encoding enc_reply reply⌝ -∗ Φ enc_reply)
  )%I
.
Next Obligation.
  unfold GetState_core_spec.
  solve_proper.
Defined.

(* FIXME: don't want to carry the four gname records around everywhere *)
Definition BecomePrimary_core_spec γp γpsrv γ γsrv args σ backupγ (ρ:u64 -d> primary_system_names -d> primary_server_names -d> pb_system_names -d> pb_server_names -d> iPropO Σ) :=
  λ (Φ : u64 -> iPropO Σ) ,
  (
    is_epoch_lb γsrv args.(BecomePrimaryArgs.epoch) ∗
    is_epoch_config γ args.(BecomePrimaryArgs.epoch) (γsrv :: backupγ) ∗
    ([∗ list] host ; γsrv' ∈ args.(BecomePrimaryArgs.replicas) ; γsrv :: backupγ, (ρ host γp γpsrv γ γsrv') ∗ is_epoch_lb γsrv' args.(BecomePrimaryArgs.epoch)) ∗
    become_primary_escrow γp γpsrv args.(BecomePrimaryArgs.epoch) σ (own_primary_ghost γ γsrv args.(BecomePrimaryArgs.epoch) σ) ∗
    (∀ err, Φ err)
    )%I
.

Program Definition BecomePrimary_spec_pre γp γpsrv γ γsrv ρ :=
  λ (enc_args:list u8), λne (Φ : list u8 -d> iPropO Σ) ,
  (∃ args σ confγ,
    ⌜BecomePrimaryArgs.has_encoding enc_args args⌝ ∗
    BecomePrimary_core_spec γp γpsrv γ γsrv args σ confγ ρ (λ err, ∀ reply, ⌜reply = u64_le err⌝ -∗ Φ reply)
  )%I
.
Next Obligation.
  unfold BecomePrimary_core_spec.
  solve_proper.
Defined.

Definition appN := pbN .@ "app".
Definition escrowN := pbN .@ "escrow".

Definition own_ghost' γsys (opsfullQ : list (OpType * (list OpType → iProp Σ))) : iProp Σ :=
  ∃ ops_gnames: list (OpType * gname),
    own_ghost γsys ops_gnames ∗
    ⌜opsfullQ.*1 = ops_gnames.*1 ⌝ ∗
    [∗ list] k↦Φ;γ ∈ snd <$> opsfullQ; snd <$> ops_gnames, saved_pred_own γ DfracDiscarded Φ.

Definition is_inv γlog γsys :=
  inv appN (∃ opsfullQ,
      own_ghost' γsys opsfullQ ∗
      own_log γlog (get_rwops opsfullQ) ∗
      □(
        ∀ opsPre opsPrePre lastEnt,
        ⌜prefix opsPre opsfullQ⌝ -∗ ⌜opsPre = opsPrePre ++ [lastEnt]⌝ -∗
        (lastEnt.2 (get_rwops opsPrePre))
      )
      ).

Definition Apply_core_spec γ γlog op enc_op :=
  λ (Φ : ApplyReply.C -> iPropO Σ) ,
  (
  ⌜has_op_encoding enc_op op⌝ ∗
  is_inv γlog γ ∗
  □(|={⊤∖↑pbN,∅}=> ∃ σ, own_log γlog σ ∗ (own_log γlog (σ ++ [op]) ={∅,⊤∖↑pbN}=∗
            Φ (ApplyReply.mkC 0 (compute_reply σ op))
  )) ∗
  □(∀ (err:u64) ret, ⌜err ≠ 0⌝ -∗ Φ (ApplyReply.mkC err ret))
  )%I
.

Program Definition Apply_spec γ :=
  λ (enc_args:list u8), λne (Φ : list u8 -d> iPropO Σ) ,
  (∃ op γlog, Apply_core_spec γ γlog op enc_args
                      (λ reply, ∀ enc_reply, ⌜ApplyReply.has_encoding enc_reply reply⌝ -∗ Φ enc_reply)
  )%I
.
Next Obligation.
  unfold Apply_core_spec.
  solve_proper.
Defined.

Definition ApplyRo_core_spec γ γlog op enc_op :=
  λ (Φ : ApplyReply.C -> iPropO Σ) ,
  (
  ⌜has_op_encoding enc_op op⌝ ∗
  is_inv γlog γ ∗
  □(|={⊤∖↑pbN,∅}=> ∃ σ, own_log γlog σ ∗ (own_log γlog σ ={∅,⊤∖↑pbN}=∗
            Φ (ApplyReply.mkC 0 (compute_reply σ op))
  )) ∗
  □(∀ (err:u64) ret, ⌜err ≠ 0⌝ -∗ Φ (ApplyReply.mkC err ret))
  )%I
.

Program Definition ApplyRo_spec γ :=
  λ (enc_args:list u8), λne (Φ : list u8 -d> iPropO Σ) ,
  (∃ op γlog, ApplyRo_core_spec γ γlog op enc_args
                      (λ reply, ∀ enc_reply, ⌜ApplyReply.has_encoding enc_reply reply⌝ -∗ Φ enc_reply)
  )%I
.
Next Obligation.
  unfold ApplyRo_core_spec.
  solve_proper.
Defined.


Definition is_pb_host_pre ρ : (u64 -d> primary_system_names -d> primary_server_names -d> pb_system_names -d> pb_server_names -d> iPropO Σ) :=
  (λ host γp γpsrv γ γsrv,
  ∃ γrpc,
  handler_spec γrpc host (U64 0) (ApplyAsBackup_spec γp γ γsrv) ∗
  handler_spec γrpc host (U64 1) (SetState_spec γp γ γsrv) ∗
  handler_spec γrpc host (U64 2) (GetState_spec γp γ γsrv) ∗
  handler_spec γrpc host (U64 3) (BecomePrimary_spec_pre γp γpsrv γ γsrv ρ) ∗
  handler_spec γrpc host (U64 4) (Apply_spec γ) ∗
  handler_spec γrpc host (U64 6) (ApplyRo_spec γ) ∗
  handlers_dom γrpc {[ (U64 0) ; (U64 1) ; (U64 2) ; (U64 3) ; (U64 4) ; (U64 6) ]})%I
.

Instance is_pb_host_pre_contr : Contractive is_pb_host_pre.
Proof.
  intros n ?? Hρ. rewrite /is_pb_host_pre.
  intros ?????. f_equiv. intros ?.
  do 5 (f_contractive || f_equiv).
  rewrite /BecomePrimary_spec_pre /BecomePrimary_core_spec.
  intros args Φ. simpl. repeat f_equiv. apply Hρ.
Qed.

Definition is_pb_host_def :=
  fixpoint (is_pb_host_pre).
Definition is_pb_host_aux : seal (is_pb_host_def). by eexists. Qed.
Definition is_pb_host := is_pb_host_aux.(unseal).
Definition is_pb_host_eq : is_pb_host = is_pb_host_def := is_pb_host_aux.(seal_eq).

Definition BecomePrimary_spec γp γpsrv γ γsrv := BecomePrimary_spec_pre γp γpsrv γ γsrv is_pb_host.

Lemma is_pb_host_unfold host γp γpsrv γ γsrv:
  is_pb_host host γp γpsrv γ γsrv ⊣⊢ is_pb_host_pre (is_pb_host) host γp γpsrv γ γsrv
.
Proof.
  rewrite is_pb_host_eq. apply (fixpoint_unfold (is_pb_host_pre)).
Qed.

Global Instance is_pb_host_pers host γp γpsrv γ γsrv: Persistent (is_pb_host host γp γpsrv γ γsrv).
Proof.
  rewrite is_pb_host_unfold.
  apply _.
Qed.

(* End RPC specs *)

(* Encapsulates the protocol-level ghost resources of a replica server; this is
   suitable for exposing as part of interfaces for users of the library. For
   now, it's only part of the crash obligation. *)
(* should not be unfolded in proof *)
Definition own_Server_ghost_f γp γ γsrv epoch ops sealed : iProp Σ :=
  ∃ opsfull,
  "%Hre" ∷ ⌜ops = get_rwops opsfull⌝ ∗
  "#Hprim_facts" ∷ is_proposal_facts_prim γp epoch opsfull ∗
  "Hghost" ∷ (own_replica_ghost γ γsrv epoch opsfull sealed)
.

End pb_global_definitions.

Module server.
Record t {pb_record:Sm.t} :=
  mkC {
    epoch : u64 ;
    sealed : bool ;
    ops_full_eph: list (pb_record.(Sm.OpType) * gname) ;
    isPrimary : bool ;
    canBecomePrimary : bool ;

    (* read-only optimization-related *)
    committedNextIndex : u64 ;
  }.

Global Instance etaServer {pb_record:Sm.t} : Settable _ :=
  settable! (mkC pb_record) <epoch; sealed; ops_full_eph; isPrimary; canBecomePrimary; committedNextIndex>.
End server.

Section pb_local_definitions.
(* definitions that refer to a particular node *)

Context {pb_record:Sm.t}.
Notation OpType := (pb_record.(Sm.OpType)).
Notation has_op_encoding := (Sm.has_op_encoding pb_record).
Notation has_snap_encoding := (Sm.has_snap_encoding pb_record).
Notation compute_reply := (Sm.compute_reply pb_record).

Notation pbG := (pbG (pb_record:=pb_record)).
Notation "server.t" := (server.t (pb_record:=pb_record)).

Context `{!heapGS Σ}.
Context `{!pbG Σ}.

Definition is_Clerk (ck:loc) γ γsrv : iProp Σ :=
  ∃ (cl:loc) srv γp γpsrv, (* FIXME: *)
  "#Hcl" ∷ readonly (ck ↦[pb.Clerk :: "cl"] #cl) ∗
  "#Hcl_rpc"  ∷ is_ReconnectingClient cl srv ∗
  "#Hsrv" ∷ is_pb_host srv γp γpsrv γ γsrv
.

(* End clerk specs *)

(* Server-side definitions *)

Implicit Type (own_StateMachine: u64 → list OpType → bool → (u64 → list OpType → bool → iProp Σ) → iProp Σ).
(* StateMachine *)
Definition is_ApplyFn own_StateMachine (startApplyFn:val) (P:u64 → list (OpType) → bool → iProp Σ) : iProp Σ :=
  ∀ op_sl (epoch:u64) (σ:list OpType) (op_bytes:list u8) (op:OpType) Q,
  {{{
        ⌜has_op_encoding op_bytes op⌝ ∗
        readonly (is_slice_small op_sl byteT 1 op_bytes) ∗
        (* XXX: This is the weakest mask that the pb library is compatible with.
           By making the mask weak, we allow for more possible implementations
           of startApplyFn, so we give a stronger spec to the client. The chain
           of callbacks had made it confusing which way is weaker and which way
           stronger.
         *)
        (P epoch σ false ={↑pbN}=∗ P epoch (σ ++ [op]) false ∗ Q) ∗
        own_StateMachine epoch σ false P
  }}}
    startApplyFn (slice_val op_sl)
  {{{
        reply_sl q (waitFn:goose_lang.val),
        RET (slice_val reply_sl, waitFn);
        is_slice_small reply_sl byteT q (compute_reply σ op) ∗
        own_StateMachine epoch (σ ++ [op]) false P ∗
        (∀ Ψ, (Q -∗ Ψ #()) -∗ WP waitFn #() {{ Ψ }})
  }}}
.

Definition is_SetStateAndUnseal_fn own_StateMachine (set_state_fn:val) P : iProp Σ :=
  ∀ σ_prev (epoch_prev:u64) σ epoch (snap:list u8) snap_sl sealed Q,
  {{{
        ⌜ (length σ < 2 ^ 64)%Z ⌝ ∗
        ⌜has_snap_encoding snap σ⌝ ∗
        readonly (is_slice_small snap_sl byteT 1 snap) ∗
        (P epoch_prev σ_prev sealed ={↑pbN}=∗ P epoch σ false ∗ Q) ∗
        own_StateMachine epoch_prev σ_prev sealed P
  }}}
    set_state_fn (slice_val snap_sl) #(U64 (length σ)) #epoch
  {{{
        RET #();
        own_StateMachine epoch σ false P ∗
        Q
  }}}
.

Definition is_GetStateAndSeal_fn own_StateMachine (get_state_fn:val) P : iProp Σ :=
  ∀ σ epoch sealed Q,
  {{{
        own_StateMachine epoch σ sealed P ∗
        (P epoch σ sealed ={↑pbN}=∗ P epoch σ true ∗ Q)
  }}}
    get_state_fn #()
  {{{
        snap_sl snap,
        RET (slice_val snap_sl);
        readonly (is_slice_small snap_sl byteT 1 snap) ∗
        ⌜has_snap_encoding snap σ⌝ ∗
        own_StateMachine epoch σ true P ∗
        Q
  }}}
.

Definition is_ApplyReadonlyFn own_StateMachine (startApplyFn:val) (P:u64 → list (OpType) → bool → iProp Σ) : iProp Σ :=
  ∀ op_sl (epoch:u64) (σ:list OpType) (op_bytes:list u8) (op:OpType),
  {{{
        ⌜has_op_encoding op_bytes op⌝ ∗
        readonly (is_slice_small op_sl byteT 1 op_bytes) ∗
        own_StateMachine epoch σ false P
  }}}
    startApplyFn (slice_val op_sl)
  {{{
        reply_sl q,
        RET (slice_val reply_sl);
        is_slice_small reply_sl byteT q (compute_reply σ op) ∗
        own_StateMachine epoch σ false P
  }}}
.

Definition accessP_fact own_StateMachine P : iProp Σ :=
  □ (£ 1 -∗ (∀ Φ σ epoch sealed,
     (∀ σold sealedold E, P epoch σold sealedold ={E}=∗ P epoch σold sealedold ∗ Φ) -∗
  own_StateMachine epoch σ sealed P -∗ |NC={⊤}=>
  wpc_nval ⊤ (own_StateMachine epoch σ sealed P ∗ Φ)))
.

Definition is_StateMachine (sm:loc) own_StateMachine P : iProp Σ :=
  tc_opaque (
  ∃ (applyFn:val) (applyRoFn:val) (getFn:val) (setFn:val),
  "#Happly" ∷ readonly (sm ↦[pb.StateMachine :: "StartApply"] applyFn) ∗
  "#HapplySpec" ∷ is_ApplyFn own_StateMachine applyFn P ∗

  "#HsetState" ∷ readonly (sm ↦[pb.StateMachine :: "SetStateAndUnseal"] setFn) ∗
  "#HsetStateSpec" ∷ is_SetStateAndUnseal_fn own_StateMachine setFn P ∗

  "#HgetState" ∷ readonly (sm ↦[pb.StateMachine :: "GetStateAndSeal"] getFn) ∗
  "#HgetStateSpec" ∷ is_GetStateAndSeal_fn own_StateMachine getFn P ∗

  "#HapplyReadonly" ∷ readonly (sm ↦[pb.StateMachine :: "ApplyReadonly"] applyRoFn) ∗
  "#HapplyReadonlySpec" ∷ is_ApplyReadonlyFn own_StateMachine applyRoFn P ∗

  "#HaccP" ∷ accessP_fact own_StateMachine P)%I
.

Global Instance is_StateMachine_pers sm own_StateMachine P :
  Persistent (is_StateMachine sm own_StateMachine P).
Proof.
unfold is_StateMachine. unfold tc_opaque. apply _.
Qed.

Definition numClerks : nat := 32.

Notation get_rwops := (get_rwops (pb_record:=pb_record)).

(*
Definition is_full_ro_suffix {A:Type} r (l:list (OpType * A)) :=
  ∀ r',
  get_rwops r' = [] →
  suffix r' l →
  suffix r' r.

Lemma suffix_app_r {A} a (s l:list A) :
  length s > 0 →
  suffix s (l ++ [a]) →
  ∃ s', s = s' ++ [a] ∧ suffix s' l.
Proof.
Admitted.

(* FIXME: move these lemmas *)
Lemma is_full_ro_suffix_nil {A} l op a:
      is_full_ro_suffix (A:=A) [] (l ++ [(op, a)]).
Proof.
  intros r Hros Hsuffix.
  destruct (decide (length r = 0)).
  {
    apply nil_length_inv in e.
    subst.
    apply suffix_nil.
  }
  exfalso.
  apply suffix_app_r in Hsuffix; last lia.
  destruct Hsuffix as (? & H & _).
  subst.
  rewrite get_rwops_app /get_rwops /= in Hros.
  apply app_eq_nil in Hros.
  naive_solver.
Qed.

Lemma is_full_ro_suffix_app {A} r l op a :
      is_full_ro_suffix (A:=A) r l →
      is_full_ro_suffix (A:=A) (r ++ [(ro_op op, a)]) (l ++ [(ro_op op, a)]).
Proof.
  intros Hcontains.
  intros r' Hros Hsuffix'.
  destruct (decide (length r' = 0)).
  {
    apply nil_length_inv in e.
    subst.
    apply suffix_nil.
  }
  {
    apply suffix_app_r in Hsuffix'; last first.
    { lia. }
    destruct Hsuffix' as (r'' & Hr' & Hr''suffix).
    subst.
    apply suffix_app.
    apply Hcontains.
    { rewrite get_rwops_app in Hros.
      apply app_eq_nil in Hros.
      naive_solver. }
    done.
  }
Qed.

(* Situation in roapply proof:
   lcommit ≺ leph + [ro_op op]; i.e. lcommit ⪯ leph
   Same number of RW ops in lcommit and leph
   lcommit ends with 6 RO ops
   leph ends with 5 RO ops.
   Want to derive contradiction.
 *)
Lemma roapply_helper {A} r l r' (l':list (OpType * A)) :
  is_full_ro_suffix r l →
  is_full_ro_suffix r' l' →
  prefix l' l →
  (get_rwops l') = (get_rwops l) →
  r' `suffix_of` l' →
  get_rwops r' = [] →
  r' `prefix_of` r
.
Proof.
  intros Hcontains Hcontains' Hprefix' Hrws Hsuffix' Hros.
Admitted. *)

(* this is meant to be unfolded in the code proof *)
Definition is_Primary γ γsrv (s:server.t) clerks_sl : iProp Σ:=
  ∃ (clerkss:list Slice.t) (backups:list pb_server_names),
  "%Hclerkss_len" ∷ ⌜length clerkss = numClerks⌝ ∗
  "#Hconf" ∷ is_epoch_config γ s.(server.epoch) (γsrv :: backups) ∗
            (* FIXME: ptrT vs refT (struct.t Clerk) *)
  "#Hclerkss_sl" ∷ readonly (is_slice_small clerks_sl (slice.T ptrT) 1 clerkss) ∗
  "#Hclerkss_rpc" ∷ ([∗ list] clerks_sl ∈ clerkss,
                        ∃ clerks,
                        "#Hclerks_sl" ∷ readonly (is_slice_small clerks_sl ptrT 1 clerks) ∗
                        "%Hclerks_conf" ∷ ⌜length clerks = length backups⌝ ∗
                        "#Hclerks_rpc" ∷ ([∗ list] ck ; γsrv' ∈ clerks ; backups, is_Clerk ck γ γsrv' ∗ is_epoch_lb γsrv' s.(server.epoch))
                    )
.

(* this should never be unfolded in the proof of code *)
Definition own_Primary_ghost_f γp γpsrv γ γsrv (canBecomePrimary isPrimary:bool) epoch (committedNextIndex:u64) opsfull : iProp Σ:=
  tc_opaque (
            "Hprim_escrow" ∷ own_primary_escrow_ghost γp γpsrv canBecomePrimary epoch ∗
            "#Hprim_facts" ∷ is_proposal_facts_prim γp epoch opsfull  ∗
            "#Hs_prop_lb" ∷ is_proposal_lb γ epoch opsfull ∗

            "Hprim" ∷ if isPrimary then
              ∃ (ops_commit_full:list (OpType * gname)),
              "Hprim" ∷ own_primary_ghost γ γsrv epoch opsfull ∗

              (* committed witness for committed state *)
              "#Hcommit_lb" ∷ is_ghost_lb γ ops_commit_full ∗
              "#Hcommit_prop_lb" ∷ is_proposal_lb γ epoch ops_commit_full ∗
              "%HcommitLen" ∷ ⌜length (get_rwops ops_commit_full) = int.nat committedNextIndex⌝
            else
              True
      )%I
.

Definition no_overflow (x:nat) : Prop := int.nat (U64 x) = x.
Hint Unfold no_overflow : arith.

(* physical (volatile) state; meant to be unfolded in code proof *)
Definition own_Server (s:loc) (st:server.t) γp γ γsrv mu : iProp Σ :=
  ∃ own_StateMachine (sm:loc) clerks_sl
    (committedNextIndex_cond:loc) (opAppliedConds_loc:loc) (opAppliedConds:gmap u64 loc),
  (* non-persistent physical *)
  "Hepoch" ∷ s ↦[pb.Server :: "epoch"] #st.(server.epoch) ∗
  "HnextIndex" ∷ s ↦[pb.Server :: "nextIndex"] #(U64 (length (get_rwops st.(server.ops_full_eph)))) ∗
  "HisPrimary" ∷ s ↦[pb.Server :: "isPrimary"] #st.(server.isPrimary) ∗
  "HcanBecomePrimary" ∷ s ↦[pb.Server :: "canBecomePrimary"] #st.(server.canBecomePrimary) ∗
  "Hsealed" ∷ s ↦[pb.Server :: "sealed"] #st.(server.sealed) ∗
  "Hsm" ∷ s ↦[pb.Server :: "sm"] #sm ∗
  "Hclerks" ∷ s ↦[pb.Server :: "clerks"] (slice_val clerks_sl) ∗
  "HcommittedNextIndex" ∷ s ↦[pb.Server :: "committedNextIndex"] #st.(server.committedNextIndex) ∗
  "HcommittedNextIndex_cond" ∷ s ↦[pb.Server :: "committedNextIndex_cond"] #committedNextIndex_cond ∗
  (* backup sequencer *)
  "HopAppliedConds" ∷ s ↦[pb.Server :: "opAppliedConds"] #opAppliedConds_loc ∗
  "HopAppliedConds_map" ∷ is_map opAppliedConds_loc 1 opAppliedConds ∗

  (* ownership of the statemachine *)
  "Hstate" ∷ own_StateMachine st.(server.epoch) (get_rwops st.(server.ops_full_eph)) st.(server.sealed) (own_Server_ghost_f γp γ γsrv) ∗

  (* persistent physical state *)
  "#HopAppliedConds_conds" ∷ ([∗ map] i ↦ cond ∈ opAppliedConds, is_cond cond mu) ∗
  "#HcommittedNextRoIndex_is_cond" ∷ is_cond committedNextIndex_cond mu ∗

  (* witnesses for primary; the exclusive state is in own_Server_ghost *)
  "#Hprimary" ∷ (⌜st.(server.isPrimary) = false⌝ ∨ is_Primary γ γsrv st clerks_sl) ∗

  (* state-machine callback specs *)
  "#HisSm" ∷ is_StateMachine sm own_StateMachine (own_Server_ghost_f γp γ γsrv) ∗

  (* overflow *)
  "%HnextIndexNoOverflow" ∷ ⌜no_overflow (length (get_rwops (st.(server.ops_full_eph))))⌝
.

(* should not be unfolded in proof *)
Definition own_Server_ghost_eph_f (st:server.t) γp γpsrv γ γsrv: iProp Σ :=
  tc_opaque (
  let ops:=(get_rwops st.(server.ops_full_eph)) in
  "Hprimary" ∷ own_Primary_ghost_f γp γpsrv γ γsrv st.(server.canBecomePrimary) st.(server.isPrimary) st.(server.epoch) st.(server.committedNextIndex) st.(server.ops_full_eph) ∗
  (* epoch lower bound *)
  "#Hs_epoch_lb" ∷ is_epoch_lb γsrv st.(server.epoch)
  )%I
.

Definition mu_inv (s:loc) γp γpsrv γ γsrv mu: iProp Σ :=
  ∃ st,
  "Hvol" ∷ own_Server s st γp γ γsrv mu ∗
  "HghostEph" ∷ own_Server_ghost_eph_f st γp γpsrv γ γsrv
.

Definition is_Server (s:loc) γp γpsrv γ γsrv : iProp Σ :=
  ∃ (mu:val),
  "#Hmu" ∷ readonly (s ↦[pb.Server :: "mu"] mu) ∗
  "#HmuInv" ∷ is_lock pbN mu (mu_inv s γp γpsrv γ γsrv mu) ∗
  "#Hsys_inv" ∷ sys_inv γ.

Lemma wp_Server__isEpochStale {stk} (s:loc) (currEpoch epoch:u64) :
  {{{
        s ↦[pb.Server :: "epoch"] #currEpoch
  }}}
    pb.Server__isEpochStale #s #epoch @ stk
  {{{
        RET #(negb (bool_decide (int.Z epoch = int.Z currEpoch)));
        s ↦[pb.Server :: "epoch"] #currEpoch
  }}}
.
Proof.
  iIntros (Φ) "HcurrEpoch HΦ".
  wp_call.
  wp_loadField.
  wp_pures.
  iModIntro.
  iSpecialize ("HΦ" with "HcurrEpoch").
  iExactEq "HΦ".
  repeat f_equal.
  apply bool_decide_ext.
  naive_solver.
Qed.

End pb_local_definitions.
