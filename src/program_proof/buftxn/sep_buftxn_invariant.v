Import EqNotations.
From Perennial.Helpers Require Import Map.
From iris.base_logic.lib Require Import mnat.
From Perennial.algebra Require Import auth_map liftable liftable2 log_heap async.

From Goose.github_com.mit_pdos.goose_nfsd Require Import buftxn.
From Perennial.program_logic Require Export ncinv.
From Perennial.program_proof Require Import buf.buf_proof addr.addr_proof txn.txn_proof.
From Perennial.program_proof Require buftxn.buftxn_proof.
From Perennial.program_proof Require Import proof_prelude.
From Perennial.goose_lang.lib Require Import slice.typed_slice.
From Perennial.goose_lang.ffi Require Import disk_prelude.

(** * A more separation logic-friendly spec for buftxn

Overview of resources used here:

durable_mapsto_own - durable, exclusive
durable_mapsto - durable but missing modify_token
buftxn_maps_to - ephemeral

is_crash_lock (durable_mapsto_own) (durable_mapsto)
on crash: exchange durable_mapsto for durable_mapsto_own

lift: move durable_mapsto_own into transaction and get buftxn_maps_to and durable_mapsto is added to is_buftxn

is_buftxn P = is_buftxn_mem * is_buftxn_durable P

reads and writes need buftxn_maps_to and is_buftxn_mem

is_buftxn_durable P -* P (P is going to be durable_mapsto) (use this to frame out crash condition)

exchange own_last_frag γ for own_last_frag γ' ∗ modify_token γ' (in sep_buftxn layer)
exchange ephemeral_txn_val γ for ephemeral_txn_val γ' if the transaction id was preserved
 *)

(* mspec is a shorthand for referring to the old "map-based" spec, since we will
want to use similar names in this spec *)
Module mspec := buftxn.buftxn_proof.

(*
Theorem holds_at_map_ctx `{Countable0: Countable L} {V} `{!mapG Σ L V} (P: (L → V → iProp Σ) → iProp Σ)
        γ q mq d m :
  dom _ m = d →
  map_ctx γ q m -∗
  HoldsAt P (λ a v, ptsto γ a mq v) d -∗
  map_ctx γ q m ∗ ([∗ map] a↦v ∈ m, ptsto γ a mq v) ∗
                PredRestore P m.
Proof.
  iIntros (<-) "Hctx HP".
  iDestruct "HP" as (m') "(%Hdom & Hm & Hmapsto2)"; rewrite /named.
  iDestruct (map_valid_subset with "Hctx Hm") as %Hsubset.
  assert (m = m') by eauto using map_subset_dom_eq; subst m'.
  iFrame.
Qed.
*)

Theorem map_update_predicate `{!EqDecision L, !Countable L} {V} `{!mapG Σ L V}
        (P0 P: (L → V → iProp Σ) → iProp Σ) (γ: gname) mapsto2 d m :
  map_ctx γ 1 m -∗
  HoldsAt P0 (λ a v, ptsto_mut γ a 1 v) d -∗
  HoldsAt P mapsto2 d -∗
  |==> ∃ m', map_ctx γ 1 m' ∗ HoldsAt P (λ a v, ptsto_mut γ a 1 v ∗ mapsto2 a v) d.
Proof.
  iIntros "Hctx HP0 HP".
  iDestruct (HoldsAt_elim_big_sepM with "HP0") as (m0) "[%Hdom_m0 Hstable]".
  iDestruct "HP" as (m') "(%Hdom & HPm & HP)"; rewrite /named.
  iMod (map_update_map m' with "Hctx Hstable") as "[Hctx Hstable]".
  { congruence. }
  iModIntro.
  iExists _; iFrame.
  iDestruct (big_sepM_sep with "[$Hstable $HPm]") as "Hm".
  iExists _; iFrame.
  iPureIntro.
  congruence.
Qed.

(* TODO(tej): we don't get these definitions due to not importing the buftxn
proof; should fix that *)
Notation object := ({K & bufDataT K}).
Notation versioned_object := ({K & (bufDataT K * bufDataT K)%type}).

Definition objKind (obj: object): bufDataKind := projT1 obj.
Definition objData (obj: object): bufDataT (objKind obj) := projT2 obj.

Class buftxnG Σ :=
  { buftxn_buffer_inG :> mapG Σ addr object;
    buftxn_mspec_buftxnG :> mspec.buftxnG Σ;
    buftxn_asyncG :> asyncG Σ addr object;
  }.

Record buftxn_names {Σ} :=
  { buftxn_txn_names : @txn_names Σ;
    buftxn_async_name : async_gname;
  }.

Arguments buftxn_names Σ : assert, clear implicits.

Section goose_lang.
  Context `{!buftxnG Σ}.

  Context (N:namespace).

  Implicit Types (l: loc) (γ: buftxn_names Σ) (γtxn: gname).
  Implicit Types (obj: object).

  Definition txn_durable γ txn_id :=
    (* oof, this leaks all the abstractions *)
    mnat_own_lb γ.(buftxn_txn_names).(txn_walnames).(heapspec.wal_heap_durable_lb) txn_id.


  Definition txn_system_inv γ: iProp Σ :=
    ∃ (σs: async (gmap addr object)),
      "H◯async" ∷ ghost_var γ.(buftxn_txn_names).(txn_crashstates) (3/4) σs ∗
      "H●latest" ∷ async_ctx γ.(buftxn_async_name) 1 σs
  .

  (* this is for the entire txn manager, and relates it to some ghost state *)
  Definition is_txn_system γ : iProp Σ :=
    "Htxn_inv" ∷ ncinv N (txn_system_inv γ) ∗
    "His_txn" ∷ ncinv invN (is_txn_always γ.(buftxn_txn_names)).

  Lemma init_txn_system {E} l_txn γUnified dinit σs :
    is_txn l_txn γUnified dinit ∗ ghost_var γUnified.(txn_crashstates) (3/4) σs ={E}=∗
    ∃ γ, ⌜γ.(buftxn_txn_names) = γUnified⌝ ∗
         is_txn_system γ.
  Proof.
    iIntros "[#Htxn Hasync]".
    iMod (async_ctx_init σs) as (γasync) "H●async".
    set (γ:={|buftxn_txn_names := γUnified; buftxn_async_name := γasync; |}).
    iExists γ.
    iMod (ncinv_alloc N E (txn_system_inv γ) with "[-]") as "($&Hcfupd)".
    { iNext.
      iExists _; iFrame. }
    iModIntro.
    simpl.
    iSplit; first by auto.
    iNamed "Htxn"; iFrame "#".
  Qed.

  (* modify_token is an obligation from the buftxn_proof, which is how the txn
  invariant keeps track of exclusive ownership over an address. This proof has a
  more sophisticated notion of owning an address coming from the logical setup
  in [async.v], but we still have to track this token to be able to lift
  addresses into a transaction. *)
  Definition modify_token γ (a: addr) : iProp Σ :=
    ∃ obj, txn.invariant.mapsto_txn γ.(buftxn_txn_names) a obj.

  Global Instance modify_token_conflicting γ T :
    Conflicting (λ (l : addr) (_ : T), modify_token γ l).
  Proof.
    iIntros (a0 v0 a1 v1) "H0 H1".
    iDestruct "H0" as (o0) "H0".
    iDestruct "H1" as (o1) "H1".
    iApply (mspec.mapsto_txn_conflicting with "H0 H1").
  Qed.

  (* The basic statement of what is in the logical, committed disk of the
  transaction system.

  Has three components: the value starting from some txn i, a token giving
  exclusive ownership over transactions ≥ i, and a persistent witness that i is
  durable (so we don't crash to before this fact is relevant). The first two are
  grouped into [ephemeral_val_from]. *)
  Definition durable_mapsto γ (a: addr) obj: iProp Σ :=
    ∃ i, ephemeral_val_from γ.(buftxn_async_name) i a obj ∗
         txn_durable γ i.

  Definition durable_mapsto_own γ a obj: iProp Σ :=
    modify_token γ a ∗ durable_mapsto γ a obj.

  Global Instance durable_mapsto_own_discretizable γ a obj: Discretizable (durable_mapsto_own γ a obj).
  Proof. apply _. Qed.

  Definition is_buftxn_mem l γ dinit γtxn γdurable : iProp Σ :=
    ∃ (mT: gmap addr versioned_object) anydirty,
      "#Htxn_system" ∷ is_txn_system γ ∗
      "Hbuftxn" ∷ mspec.is_buftxn l mT γ.(buftxn_txn_names) dinit anydirty ∗
      "Htxn_ctx" ∷ map_ctx γtxn 1 (mspec.modified <$> mT) ∗
      "%Hanydirty" ∷ ⌜anydirty=false →
                      mspec.modified <$> mT = mspec.committed <$> mT⌝ ∗
      "Hdurable" ∷ map_ctx γdurable (1/2) (mspec.committed <$> mT)
  .

  Definition is_buftxn_durable γ γdurable (P0 : (_ -> _ -> iProp Σ) -> iProp Σ) : iProp Σ :=
    ∃ committed_mT,
      "Hdurable_frag" ∷ map_ctx γdurable (1/2) committed_mT ∗
      "Hold_vals" ∷ ([∗ map] a↦v ∈ committed_mT,
                     durable_mapsto γ a v) ∗
      "#HrestoreP0" ∷ □ (∀ mapsto,
                         ([∗ map] a↦v ∈ committed_mT,
                          mapsto a v) -∗
                         P0 mapsto)
  .

  Definition is_buftxn l γ dinit γtxn P0 : iProp Σ :=
    ∃ γdurable,
      "Hbuftxn_mem" ∷ is_buftxn_mem l γ dinit γtxn γdurable ∗
      "Hbuftxn_durable" ∷ is_buftxn_durable γ γdurable P0.

  Global Instance: Params (@is_buftxn) 4 := {}.

  Global Instance is_buftxn_durable_proper γ γdurable :
    Proper (pointwise_relation _ (⊣⊢) ==> (⊣⊢)) (is_buftxn_durable γ γdurable).
  Proof.
    intros P1 P2 Hequiv.
    rewrite /is_buftxn_durable.
    setoid_rewrite Hequiv.
    reflexivity.
  Qed.

  Global Instance is_buftxn_durable_mono γ γdurable :
    Proper (pointwise_relation _ (⊢) ==> (⊢)) (is_buftxn_durable γ γdurable).
  Proof.
    intros P1 P2 Hequiv.
    rewrite /is_buftxn_durable.
    setoid_rewrite Hequiv.
    reflexivity.
  Qed.

  Theorem is_buftxn_durable_wand γ γdurable P1 P2 :
    is_buftxn_durable γ γdurable P1 -∗
    □(∀ mapsto, P1 mapsto -∗ P2 mapsto) -∗
    is_buftxn_durable γ γdurable P2.
  Proof.
    iIntros "Htxn #Hwand".
    iNamed "Htxn".
    iExists _; iFrame "∗#%".
    iIntros (mapsto) "!> Hm".
    iApply "Hwand". iApply "HrestoreP0". iFrame.
  Qed.

  Global Instance is_buftxn_proper l γ dinit γtxn :
    Proper (pointwise_relation _ (⊣⊢) ==> (⊣⊢)) (is_buftxn l γ dinit γtxn).
  Proof.
    intros P1 P2 Hequiv.
    rewrite /is_buftxn.
    setoid_rewrite Hequiv.
    done.
  Qed.

  Global Instance is_buftxn_mono l γ dinit γtxn :
    Proper (pointwise_relation _ (⊢) ==> (⊢)) (is_buftxn l γ dinit γtxn).
  Proof.
    intros P1 P2 Hequiv.
    rewrite /is_buftxn.
    setoid_rewrite Hequiv.
    done.
  Qed.

  Theorem is_buftxn_wand l γ dinit γtxn P1 P2 :
    is_buftxn l γ dinit γtxn P1 -∗
    □(∀ mapsto, P1 mapsto -∗ P2 mapsto) -∗
    is_buftxn l γ dinit γtxn P2.
  Proof.
    iIntros "Htxn #Hwand".
    iNamed "Htxn".
    iDestruct (is_buftxn_durable_wand with "Hbuftxn_durable Hwand") as "Hbuftxn_durable".
    iExists _; iFrame.
  Qed.

  Theorem is_buftxn_durable_to_old_pred γ γdurable P0 :
    is_buftxn_durable γ γdurable P0 -∗ P0 (durable_mapsto γ).
  Proof.
    iNamed 1.
    iApply "HrestoreP0". iFrame.
  Qed.

  Theorem is_buftxn_to_old_pred l γ dinit γtxn P0 :
    is_buftxn l γ dinit γtxn P0 -∗ P0 (durable_mapsto_own γ).
  Proof.
    iNamed 1.
    iNamed "Hbuftxn_mem".
    iNamed "Hbuftxn_durable".
    iDestruct (map_ctx_agree with "Hdurable_frag Hdurable") as %->.
    iApply "HrestoreP0".
    iApply big_sepM_sep. iFrame.
    iDestruct (mspec.is_buftxn_to_committed_mapsto_txn with "Hbuftxn") as "Hmod".
    iApply (big_sepM_mono with "Hmod").
    iIntros (k x Hkx) "H".
    iExists _; iFrame.
  Qed.

  Definition buftxn_maps_to γtxn (a: addr) obj : iProp Σ :=
     ptsto_mut γtxn a 1 obj.

  (* TODO: prove this instance for ptsto_mut 1 *)
  Global Instance buftxn_maps_to_conflicting γtxn :
    Conflicting (buftxn_maps_to γtxn).
  Proof.
    rewrite /buftxn_maps_to.
    iIntros (????) "Ha1 Ha2".
    destruct (decide (a0 = a1)); subst; auto.
    iDestruct (ptsto_conflict with "Ha1 Ha2") as %[].
  Qed.

  Definition object_to_versioned (obj: object): versioned_object :=
    existT (objKind obj) (objData obj, objData obj).

  Lemma committed_to_versioned obj :
    mspec.committed (object_to_versioned obj) = obj.
  Proof. destruct obj; reflexivity. Qed.

  Lemma modified_to_versioned obj :
    mspec.modified (object_to_versioned obj) = obj.
  Proof. destruct obj; reflexivity. Qed.

  Lemma durable_mapsto_mapsto_txn_agree E γ a obj1 obj2 :
    ↑N ⊆ E →
    ↑invN ⊆ E →
    N ## invN →
    is_txn_system γ -∗
    durable_mapsto γ a obj1 -∗
    mapsto_txn γ.(buftxn_txn_names) a obj2 -∗
    |NC={E}=> ⌜obj1 = obj2⌝ ∗ durable_mapsto γ a obj1 ∗ mapsto_txn γ.(buftxn_txn_names) a obj2.
  Proof.
    iIntros (???) "#Hinv Ha_i Ha". iNamed "Hinv".
    iInv "His_txn" as ">Hinner1".
    iInv "Htxn_inv" as ">Hinner2".
    iAssert (⌜obj1 = obj2⌝)%I as %?; last first.
    { iFrame. auto. }
    iNamed "Hinner1".
    iClear "Hheapmatch Hcrashheapsmatch Hmetactx".
    iNamed "Hinner2".
    iDestruct (ghost_var_agree with "Hcrashstates [$]") as %->.
    iDestruct (mapsto_txn_cur with "Ha") as "[Ha _]".
    iDestruct "Ha_i" as (i) "[Ha_i _]".
    iDestruct (ephemeral_val_from_agree_latest with "H●latest Ha_i") as %Hlookup_obj.
    iDestruct (log_heap_valid_cur with "Hlogheapctx [$]") as %Hlookup_obj0.
    iPureIntro.
    congruence.
  Qed.

  Theorem is_buftxn_durable_not_in_map γ a obj γdurable P0 committed_mT :
    durable_mapsto γ a obj -∗
    is_buftxn_durable γ γdurable P0 -∗
    map_ctx γdurable (1 / 2) committed_mT -∗
    ⌜committed_mT !! a = None⌝.
  Proof.
    iIntros "Ha Hdur Hctx".
    destruct (committed_mT !! a) eqn:He; try eauto.
    iNamed "Hdur".
    iDestruct (map_ctx_agree with "Hctx Hdurable_frag") as %->.
    iDestruct (big_sepM_lookup with "Hold_vals") as "Ha2"; eauto.
    iDestruct "Ha" as (i) "[Ha _]".
    iDestruct "Ha2" as (i2) "[Ha2 _]".
    iDestruct (ephemeral_val_from_conflict with "Ha Ha2") as "H".
    done.
  Qed.

  Theorem lift_into_txn E l γ dinit γtxn P0 a obj :
    ↑N ⊆ E →
    ↑invN ⊆ E →
    N ## invN →
    is_buftxn l γ dinit γtxn P0 -∗
    durable_mapsto_own γ a obj
    -∗ |NC={E}=>
    buftxn_maps_to γtxn a obj ∗
    is_buftxn l γ dinit γtxn (λ mapsto, mapsto a obj ∗ P0 mapsto).
  Proof.
    iIntros (???) "Hctx [Ha Ha_i]".
    iNamed "Hctx".
    iNamed "Hbuftxn_mem".

    iDestruct "Ha" as (obj0) "Ha".

    iMod (durable_mapsto_mapsto_txn_agree with "[$] Ha_i Ha") as "(%Heq & Ha_i & Ha)";
      [ solve_ndisj.. | subst obj0 ].

    iDestruct (mspec.is_buftxn_not_in_map with "Hbuftxn Ha") as %Hnotin.
    assert ((mspec.modified <$> mT) !! a = None).
    { rewrite lookup_fmap Hnotin //. }
    assert ((mspec.committed <$> mT) !! a = None).
    { rewrite lookup_fmap Hnotin //. }
    iMod (mspec.BufTxn_lift_one _ _ _ _ _ _ E with "[$Ha $Hbuftxn]") as "Hbuftxn"; auto.
    iMod (map_alloc a obj with "Htxn_ctx") as "[Htxn_ctx Ha]"; eauto.

    iNamed "Hbuftxn_durable".
    iDestruct (map_ctx_agree with "Hdurable Hdurable_frag") as %<-.
    iCombine "Hdurable Hdurable_frag" as "Hdurable".
    iMod (map_alloc a obj with "Hdurable") as "[Hdurable _]"; eauto.
    iDestruct "Hdurable" as "[Hdurable Hdurable_frag]".

    iModIntro.
    iFrame "Ha".
    iExists _. iSplitR "Hdurable_frag Hold_vals Ha_i".
    {
      iExists (<[a:=object_to_versioned obj]> mT), anydirty.
      iFrame "Htxn_system".
      rewrite !fmap_insert committed_to_versioned modified_to_versioned.
      iFrame.
      iPureIntro. destruct anydirty; intuition congruence.
    }
    {
      iExists _. iFrame "Hdurable_frag".
      rewrite !big_sepM_insert //. iFrame.
      iModIntro.
      iIntros (mapsto) "H".
      iDestruct (big_sepM_insert with "H") as "[Ha H]"; eauto. iFrame.
      iApply "HrestoreP0"; iFrame.
    }
  Qed.

  Theorem lift_map_into_txn E l γ dinit γtxn P0 m :
    ↑invN ⊆ E →
    ↑N ⊆ E →
    N ## invN →
    is_buftxn l γ dinit γtxn P0 -∗
    ([∗ map] a↦v ∈ m, durable_mapsto_own γ a v) -∗ |NC={E}=>
    ([∗ map] a↦v ∈ m, buftxn_maps_to γtxn a v) ∗
                      is_buftxn l γ dinit γtxn
                        (λ mapsto,
                         ([∗ map] a↦v ∈ m, mapsto a v) ∗
                         P0 mapsto).
  Proof.
    iIntros (???) "Hctx Hm".
    iInduction m as [|a v m] "IH" using map_ind forall (P0).
    - setoid_rewrite big_sepM_empty.
      rewrite !left_id.
      setoid_rewrite (@left_id _ _ _ _ emp_sep).
      by iFrame.
    - rewrite !big_sepM_insert //.
      iDestruct "Hm" as "[[Ha_mod Ha_dur] Hm]".
      iAssert (durable_mapsto_own γ a v) with "[Ha_mod Ha_dur]" as "Ha".
      { iFrame. }
      iMod (lift_into_txn with "Hctx Ha") as "[Ha Hctx]"; [ solve_ndisj .. | ].
      iMod ("IH" with "Hctx Hm") as "[Hm Hctx]".
      iModIntro.
      iFrame.
      iApply (is_buftxn_mono with "Hctx"); auto.
      iIntros (mapsto) "(H0 & H1 & $)".
      iApply big_sepM_insert; eauto. iFrame.
  Qed.

  Lemma conflicting_exists {PROP:bi} (A L V : Type) (P : A → L → V → PROP) :
    (∀ x1 x2, ConflictsWith (P x1) (P x2)) →
    Conflicting (λ a v, ∃ x, P x a v)%I.
  Proof.
    intros.
    hnf; intros a1 v1 a2 v2.
    iIntros "H1 H2".
    iDestruct "H1" as (?) "H1".
    iDestruct "H2" as (?) "H2".
    iApply (H with "H1 H2").
  Qed.

  Theorem lift_liftable_into_txn E `{!Liftable P}
          l γ dinit γtxn P0 :
    ↑invN ⊆ E →
    ↑N ⊆ E →
    N ## invN →
    is_buftxn l γ dinit γtxn P0 -∗
    P (λ a v, durable_mapsto_own γ a v)
    -∗ |NC={E}=>
    P (buftxn_maps_to γtxn) ∗
    is_buftxn l γ dinit γtxn
      (λ mapsto,
       P mapsto ∗ P0 mapsto).
  Proof.
    iIntros (???) "Hctx HP".
    iDestruct (liftable_restore_elim with "HP") as (m) "[Hm #HP]".
    iMod (lift_map_into_txn with "Hctx Hm") as "[Hm Hctx]";
      [ solve_ndisj .. | ].
    iModIntro.
    iFrame.
    iSplitR "Hctx".
    - iApply "HP"; iFrame.
    - iApply (is_buftxn_wand with "Hctx").
      iIntros (mapsto) "!> [Hm $]".
      iApply "HP"; auto.
  Qed.

End goose_lang.