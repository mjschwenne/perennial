From Perennial.program_proof.rsm Require Import distx distx_txnlog distx_index distx_tuple.
From Goose.github_com.mit_pdos.rsm Require Import distx.
From Perennial.program_proof Require Import std_proof.

Section list.

  Lemma take_length_prefix {A} (l1 l2 : list A) :
    prefix l1 l2 ->
    take (length l1) l2 = l1.
  Proof. intros [l Happ]. by rewrite Happ take_app_length. Qed.

End list.

Section word.

  Lemma uint_nat_W64 (n : nat) :
    n < 2 ^ 64 ->
    uint.nat (W64 n) = n.
  Proof. intros H. word. Qed.

  Lemma uint_nat_word_add_S (x : u64) :
    uint.Z x < 2 ^ 64 - 1 ->
    (uint.nat (w64_instance.w64.(word.add) x (W64 1))) = S (uint.nat x).
  Proof. intros H. word. Qed.

End word.

Section list.

  Lemma not_elem_of_take {A} (l : list A) n x :
    NoDup l ->
    l !! n = Some x ->
    x ∉ take n l.
  Proof.
    intros Hnd Hx Htake.
    apply take_drop_middle in Hx.
    rewrite -Hx cons_middle NoDup_app in Hnd.
    destruct Hnd as (_ & Hnd & _).
    specialize (Hnd _ Htake).
    set_solver.
  Qed.

End list.

Section program.
  Context `{!heapGS Σ, !distx_ghostG Σ}.

  (*@ type Replica struct {                                                   @*)
  (*@     // Mutex                                                            @*)
  (*@     mu *sync.Mutex                                                      @*)
  (*@     // Replica ID.                                                      @*)
  (*@     rid uint64                                                          @*)
  (*@     // Replicated transaction log.                                      @*)
  (*@     log *TxnLog                                                         @*)
  (*@     //                                                                  @*)
  (*@     // Fields below are application states.                             @*)
  (*@     //                                                                  @*)
  (*@     // LSN up to which all commands have been applied.                  @*)
  (*@     lsna   uint64                                                       @*)
  (*@     // Preparation map.                                                 @*)
  (*@     prepm  map[uint64][]WriteEntry                                      @*)
  (*@     // Transaction status table; mapping from transaction timestamps to their @*)
  (*@     // commit/abort status.                                             @*)
  (*@     txntbl map[uint64]bool                                              @*)
  (*@     // Index.                                                           @*)
  (*@     idx    *Index                                                       @*)
  (*@     // Key-value map.                                                   @*)
  (*@     kvmap  map[string]*Tuple                                            @*)
  (*@ }                                                                       @*)
  Definition mergef_stm (pwrs : option dbmap) (coa : option bool) :=
    match pwrs, coa with
    | _, Some true => Some StCommitted
    | _, Some false => Some StAborted
    | Some m, None => Some (StPrepared m)
    | _, _ => None
    end.

  Definition merge_stm (prepm : gmap u64 dbmap) (txntbl : gmap u64 bool) :=
    merge mergef_stm prepm txntbl.

  (* Ideally one [kmap] would do the work, but we lost injectivity from u64 to
  nat when converting through Z. *)
  Definition absrel_stm
    (prepm : gmap u64 dbmap) (txntbl : gmap u64 bool) (stm : gmap nat txnst) :=
    (kmap Z.of_nat stm : gmap Z txnst) = kmap uint.Z (merge_stm prepm txntbl).

  Lemma absrel_stm_txntbl_present prepm txntbl stm ts b :
    txntbl !! ts = Some b ->
    absrel_stm prepm txntbl stm ->
    stm !! (uint.nat ts) = Some (if b : bool then StCommitted else StAborted).
  Proof.
    intros Htbl Habs.
    rewrite /absrel_stm map_eq_iff in Habs.
    specialize (Habs (uint.Z ts)).
    rewrite lookup_kmap lookup_merge Htbl in Habs.
    set st := if b then _ else _.
    replace (diag_None _ _ _) with (Some st) in Habs; last first.
    { by destruct (prepm !! ts), b. }
    rewrite lookup_kmap_Some in Habs.
    destruct Habs as (tsN & -> & Hcmt).
    by rewrite Nat2Z.id.
  Qed.

  Lemma absrel_stm_txntbl_absent_prepm_present prepm txntbl stm ts pwrs :
    txntbl !! ts = None ->
    prepm !! ts = Some pwrs ->
    absrel_stm prepm txntbl stm ->
    stm !! (uint.nat ts) = Some (StPrepared pwrs).
  Proof.
    intros Htbl Hpm Habs.
    rewrite /absrel_stm map_eq_iff in Habs.
    specialize (Habs (uint.Z ts)).
    rewrite lookup_kmap lookup_merge Htbl Hpm /= lookup_kmap_Some in Habs.
    destruct Habs as (tsN & -> & Hcmt).
    by rewrite Nat2Z.id.
  Qed.

  Lemma absrel_stm_both_absent prepm txntbl stm ts :
    txntbl !! ts = None ->
    prepm !! ts = None ->
    absrel_stm prepm txntbl stm ->
    stm !! (uint.nat ts) = None.
  Proof.
    intros Htbl Hpm Habs.
    rewrite /absrel_stm map_eq_iff in Habs.
    specialize (Habs (uint.Z ts)).
    rewrite lookup_kmap lookup_merge Htbl Hpm /= lookup_kmap_None in Habs.
    apply Habs.
    word.
  Qed.

  Lemma merge_stm_insert_txntbl prepm txntbl ts b :
    merge_stm prepm (<[ts := b]> txntbl) =
    <[ts := if b : bool then StCommitted else StAborted]> (merge_stm prepm txntbl).
  Proof.
    apply map_eq.
    intros tsx.
    rewrite lookup_merge.
    destruct (decide (tsx = ts)) as [-> | Hne]; last first.
    { do 2 (rewrite lookup_insert_ne; last done).
      by rewrite lookup_merge.
    }
    rewrite 2!lookup_insert.
    by destruct (prepm !! ts), b.
  Qed.

  Lemma merge_stm_delete_prepm prepm txntbl ts :
    is_Some (txntbl !! ts) ->
    merge_stm (delete ts prepm) txntbl = merge_stm prepm txntbl.
  Proof.
    intros Htxntbl.
    apply map_eq.
    intros tsx.
    rewrite 2!lookup_merge.
    destruct (decide (tsx = ts)) as [-> | Hne]; last first.
    { by rewrite lookup_delete_ne; last done. }
    destruct Htxntbl as [b Hb].
    rewrite Hb.
    by destruct (delete _ _ !! ts), (prepm !! ts).
  Qed.

  Lemma absrel_stm_inv_apply_commit {prepm txntbl stm} ts :
    absrel_stm prepm txntbl stm ->
    absrel_stm (delete ts prepm) (<[ts := true]> txntbl) (<[uint.nat ts := StCommitted]> stm).
  Proof.
    rewrite /absrel_stm.
    intros Habs.
    rewrite merge_stm_delete_prepm; last by rewrite lookup_insert.
    rewrite merge_stm_insert_txntbl 2!kmap_insert Habs.
    f_equal.
    word.
  Qed.

  Definition own_replica_tpls (rp : loc) (tpls : gmap dbkey dbtpl) : iProp Σ :=
    ∃ (idx : loc) (α : gname),
      "Hidx"   ∷ rp ↦[Replica :: "idx"] #idx ∗
      "Htpls"  ∷ ([∗ map] k ↦ t ∈ tpls, tuple_phys_half α k t.1 t.2) ∗
      "#HidxR" ∷ is_index idx α.

  Definition own_replica_state (rp : loc) (st : rpst) : iProp Σ :=
    ∃ (rid : u64) (prepm : loc) (txntbl : loc)
      (prepmS : gmap u64 Slice.t) (prepmM : gmap u64 dbmap) (txntblM : gmap u64 bool)
      (stm : gmap nat txnst) (tpls : gmap dbkey dbtpl),
      "Hrid"     ∷ rp ↦[Replica :: "rid"] #rid ∗
      "Hprepm"   ∷ rp ↦[Replica :: "prepm"] #prepm ∗
      "HprepmS"  ∷ own_map prepm (DfracOwn 1) prepmS ∗
      "HprepmM"  ∷ ([∗ map] s; m ∈ prepmS; prepmM, ∃ l, own_dbmap_in_slice s l m) ∗
      "Htxntbl"  ∷ rp ↦[Replica :: "txntbl"] #txntbl ∗
      "HtxntblM" ∷ own_map txntbl (DfracOwn 1) txntblM ∗
      "Htpls"    ∷ own_replica_tpls rp tpls ∗
      "%Hstmabs" ∷ ⌜absrel_stm prepmM txntblM stm⌝ ∗
      "%Habs"    ∷ ⌜st = State stm tpls⌝.

  (* Need this wrapper to prevent [wp_if_destruct] from eating the eq. *)
  Definition rsm_consistency log st := apply_cmds log = st.

  Definition own_replica_paxos
    (rp : loc) (st : rpst) (gid : groupid) (γ : distx_names) : iProp Σ :=
    ∃ (log : loc) (lsna : u64) (loga : dblog),
      "Hlog"    ∷ rp ↦[Replica :: "log"] #log ∗
      "Htxnlog" ∷ own_txnlog log gid γ ∗
      "Hlsna"   ∷ rp ↦[Replica :: "lsna"] #lsna ∗
      "#Hloga"  ∷ clog_lb γ gid loga ∗
      "%Hlen"   ∷ ⌜length loga = S (uint.nat lsna)⌝ ∗
      "%Hrsm"   ∷ ⌜rsm_consistency loga st⌝.

  Definition own_replica (rp : loc) (gid : groupid) (γ : distx_names) : iProp Σ :=
    ∃ (st : rpst),
      "Hst"  ∷ own_replica_state rp st ∗
      "Hlog" ∷ own_replica_paxos rp st gid γ.

  Definition is_replica (rp : loc) (gid : groupid) (γ : distx_names) : iProp Σ :=
    ∃ (mu : loc),
      "#Hmu"   ∷ readonly (rp ↦[Replica :: "mu"] #mu) ∗
      "#Hlock" ∷ is_lock distxN #mu (own_replica rp gid γ) ∗
      "%Hgid"  ∷ ⌜gid ∈ gids_all⌝.

  Theorem wp_Replica__Abort (rp : loc) (ts : u64) (gid : groupid) γ :
    txnres_abt γ (uint.nat ts) -∗
    is_replica rp gid γ -∗
    {{{ True }}}
      Replica__Abort #rp #ts
    {{{ (ok : bool), RET #ok; True }}}.
  Proof.
    (*@ func (rp *Replica) Abort(ts uint64) bool {                              @*)
    (*@     // Query the transaction table. Note that if there's an entry for @ts in @*)
    (*@     // @txntbl, then transaction @ts can only be aborted. That's why we're not @*)
    (*@     // even reading the value of entry.                                 @*)
    (*@     _, aborted := rp.txntbl[ts]                                         @*)
    (*@     if aborted {                                                        @*)
    (*@         return true                                                     @*)
    (*@     }                                                                   @*)
    (*@                                                                         @*)
    (*@     lsn, term := rp.log.SubmitAbort(ts)                                 @*)
    (*@     if lsn == 0 {                                                       @*)
    (*@         return false                                                    @*)
    (*@     }                                                                   @*)
    (*@                                                                         @*)
    (*@     safe := rp.log.WaitUntilSafe(lsn, term)                             @*)
    (*@     if !safe {                                                          @*)
    (*@         return false                                                    @*)
    (*@     }                                                                   @*)
    (*@                                                                         @*)
    (*@     // We don't really care about the result, since at this point (i.e., after @*)
    (*@     // at least one failed prepares), abort should never fail.          @*)
    (*@     return true                                                         @*)
    (*@ }                                                                       @*)
  Admitted.

  Theorem wp_Replica__Commit (rp : loc) (ts : u64) (wrs : dbmap) (gid : groupid) γ :
    txnres_cmt γ (uint.nat ts) wrs -∗
    is_replica rp gid γ -∗
    {{{ True }}}
      Replica__Commit #rp #ts
    {{{ (ok : bool), RET #ok; True }}}.
  Proof.
    (*@ func (rp *Replica) Commit(ts uint64) bool {                             @*)
    (*@     // Query the transaction table. Note that if there's an entry for @ts in @*)
    (*@     // @txntbl, then transaction @ts can only be committed. That's why we're not @*)
    (*@     // even reading the value of entry.                                 @*)
    (*@     _, committed := rp.txntbl[ts]                                       @*)
    (*@     if committed {                                                      @*)
    (*@         return true                                                     @*)
    (*@     }                                                                   @*)
    (*@                                                                         @*)
    (*@     lsn, term := rp.log.SubmitCommit(ts)                                @*)
    (*@     if lsn == 0 {                                                       @*)
    (*@         return false                                                    @*)
    (*@     }                                                                   @*)
    (*@                                                                         @*)
    (*@     safe := rp.log.WaitUntilSafe(lsn, term)                             @*)
    (*@     if !safe {                                                          @*)
    (*@         return false                                                    @*)
    (*@     }                                                                   @*)
    (*@                                                                         @*)
    (*@     // We don't really care about the result, since at this point (i.e., after @*)
    (*@     // all the successful prepares), commit should never fail.          @*)
    (*@     return true                                                         @*)
    (*@ }                                                                       @*)
  Admitted.

  Theorem wp_Replica__Prepare (rp : loc) (ts : u64) (wrs : Slice.t) (gid : groupid) γ :
    group_inv γ gid -∗
    is_replica rp gid γ -∗
    {{{ True }}}
      Replica__Prepare #rp #ts (to_val wrs)
    {{{ (status : txnst) (ok : bool), RET (#(txnst_to_u64 status), #ok);
        if ok then txnprep_prep γ gid (uint.nat ts) else txnprep_unprep γ gid (uint.nat ts)
    }}}.
  Proof.
    (*@ func (rp *Replica) Prepare(ts uint64, wrs []WriteEntry) (uint64, bool) { @*)
    (*@     // Return immediately if the transaction has already prepared, aborted, or @*)
    (*@     // committed. Note that this is more of an optimization to eliminate @*)
    (*@     // submitting unnecessary log entries than a correctness requirement. We'll @*)
    (*@     // check this in @applyPrepare anyway.                              @*)
    (*@     status := rp.queryTxnStatus(ts)                                     @*)
    (*@     if status != TXN_RUNNING {                                          @*)
    (*@         return status, true                                             @*)
    (*@     }                                                                   @*)
    (*@                                                                         @*)
    (*@     lsn, term := rp.log.SubmitPrepare(ts, wrs)                          @*)
    (*@     if lsn == 0 {                                                       @*)
    (*@         return 0, false                                                 @*)
    (*@     }                                                                   @*)
    (*@                                                                         @*)
    (*@     safe := rp.log.WaitUntilSafe(lsn, term)                             @*)
    (*@     if !safe {                                                          @*)
    (*@         return 0, false                                                 @*)
    (*@     }                                                                   @*)
    (*@                                                                         @*)
    (*@     rp.waitUntilExec(lsn)                                               @*)
    (*@                                                                         @*)
    (*@     // The command has been executed, get the prepared result. Note that here we @*)
    (*@     // can assume the transaction could not be running; we should indeed prove @*)
    (*@     // that to save some work from the users.                           @*)
    (*@     return rp.queryTxnStatus(ts), true                                  @*)
    (*@ }                                                                       @*)
  Admitted.

  Theorem wp_Replica__Read (rp : loc) (ts : u64) (key : string) (gid : groupid) γ :
    is_replica rp gid γ -∗
    {{{ True }}}
      Replica__Read #rp #ts #(LitString key)
    {{{ (v : dbval) (ok : bool), RET (dbval_to_val v, #ok);
        if ok then hist_repl_at γ key (uint.nat ts) v else True
    }}}.
  Proof.
    (*@ func (rp *Replica) Read(ts uint64, key string) (Value, bool) {          @*)
    (*@     // If the transaction has already terminated, this can only be an outdated @*)
    (*@     // read that no one actually cares.                                 @*)
    (*@     _, terminated := rp.txntbl[ts]                                      @*)
    (*@     if terminated {                                                     @*)
    (*@         return Value{}, false                                           @*)
    (*@     }                                                                   @*)
    (*@                                                                         @*)
    (*@     lsn, term := rp.log.SubmitRead(ts, key)                             @*)
    (*@     if lsn == 0 {                                                       @*)
    (*@         return Value{}, false                                           @*)
    (*@     }                                                                   @*)
    (*@                                                                         @*)
    (*@     safe := rp.log.WaitUntilSafe(lsn, term)                             @*)
    (*@     if !safe {                                                          @*)
    (*@         return Value{}, false                                           @*)
    (*@     }                                                                   @*)
    (*@                                                                         @*)
    (*@     rp.waitUntilExec(lsn)                                               @*)
    (*@                                                                         @*)
    (*@     tpl := rp.idx.GetTuple(key)                                         @*)
    (*@                                                                         @*)
    (*@     // Note that @ReadVersion is read-only; in particular, it does not modify @*)
    (*@     // @tslast. This follows the key RSM principle that requires the application @*)
    (*@     // state to be exactly equal to applying some prefix of the replicated log. @*)
    (*@     v, ok := tpl.ReadVersion(ts)                                        @*)
    (*@                                                                         @*)
    (*@     return v, ok                                                        @*)
    (*@ }                                                                       @*)
  Admitted.

  Theorem wp_Replica__validate
    (rp : loc) (ts : u64) (pwrsS : Slice.t) (pwrsL : list dbmod) (pwrs : dbmap) :
    {{{ own_dbmap_in_slice pwrsS pwrsL pwrs }}}
      Replica__validate #rp #ts (to_val pwrsS)
    {{{ (ok : bool), RET #ok; True }}}.
  Proof.
    iIntros (Φ) "[HpwrsS %Hpwrs] HΦ".
    wp_call.

    (*@ func (rp *Replica) validate(ts uint64, wrs []WriteEntry) bool {         @*)
    (*@     // Start acquiring locks for each key.                              @*)
    (*@     var pos uint64 = 0                                                  @*)
    (*@                                                                         @*)
    wp_apply (wp_ref_to); first by auto.
    iIntros (pos) "Hpos".
    wp_pures.

    (*@     for pos < uint64(len(wrs)) {                                        @*)
    (*@         ent := wrs[pos]                                                 @*)
    (*@         tpl := rp.idx.GetTuple(ent.k)                                   @*)
    (*@         ret := tpl.Own(ts)                                              @*)
    (*@         if !ret {                                                       @*)
    (*@             break                                                       @*)
    (*@         }                                                               @*)
    (*@         pos++                                                           @*)
    (*@     }                                                                   @*)
    (*@                                                                         @*)
    iDestruct (own_slice_sz with "HpwrsS") as %Hlen.
    iDestruct (own_slice_small_acc with "HpwrsS") as "[HpwrsS HpwrsC]".
    set P := (λ (b : bool), ∃ (n : u64),
      "HpwrsS" ∷ own_slice_small pwrsS (struct.t WriteEntry) (DfracOwn 1) pwrsL ∗
      "HposR"  ∷ pos ↦[uint64T] #n)%I.
    wp_apply (wp_forBreak_cond P with "[] [HpwrsS]").
    { (* loop body *)
      clear Φ. iIntros (Φ) "!> HP HΦ". iNamed "HP".
      wp_load.
      wp_apply (wp_slice_len).
      wp_if_destruct; last first.
      { (* exit from the loop condition *) iApply "HΦ". by iFrame. }
      wp_load.
      destruct (lookup_lt_is_Some_2 pwrsL (uint.nat n)) as [wr Hwr]; first word.
      wp_apply (wp_SliceGet with "[$HpwrsS]"); first done.
      iIntros "HpwrsL".
      wp_pures.
      admit.
    }

    (*@     // Release partially acquired locks.                                @*)
    (*@     if pos < uint64(len(wrs)) {                                         @*)
    (*@         ent := wrs[pos]                                                 @*)
    (*@         var i uint64 = 0                                                @*)
    (*@         for i < pos {                                                   @*)
    (*@             tpl := rp.idx.GetTuple(ent.k)                               @*)
    (*@             tpl.Free()                                                  @*)
    (*@             i++                                                         @*)
    (*@         }                                                               @*)
    (*@         return false                                                    @*)
    (*@     }                                                                   @*)
    (*@                                                                         @*)
    (*@     return true                                                         @*)
    (*@ }                                                                       @*)
  Admitted.

  Theorem wp_Replica__applyPrepare
    (rp : loc) (ts : u64) (pwrsS : Slice.t)
    (pwrsL : list dbmod) (pwrs : dbmap) (st : rpst) :
    {{{ own_replica_state rp st ∗ own_dbmap_in_slice pwrsS pwrsL pwrs }}}
      Replica__applyPrepare #rp #ts (to_val pwrsS)
    {{{ RET #(); own_replica_state rp (apply_cmd st (CmdPrep (uint.nat ts) pwrs)) }}}.
  Proof.
    (*@ func (rp *Replica) applyPrepare(ts uint64, wrs []WriteEntry) {          @*)
    (*@     // The transaction has already prepared, aborted, or committed. This must be @*)
    (*@     // an outdated PREPARE.                                             @*)
    (*@     status := rp.queryTxnStatus(ts)                                     @*)
    (*@     if status != TXN_RUNNING {                                          @*)
    (*@         return                                                          @*)
    (*@     }                                                                   @*)
    (*@                                                                         @*)
    (*@     // Validate timestamps.                                             @*)
    (*@     ok := rp.validate(ts, wrs)                                          @*)
    (*@     if !ok {                                                            @*)
    (*@         // If validation fails, we immediately abort the transaction for this @*)
    (*@         // shard (and other participant shards will do so as well when the @*)
    (*@         // coordinator explicitly request them to do so).               @*)
    (*@         //                                                              @*)
    (*@         // Right now we're not allowing retry. See design doc on ``handling @*)
    (*@         // failed preparation''.                                        @*)
    (*@         rp.txntbl[ts] = false                                           @*)
    (*@         return                                                          @*)
    (*@     }                                                                   @*)
    (*@                                                                         @*)
    (*@     rp.prepm[ts] = wrs                                                  @*)
    (*@ }                                                                       @*)
  Admitted.

  Theorem wp_Replica__multiwrite
    (rp : loc) (ts : u64) (pwrsS : Slice.t)
    (pwrsL : list dbmod) (pwrs : dbmap) (tpls : gmap dbkey dbtpl) :
    {{{ own_dbmap_in_slice pwrsS pwrsL pwrs ∗ own_replica_tpls rp tpls }}}
      Replica__multiwrite #rp #ts (to_val pwrsS)
    {{{ RET #(); own_replica_tpls rp (multiwrite (uint.nat ts) pwrs tpls) }}}.
  Proof.
    iIntros (Φ) "[[HpwrsS %Hpwrs] Htpls] HΦ".
    wp_call.

    (*@ func (rp *Replica) multiwrite(ts uint64, pwrs []WriteEntry) {           @*)
    (*@     for _, ent := range pwrs {                                          @*)
    (*@         key := ent.k                                                    @*)
    (*@         value := ent.v                                                  @*)
    (*@         tpl := rp.idx.GetTuple(key)                                     @*)
    (*@         if value.b {                                                    @*)
    (*@             tpl.AppendVersion(ts, value.s)                              @*)
    (*@         } else {                                                        @*)
    (*@             tpl.KillVersion(ts)                                         @*)
    (*@         }                                                               @*)
    (*@         tpl.Free()                                                      @*)
    (*@     }                                                                   @*)
    (*@ }                                                                       @*)
    iDestruct (own_slice_sz with "HpwrsS") as %HpwrsLen.
    iDestruct (own_slice_to_small with "HpwrsS") as "HpwrsS".
    set P := (λ (i : u64),
                let pwrs' := list_to_map (take (uint.nat i) pwrsL) in
                own_replica_tpls rp (multiwrite (uint.nat ts) pwrs' tpls))%I.
    wp_apply (wp_forSlice P with "[] [$HpwrsS Htpls]"); last first; first 1 last.
    { (* Loop entry. *)
      subst P. simpl.
      replace (uint.nat (W64 _)) with O by word.
      rewrite take_0 list_to_map_nil.
      admit.
    }
    { (* Loop body. *)
      clear Φ.
      iIntros (i [k v]) "!>".
      iIntros (Φ) "(HP & %Hbound & %Hi) HΦ".
      subst P. simpl. iNamed "HP".
      wp_pures.
      wp_loadField.
      (* TODO: should have in-bound precondition. *)
      wp_apply (wp_Index__GetTuple with "HidxR").
      iIntros (tpl) "#HtplR".
      wp_pures.
      (* Obtain proof that the current key [k] has not been written. *)
      pose proof (NoDup_fst_map_to_list pwrs) as Hnd.
      rewrite Hpwrs in Hnd.
      pose proof (list_lookup_fmap fst pwrsL (uint.nat i)) as Hk.
      rewrite Hi /= in Hk.
      pose proof (not_elem_of_take _ _ _ Hnd Hk) as Htake.
      rewrite -fmap_take in Htake.
      apply not_elem_of_list_to_map_1 in Htake as Hnone.
      (* Adjust the goal. *)
      rewrite uint_nat_word_add_S; last by word.
      rewrite (take_S_r _ _ _ Hi) list_to_map_snoc; last done.
      set pwrs' := (list_to_map _) in Hnone *.
      (* Take the physical tuple out. *)
      assert (∃ t, tpls !! k = Some t) as [t Ht] by admit.
      rewrite big_sepM_delete; last by rewrite multiwrite_unmodified.
      iDestruct "Htpls" as "[Htpl Htpls]".
      destruct v as [s |]; wp_pures.
      { (* Case: [@AppendVersion]. *)
        (* Take the physical tuple out. *)
        (* TODO: should have length check. *)
        wp_apply (wp_Tuple__AppendVersion with "HtplR Htpl").
        iIntros "Htpl".
        wp_pures.
        wp_apply (wp_Tuple__Free with "HtplR Htpl").
        iIntros "Htpl".
        (* Put the physical tuple back. *)
        set h := last_extend _ _ ++ _.
        change h with (h, O).1. change t.2 with (h, O).2.
        iCombine "Htpl Htpls" as "Htpls".
        rewrite -big_sepM_insert_delete /multiwrite.
        erewrite insert_merge_l; last by rewrite Ht /=.
        iApply "HΦ".
        by iFrame "∗ #".
      }
      { (* Case: [@AKillVersion]. *)
        (* Take the physical tuple out. *)
        (* TODO: should have length check. *)
        wp_apply (wp_Tuple__KillVersion with "HtplR Htpl").
        iIntros "Htpl".
        wp_pures.
        wp_apply (wp_Tuple__Free with "HtplR Htpl").
        iIntros "Htpl".
        (* Put the physical tuple back. *)
        set h := last_extend _ _ ++ _.
        change h with (h, O).1. change t.2 with (h, O).2.
        iCombine "Htpl Htpls" as "Htpls".
        rewrite -big_sepM_insert_delete /multiwrite.
        erewrite insert_merge_l; last by rewrite Ht /=.
        iApply "HΦ".
        by iFrame "∗ #".
      }
    }
    iIntros "[HP _]". subst P. simpl.
    wp_pures.
    rewrite -HpwrsLen firstn_all -Hpwrs list_to_map_to_list.
    by iApply "HΦ".
  Admitted.

  Theorem wp_Replica__applyCommit (rp : loc) (ts : u64) (st : rpst) :
    let st' := apply_cmd st (CmdCmt (uint.nat ts)) in
    not_stuck st' ->
    {{{ own_replica_state rp st }}}
      Replica__applyCommit #rp #ts
    {{{ RET #(); own_replica_state rp st' }}}.
  Proof.
    iIntros (st' Hns Φ) "Hst HΦ". subst st'.
    wp_call.

    (*@ func (rp *Replica) applyCommit(ts uint64) {                             @*)
    (*@     // Query the transaction table. Note that if there's an entry for @ts in @*)
    (*@     // @txntbl, then transaction @ts can only be committed. That's why we're not @*)
    (*@     // even reading the value of entry.                                 @*)
    (*@     _, committed := rp.txntbl[ts]                                       @*)
    (*@                                                                         @*)
    iNamed "Hst".
    wp_loadField.
    wp_apply (wp_MapGet with "HtxntblM").
    iIntros (b ok) "[%Htxntbl HtxntblM]".
    wp_pures. subst st.

    (*@     if committed {                                                      @*)
    (*@         return                                                          @*)
    (*@     }                                                                   @*)
    (*@                                                                         @*)
    wp_if_destruct.
    { (* Txn [ts] has committed or aborted. *)
      apply map_get_true in Htxntbl.
      (* Prove that [ts] must have committed. *)
      assert (stm !! (uint.nat ts) = Some StCommitted) as Hcmt.
      { pose proof (absrel_stm_txntbl_present _ _ _ _ _ Htxntbl Hstmabs) as Hstm.
        by destruct b; [| rewrite /= Hstm in Hns].
      }
      iApply "HΦ".
      iFrame "∗ %".
      iPureIntro.
      by rewrite /= Hcmt.
    }
    clear Heqb0 ok.

    (*@     // We'll need an invariant to establish that if a transaction has prepared @*)
    (*@     // but not terminated, then @prepm[ts] has something.               @*)
    (*@     pwrs := rp.prepm[ts]                                                @*)
    (*@                                                                         @*)
    wp_loadField.
    wp_apply (wp_MapGet with "HprepmS").
    iIntros (pwrsS ok) "[%Hprepm HprepmS]".
    wp_pures.
    (* Obtain [dom prepmS = dom prepmM] needed later. *)
    iDestruct (big_sepM2_dom with "HprepmM") as %Hdom.
    apply map_get_false in Htxntbl as [Htxntbl _].
    (* Prove that [ts] must have prepared. *)
    destruct ok; last first.
    { apply map_get_false in Hprepm as [Hprepm _].
      rewrite -not_elem_of_dom Hdom not_elem_of_dom in Hprepm.
      pose proof (absrel_stm_both_absent _ _ _ _ Htxntbl Hprepm Hstmabs) as Hstm.
      by rewrite /= Hstm in Hns.
    }
    apply map_get_true in Hprepm.
    assert (∃ pwrs, prepmM !! ts = Some pwrs) as [pwrs Hpwrs].
    { apply elem_of_dom_2 in Hprepm.
      rewrite Hdom elem_of_dom in Hprepm.
      destruct Hprepm as [pwrs Hpwrs].
      by exists pwrs.
    }
    pose proof (absrel_stm_txntbl_absent_prepm_present _ _ _ _ _ Htxntbl Hpwrs Hstmabs) as Hstm.

    (*@     rp.multiwrite(ts, pwrs)                                             @*)
    (*@                                                                         @*)
    (* Take ownership of the prepare-map slice out. *)
    iDestruct (big_sepM2_delete with "HprepmM") as "[[%pwsL HpwrsS] HprepmM]"; [done | done |].
    wp_apply (wp_Replica__multiwrite with "[$HpwrsS $Htpls]").
    iIntros "Htpls".
    wp_pures.

    (*@     delete(rp.prepm, ts)                                                @*)
    (*@                                                                         @*)
    wp_loadField.
    wp_apply (wp_MapDelete with "HprepmS").
    iIntros "HprepmS".
    wp_pures.

    (*@     rp.txntbl[ts] = true                                                @*)
    (*@ }                                                                       @*)
    wp_loadField.
    wp_apply (wp_MapInsert with "HtxntblM"); first done.
    iIntros "HtxntblM".
    wp_pures.
    (* Re-establish replica abstraction relation [Habs]. *)
    pose proof (absrel_stm_inv_apply_commit ts Hstmabs) as Hstmabs'.
    iApply "HΦ".
    rewrite /= Hstm.
    by iFrame "∗ # %".
  Qed.

  Theorem wp_Replica__apply (rp : loc) (cmd : command) (pwrsS : Slice.t) (st : rpst) :
    let st' := apply_cmd st cmd in
    valid_ts_of_command cmd ->
    not_stuck st' ->
    {{{ own_replica_state rp st ∗ own_pwrs_slice pwrsS cmd }}}
      Replica__apply #rp (command_to_val pwrsS cmd)
    {{{ RET #(); own_replica_state rp st' }}}.
  Proof.
    (*@ func (rp *Replica) apply(cmd Cmd) {                                     @*)
    (*@     if cmd.kind == 0 {                                                  @*)
    (*@         rp.applyRead(cmd.ts, cmd.key)                                   @*)
    (*@     } else if cmd.kind == 1 {                                           @*)
    (*@         rp.applyPrepare(cmd.ts, cmd.wrs)                                @*)
    (*@     } else if cmd.kind == 2 {                                           @*)
    (*@         rp.applyCommit(cmd.ts)                                          @*)
    (*@     } else {                                                            @*)
    (*@         rp.applyAbort(cmd.ts)                                           @*)
    (*@     }                                                                   @*)
    (*@ }                                                                       @*)
    iIntros (st' Hts Hns Φ) "[Hst HpwrsS] HΦ".
    wp_call.
    destruct cmd eqn:Hcmd; simpl; wp_pures.
    { (* Case: Read. *)
      admit.
    }
    { (* Case: Prepare. *)
      iDestruct "HpwrsS" as (pwrsL) "HpwrsS".
      admit.
    }
    { (* Case: Commit. *)
      rewrite /valid_ts_of_command /valid_ts in Hts.
      wp_apply (wp_Replica__applyCommit with "Hst").
      { by rewrite uint_nat_W64; last word. }
      rewrite uint_nat_W64; last word.
      iIntros "Hst".
      wp_pures.
      iApply "HΦ".
      by iFrame.
    }
    { (* Case: Abort. *)
      admit.
    }
  Admitted.

  Theorem wp_Replica__Start (rp : loc) (gid : groupid) γ :
    know_distx_inv γ -∗ 
    is_replica rp gid γ -∗
    {{{ True }}}
      Replica__Start #rp
    {{{ RET #(); True }}}.
  Proof.
    iIntros "#Hinv #Hrp" (Φ) "!> _ HΦ".
    wp_call.

    (*@ func (rp *Replica) Start() {                                            @*)
    (*@     rp.mu.Lock()                                                        @*)
    (*@                                                                         @*)
    iNamed "Hrp".
    wp_loadField.
    wp_apply (acquire_spec with "Hlock").
    iIntros "[Hlocked Hrp]".
    wp_pures.

    (*@     for {                                                               @*)
    (*@         lsn := std.SumAssumeNoOverflow(rp.lsna, 1)                      @*)
    (*@         // TODO: a more efficient interface would return multiple safe commands @*)
    (*@         // at once (so as to reduce the frequency of acquiring Paxos mutex). @*)
    (*@                                                                         @*)
    set P := (λ b : bool, own_replica rp gid γ ∗ locked #mu)%I.
    wp_apply (wp_forBreak P with "[] [$Hrp $Hlocked]"); last first.
    { (* Get out of an infinite loop. *) iIntros "Hrp". wp_pures. by iApply "HΦ". }
    clear Φ. iIntros "!>" (Φ) "[Hrp Hlocked] HΦ".
    iNamed "Hrp". iNamed "Hlog".
    wp_call. wp_loadField.
    wp_apply wp_SumAssumeNoOverflow.
    iIntros (Hnoof).

    (*@         // Ghost action: Learn a list of new commands.                  @*)
    (*@         cmd, ok := rp.log.Lookup(lsn)                                   @*)
    (*@                                                                         @*)
    wp_loadField.
    wp_apply (wp_TxnLog__Lookup with "Htxnlog").
    iInv "Hinv" as "> HinvO" "HinvC".
    iApply ncfupd_mask_intro; first set_solver.
    iIntros "Hmask".
    iNamed "HinvO".
    (* Take the required group invariant. *)
    iDestruct (big_sepS_elem_of_acc with "Hgroups") as "[Hgroup HgroupsC]"; first apply Hgid.
    (* Separate out the ownership of the Paxos log from others. *)
    iDestruct (group_inv_expose_cpool_extract_log with "Hgroup") as (cpool paxos) "[Hpaxos Hgroup]".
    (* Obtain a lower bound before passing it to Paxos. *)
    iDestruct (log_witness with "Hpaxos") as "#Hlb".
    iExists paxos. iFrame.
    iIntros (paxos') "Hpaxos".
    (* Obtain prefix between the old and new logs. *)
    iDestruct (log_prefix with "Hpaxos Hlb") as %Hpaxos.
    destruct Hpaxos as [cmds Hpaxos].
    (* Obtain inclusion between the command pool and the log. *)
    iAssert (⌜cpool_subsume_log cpool paxos'⌝)%I as %Hincl.
    { iNamed "Hgroup".
      by iDestruct (log_cpool_incl with "Hpaxos Hcpool") as %Hincl.
    }
    (* Obtain validity of command timestamps; used when executing @apply. *)
    iAssert (⌜Forall valid_ts_of_command paxos'⌝)%I as %Hts.
    { iNamed "Hgroup".
      iAssert (⌜set_Forall valid_ts_of_command cpool⌝)%I as %Hcpoolts.
      { iIntros (c Hc).
        iDestruct (big_sepS_elem_of with "Hvc") as "Hc"; first apply Hc.
        destruct c; simpl.
        { by iDestruct "Hc" as %[Hvts _]. }
        { by iDestruct "Hc" as (?) "[_ [%Hvts _]]". }
        { by iDestruct "Hc" as (?) "[_ [%Hvts _]]". }
        { by iDestruct "Hc" as "[_ %Hvts]". }
      }
      by pose proof (set_Forall_Forall_subsume _ _ _ Hcpoolts Hincl) as Hts.
    }
    (* Obtain prefix between the applied log and the new log; needed later. *)
    iDestruct (log_prefix with "Hpaxos Hloga") as %Hloga.
    (* Obtain a witness of the new log; need later. *)
    iDestruct (log_witness with "Hpaxos") as "#Hlbnew".
    subst paxos'.
    (* Re-establish the group invariant w.r.t. the new log. *)
    iMod (group_inv_learn with "Htxn Hkeys Hgroup") as "(Htxn & Hkeys & Hgroup)".
    { apply Hincl. }
    (* Obtain state machine safety for the new log. *)
    iAssert (⌜not_stuck (apply_cmds (paxos ++ cmds))⌝)%I as %Hns.
    { clear Hrsm. iNamed "Hgroup". iPureIntro. by rewrite Hrsm. }
    iDestruct (group_inv_hide_cpool_merge_log with "Hpaxos Hgroup") as "Hgroup".
    (* Put back the group invariant. *)
    iDestruct ("HgroupsC" with "Hgroup") as "Hgroups".
    (* Close the entire invariant. *)
    iMod "Hmask" as "_".
    iMod ("HinvC" with "[Htxn Hkeys Hgroups]") as "_"; first by iFrame.
    iIntros "!>" (cmd ok pwrsS) "(Htxnlog & HpwrsS & %Hcmd)".
    wp_pures.

    (*@         if !ok {                                                        @*)
    (*@             // Sleep for 1 ms.                                          @*)
    (*@             rp.mu.Unlock()                                              @*)
    (*@             machine.Sleep(1 * 1000000)                                  @*)
    (*@             rp.mu.Lock()                                                @*)
    (*@             continue                                                    @*)
    (*@         }                                                               @*)
    (*@                                                                         @*)
    wp_if_destruct.
    { (* Have applied all the commands known to be committed. *)
      wp_loadField.
      iClear "Hlb Hlbnew".
      wp_apply (release_spec with "[-HΦ $Hlock $Hlocked]"); first by iFrame "∗ # %".
      wp_apply wp_Sleep.
      wp_loadField.
      wp_apply (acquire_spec with "Hlock").
      iIntros "[Hlocked Hrp]".
      wp_pures.
      iApply "HΦ".
      by iFrame.
    }

    (*@         rp.apply(cmd)                                                   @*)
    (*@                                                                         @*)
    (* Obtain a witness for the newly applied log. *)
    iClear "Hlb".
    (* Prove the newly applied log is a prefix of the new log. *)
    assert (Hprefix : prefix (loga ++ [cmd]) (paxos ++ cmds)).
    { rewrite Hnoof in Hcmd.
      replace (Z.to_nat _) with (S (uint.nat lsna)) in Hcmd by word.
      apply take_S_r in Hcmd.
      rewrite -Hlen take_length_prefix in Hcmd; last apply Hloga.
      rewrite -Hcmd.
      apply prefix_take.
    }
    iDestruct (log_lb_weaken (loga ++ [cmd]) with "Hlbnew") as "#Hlb"; first apply Hprefix.
    wp_apply (wp_Replica__apply with "[$Hst $HpwrsS]").
    { (* Prove validity of command timestamps. *)
      rewrite Forall_forall in Hts.
      apply Hts.
      eapply elem_of_prefix; last apply Hprefix.
      set_solver.
    }
    { (* Prove state machine safety for the newly applied log. *)
      pose proof (apply_cmds_not_stuck _ _ Hprefix Hns) as Hsafe.
      by rewrite /apply_cmds foldl_snoc apply_cmds_unfold Hrsm in Hsafe.
    }
    iIntros "Hst".

    (*@         rp.lsna = lsn                                                   @*)
    (*@     }                                                                   @*)
    (*@ }                                                                       @*)
    wp_storeField.
    iApply "HΦ".
    set lsna' := word.add _ _ in Hcmd *.
    subst P.
    iFrame "Hlb". iFrame "∗ # %".
    iPureIntro.
    split.
    { (* Prove [Hlen]. *)
      rewrite app_length singleton_length Hlen Hnoof.
      word.
    }
    { (* Prove [Hrsm]. *)
      by rewrite /rsm_consistency /apply_cmds foldl_snoc apply_cmds_unfold Hrsm.
    }
  Qed.

End program.
