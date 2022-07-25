From Perennial.program_proof.mvcc Require Import txn_common tid_proof.

Section program.
Context `{!heapGS Σ, !mvcc_ghostG Σ}.

(*****************************************************************)
(* func (txnMgr *TxnMgr) activate(sid uint64) uint64             *)
(*****************************************************************)
Theorem wp_txnMgr__activate (txnmgr : loc) (sid : u64) γ :
  is_txnmgr txnmgr γ -∗
  {{{ ⌜(int.Z sid) < N_TXN_SITES⌝ }}}
    TxnMgr__activate #txnmgr #sid
  {{{ (tid : u64), RET #tid; active_tid γ tid sid }}}.
Proof.
  iIntros "#Htxnmgr !>" (Φ) "%HsitesBound HΦ".
  iNamed "Htxnmgr".
  wp_call.
  
  (***********************************************************)
  (* site := txnMgr.sites[sid]                               *)
  (***********************************************************)
  wp_loadField.
  iMod (readonly_load with "HsitesS") as (q) "HsitesS'".
  list_elem sitesL (int.nat sid) as site.
  wp_apply (wp_SliceGet with "[$HsitesS']").
  { iPureIntro.
    rewrite list_lookup_fmap.
    by rewrite Hsite_lookup.
  }
  iIntros "HsitesS'".
  wp_pures.

  (***********************************************************)
  (* site.latch.Lock()                                       *)
  (***********************************************************)
  iDestruct (big_sepL_lookup with "HsitesRP") as "HsiteRP"; first done.
  iClear (latch) "Hlatch Hlock".
  iNamed "HsiteRP".
  wp_loadField.
  wp_apply (acquire_spec with "[$Hlock]").
  iIntros "[Hlocked HsiteOwn]".
  replace (U64 (Z.of_nat _)) with sid by word. 
  iNamed "HsiteOwn".
  wp_pures.
  
  (***********************************************************)
  (* var tid uint64                                          *)
  (* tid = genTID(sid)                                       *)
  (***********************************************************)
  wp_apply (wp_ref_of_zero); first done.
  iIntros (tidRef) "HtidRef".
  wp_pures.
  wp_apply (wp_genTID).
  iIntros (tid) "_".
  wp_store.
  wp_pures.
  
  (***********************************************************)
  (* for tid <= site.tidLast {                               *)
  (*     tid = genTID(sid)                                   *)
  (* }                                                       *)
  (***********************************************************)
  set P := λ (b : bool), (∃ (tidnew : u64),
             "Htidlast" ∷ site ↦[TxnSite :: "tidLast"] #tidlast ∗
             "HtidRef" ∷ tidRef ↦[uint64T] #tidnew ∗
             "%Hexit" ∷ if b then True else ⌜(int.Z tidnew) > (int.Z tidlast)⌝)%I.
  wp_apply (wp_forBreak_cond P with "[] [Htidlast HtidRef]").
  { clear Φ.
    iIntros (Φ) "!> Hloop HΦ".
    iNamed "Hloop".
    wp_load.
    wp_loadField.
    wp_pures.
    case_bool_decide.
    - wp_if_true.
      wp_pures.
      wp_apply (wp_genTID).
      iIntros (tid'') "_".
      wp_store.
      iApply "HΦ".
      unfold P.
      eauto with iFrame.
    - wp_if_false.
      iApply "HΦ".
      unfold P.
      apply Znot_le_gt in H.
      eauto with iFrame.
  }
  { unfold P. eauto with iFrame. }
  iIntros "Hloop".
  iNamed "Hloop".
  wp_pures.
  
  (***********************************************************)
  (* machine.Assume(tid < 18446744073709551615)              *)
  (***********************************************************)
  wp_load.
  wp_apply wp_Assume.
  iIntros "%Htidmax".
  apply bool_decide_eq_true_1 in Htidmax.
  
  (***********************************************************)
  (* site.tidLast = tid                                      *)
  (* site.tidsActive = append(site.tidsActive, tid)          *)
  (***********************************************************)
  wp_load.
  wp_storeField.
  wp_load.
  wp_loadField.
  wp_apply (typed_slice.wp_SliceAppend (V := u64) with "HactiveL").
  iIntros (tidsactive') "HactiveL".
  wp_storeField.
  wp_loadField.

  (* The local set of active tids is added with [tid], prove [tid ≥ tidmin]. *)

  (* Open the global invariant. *)
  iApply fupd_wp.
  iInv "Hinvgc" as ">HinvgcO" "HinvgcC".
  (* unfold mvcc_inv_gc_def. *)
  iDestruct (big_sepL_lookup_acc with "HinvgcO") as "[HinvgcO HinvgcOAcc]".
  { by apply sids_all_lookup. }
  iDestruct "HinvgcO" as (tidsM tidmin') "(HactiveAuth' & HminAuth' & %Hmin)".
  (* Update the set of active tids. *)
  iDestruct (site_active_tids_agree with "HactiveAuth' HactiveAuth") as %->.
  iMod (site_active_tids_insert tidnew with "HactiveAuth' HactiveAuth") as "(HactiveAuth' & HactiveAuth & HactiveFrag)".
  { apply HtidFree. word. }
  set tidsactiveM' := <[tidnew := tt]>tidsactiveM.
  (* Agree on the minimal tid. *)
  iDestruct (site_min_tid_agree with "HminAuth' HminAuth") as "%Emin".
  rewrite Emin. rewrite Emin in Hmin.
  clear Emin tidmin'.
  (* Close the global invariant. *)
  iDestruct ("HinvgcOAcc" with "[HactiveAuth' HminAuth']") as "HinvgcO".
  { do 2 iExists _.
    iFrame "HactiveAuth' HminAuth'".
    subst tidsactiveM'.
    rewrite dom_insert_L.

    iPureIntro.
    intros tidx Helem.
    apply elem_of_union in Helem.

    destruct Helem; last auto.
    apply elem_of_singleton in H.
    subst tidx.
    apply Forall_inv in HtidOrder.
    trans (int.nat tidlast); word.
  }
  iMod ("HinvgcC" with "[HinvgcO]") as "_"; first done.
  iModIntro.
    
  (***********************************************************)
  (* site.latch.Unlock()                                     *)
  (***********************************************************)
  wp_apply (release_spec with "[-HΦ HtidRef HactiveFrag]").
  { iFrame "Hlock Hlocked".
    iNext.
    do 5 iExists _.
    iFrame "% ∗".
    iSplit.
    { (* Prove [HactiveLM]. *)
      iPureIntro.
      (* Q: Why can't rewrite list_to_set_snoc? How to rewrite ≡? *)
      rewrite list_to_set_app_L.
      simpl.
      subst tidsactiveM'.
      rewrite dom_insert_L.
      set_solver.
    }
    iPureIntro.
    split.
    { (* Prove [HactiveND]. *)
      apply NoDup_app.
      split; first done.
      split; last apply NoDup_singleton.
      intros tidx Hin.
      rewrite -HactiveLM in HtidFree.
      setoid_rewrite not_elem_of_list_to_set in HtidFree.
      assert (contra : tidnew ∉ tidsactiveL).
      { apply HtidFree. word. }
      set_solver.
    }
    split.
    { (* Prove [HtidOrder]. *)
      apply Forall_cons.
      split.
      { split; last done.
        apply Forall_inv in HtidOrder. word.
      }
      apply Forall_app.
      split; last first.
      { apply Forall_singleton.
        split; last done.
        apply Forall_inv in HtidOrder. word.
      }
      apply Forall_inv_tail in HtidOrder.
      apply (Forall_impl _ _ _ HtidOrder).
      word.
    }
    split; last done.
    { (* Prove [HtidlastNotin]. *)
      simpl.
      intros tidx Htidx.
      subst tidsactiveM'.
      rewrite dom_insert_L.
      apply not_elem_of_union.
      split.
      - unfold not. intros contra.
        rewrite elem_of_singleton in contra.
        rewrite contra in Htidx. word.
      - apply HtidFree. word.
    }
  }
  wp_pures.
  wp_load.
  
  (***********************************************************)
  (* return tid                                              *)
  (***********************************************************)
  iApply "HΦ".
  iModIntro.
  iFrame.
  iPureIntro. word.
Qed.

End program.