From Perennial.program_proof Require Import grove_prelude.
From Perennial.program_proof.rsm Require Import big_sep.
From Perennial.program_proof.rsm.pure Require Import quorum list extend.
From Perennial.program_proof.tulip.paxos Require Import base res.

Section inv.
  Context `{!heapGS Σ, !paxos_ghostG Σ}.

  Definition paxosNS := nroot .@ "paxos".

  Definition nodedec_to_ledger d :=
    match d with
    | Accept v => Some v
    | Reject => None
    end.

  Lemma nodedec_to_ledger_Some_inv d v :
    nodedec_to_ledger d = Some v ->
    d = Accept v.
  Proof. by destruct d; first inv 1. Qed.

  Lemma nodedec_to_ledger_None_inv d :
    nodedec_to_ledger d = None ->
    d = Reject.
  Proof. by destruct d. Qed.

  Definition fixed_proposals (ds : list nodedec) (ps : proposals) :=
    ∀ t d, ds !! t = Some d -> ps !! t = nodedec_to_ledger d.

  Definition free_terms_after (t : nat) (ts : gset nat) :=
    ∀ t', (t < t')%nat -> t' ∉ ts.

  Definition prefix_base_ledger γ t v : iProp Σ :=
    ∃ vlb, is_base_proposal_receipt γ t vlb ∗ ⌜prefix vlb v⌝.

  Definition prefix_growing_ledger γ t v : iProp Σ :=
    ∃ vub, is_proposal_lb γ t vub ∗ ⌜prefix v vub⌝.

  Definition node_inv γ nid terml : iProp Σ :=
    ∃ ds psa termc logn,
      "Hds" ∷ own_past_nodedecs γ nid ds ∗
      "Hpsa"   ∷ own_accepted_proposals γ nid psa ∗
      "Htermc" ∷ own_current_term_half γ nid termc ∗
      "Hterml" ∷ own_ledger_term_half γ nid terml ∗
      "Hlogn"  ∷ own_node_ledger_half γ nid logn ∗
      "Hacpt"  ∷ own_accepted_proposal γ nid terml logn ∗
      "#Hpsalbs" ∷ ([∗ map] t ↦ v ∈ psa, prefix_base_ledger γ t v) ∗
      "#Hpsaubs" ∷ ([∗ map] t ↦ v ∈ psa, prefix_growing_ledger γ t v) ∗
      "%Hfixed"  ∷ ⌜fixed_proposals ds psa⌝ ∗
      "%Hdompsa" ∷ ⌜free_terms_after terml (dom psa)⌝ ∗
      "%Hlends"  ∷ ⌜length ds = termc⌝ ∗
      "%Htermlc" ∷ ⌜(terml ≤ termc)%nat⌝.

  Definition node_inv_without_ds_psa
    γ nid terml (ds : list nodedec) (psa : proposals) : iProp Σ :=
    ∃ termc logn,
      "Htermc" ∷ own_current_term_half γ nid termc ∗
      "Hterml" ∷ own_ledger_term_half γ nid terml ∗
      "Hlogn"  ∷ own_node_ledger_half γ nid logn ∗
      "Hacpt"  ∷ own_accepted_proposal γ nid terml logn ∗
      "%Hdompsa" ∷ ⌜free_terms_after terml (dom psa)⌝ ∗
      "%Hlends"  ∷ ⌜length ds = termc⌝ ∗
      "%Htermlc" ∷ ⌜(terml ≤ termc)%nat⌝.

  Definition node_inv_psa γ nid psa : iProp Σ :=
    "Hpsa"     ∷ own_accepted_proposals γ nid psa ∗
    "#Hpsalbs" ∷ ([∗ map] t ↦ v ∈ psa, prefix_base_ledger γ t v) ∗
    "#Hpsaubs" ∷ ([∗ map] t ↦ v ∈ psa, prefix_growing_ledger γ t v).

  Definition node_inv_ds_psa γ nid ds psa : iProp Σ :=
    "Hpsa"    ∷ node_inv_psa γ nid psa ∗
    "Hpastd"  ∷ own_past_nodedecs γ nid ds ∗
    "%Hfixed" ∷ ⌜fixed_proposals ds psa⌝.

  Lemma own_ledger_term_node_inv_terml_eq γ nid terml terml' :
    own_ledger_term_half γ nid terml -∗
    node_inv γ nid terml' -∗
    ⌜terml' = terml⌝.
  Proof.
    iIntros "HtermlX Hnode".
    iNamed "Hnode".
    by iDestruct (ledger_term_agree with "HtermlX Hterml") as %->.
  Qed.

  Definition safe_ledger_in γ nids t v : iProp Σ :=
    ∃ nid nidsq,
      "#Hvacpt"  ∷ is_accepted_proposal_lb γ nid t v ∗
      "#Hacpt"   ∷ ([∗ set] nid ∈ nidsq, is_accepted_proposal_length_lb γ nid t (length v)) ∗
      "%Hquorum" ∷ ⌜cquorum nids nidsq⌝ ∗
      "%Hmember" ∷ ⌜nid ∈ nids⌝.

  Definition safe_ledger γ nids v : iProp Σ :=
    ∃ t, safe_ledger_in γ nids t v.

  Definition safe_ledger_above γ nids t v : iProp Σ :=
    ∃ t', safe_ledger_in γ nids t' v ∗ ⌜(t' ≤ t)%nat⌝.

  Lemma safe_ledger_above_mono {γ nids} t v t' :
    (t ≤ t')%nat ->
    safe_ledger_above γ nids t v -∗
    safe_ledger_above γ nids t' v.
  Proof. iIntros (Hle) "(%p & Hsafe & %Hp)". iExists p. iFrame. iPureIntro. lia. Qed.

  Definition equal_latest_longest_proposal_nodedec (dssq : gmap u64 (list nodedec)) t v :=
    equal_latest_longest_proposal_with (mbind nodedec_to_ledger) dssq t v.

  Definition safe_base_proposal γ nids t v : iProp Σ :=
    ∃ dssqlb,
      "#Hdsq"    ∷ ([∗ map] nid ↦ ds ∈ dssqlb, is_past_nodedecs_lb γ nid ds) ∗
      "%Hlen"    ∷ ⌜map_Forall (λ _ ds, (length ds = t)%nat) dssqlb⌝ ∗
      "%Heq"     ∷ ⌜equal_latest_longest_proposal_nodedec dssqlb t v⌝ ∗
      "%Hquorum" ∷ ⌜cquorum nids (dom dssqlb)⌝.

  Definition latest_term_before_nodedec t (ds : list nodedec) :=
    latest_term_before_with (mbind nodedec_to_ledger) t ds.

  Lemma latest_term_before_nodedec_unfold t ds :
    latest_term_before_nodedec t ds = latest_term_before_with (mbind nodedec_to_ledger) t ds.
  Proof. done. Qed.

  Definition latest_term_nodedec ds :=
    latest_term_before_nodedec (length ds) ds.

  Lemma latest_term_nodedec_unfold ds :
    latest_term_nodedec ds = latest_term_before_nodedec (length ds) ds.
  Proof. done. Qed.

  Lemma latest_term_before_nodedec_app t ds dsapp :
    (t ≤ length ds)%nat ->
    latest_term_before_nodedec t (ds ++ dsapp) = latest_term_before_nodedec t ds.
  Proof.
    intros Hlen.
    rewrite /latest_term_before_nodedec.
    induction t as [| t IH]; first done.
    rewrite /= -IH; last lia.
    by rewrite lookup_app_l; last lia.
  Qed.

  Lemma latest_term_nodedec_snoc_Reject ds :
    latest_term_nodedec (ds ++ [Reject]) = latest_term_nodedec ds.
  Proof.
    rewrite /latest_term_nodedec /latest_term_before_nodedec last_length /=.
    rewrite lookup_snoc_length /=.
    by apply latest_term_before_nodedec_app.
  Qed.

  Lemma latest_term_nodedec_extend_Reject t ds :
    latest_term_nodedec (extend t Reject ds) = latest_term_nodedec ds.
  Proof.
    unfold extend.
    induction t as [| t IH]; first by rewrite app_nil_r.
    destruct (decide (t < length ds)%nat) as [Hlt | Hge].
    { replace (t - length ds)%nat with O in IH by lia.
      by replace (S t - length ds)%nat with O by lia.
    }
    replace (S t - length ds)%nat with (S (t - length ds)%nat) by lia.
    by rewrite replicate_S_end assoc latest_term_nodedec_snoc_Reject.
  Qed.

  Lemma fixed_proposals_latest_term_before_nodedec ds psa t :
    (t ≤ length ds)%nat ->
    fixed_proposals ds psa ->
    latest_term_before_nodedec t ds = latest_term_before t psa.
  Proof.
    intros Hlen Hfixed.
    rewrite /latest_term_before_nodedec /latest_term_before.
    induction t as [| p IH]; first done.
    simpl.
    assert (p < length ds)%nat as Hp by lia.
    apply list_lookup_lt in Hp as [d Hd].
    specialize (Hfixed _ _ Hd).
    rewrite Hd /= -Hfixed IH; [done | lia].
  Qed.

  Definition latest_term_before_quorum_nodedec (dss : gmap u64 (list nodedec)) t :=
    latest_term_before_quorum_with (mbind nodedec_to_ledger) dss t.

  Lemma latest_term_before_quorum_nodedec_unfold dss t :
    latest_term_before_quorum_nodedec dss t =
    latest_term_before_quorum_with (mbind nodedec_to_ledger) dss t.
  Proof. done. Qed.

  Lemma latest_term_before_quorum_nodedec_prefixes dss dsslb t :
    map_Forall2 (λ _ dslb ds, prefix dslb ds ∧ (t ≤ length dslb)%nat) dsslb dss ->
    latest_term_before_quorum_nodedec dsslb t = latest_term_before_quorum_nodedec dss t.
  Proof.
    intros Hprefixes.
    rewrite /latest_term_before_quorum_nodedec /latest_term_before_quorum_with.
    f_equal.
    apply map_eq.
    intros nid.
    rewrite 2!lookup_fmap.
    specialize (Hprefixes nid).
    destruct (dsslb !! nid) as [dslb |], (dss !! nid) as [ds |]; [| done | done | done].
    simpl. simpl in Hprefixes.
    f_equal.
    destruct Hprefixes as [[dsapp ->] Hlen].
    by rewrite -2!latest_term_before_nodedec_unfold latest_term_before_nodedec_app.
  Qed.

  Lemma fixed_proposals_latest_term_before_quorum_nodedec dss (bs : gmap u64 proposals) t :
    map_Forall2 (λ _ ds psa, fixed_proposals ds psa ∧ (t ≤ length ds)%nat) dss bs ->
    latest_term_before_quorum_nodedec dss t = latest_term_before_quorum bs t.
  Proof.
    intros Hfixed.
    rewrite /latest_term_before_quorum_nodedec /latest_term_before_quorum.
    rewrite /latest_term_before_quorum_with.
    f_equal.
    apply map_eq.
    intros x.
    rewrite 2!lookup_fmap.
    specialize (Hfixed x).
    destruct (dss !! x) as [ds |], (bs !! x) as [ps |]; [| done | done | done].
    simpl.
    f_equal.
    destruct Hfixed as [Hfixed Hlen].
    by apply fixed_proposals_latest_term_before_nodedec.
  Qed.

  Definition ledger_in_term_nodedec t (ds : list nodedec) :=
    ledger_in_term_with (mbind nodedec_to_ledger) t ds.

  Lemma fixed_proposals_ledger_in_term_nodedec ds psa t :
    (t < length ds)%nat ->
    fixed_proposals ds psa ->
    ledger_in_term_nodedec t ds = ledger_in_term t psa.
  Proof.
    intros Hlen Hfixed.
    rewrite /ledger_in_term_nodedec /ledger_in_term /ledger_in_term_with /=.
    apply list_lookup_lt in Hlen as [d Hd].
    specialize (Hfixed _ _ Hd).
    by rewrite Hd Hfixed.
  Qed.

  Definition longest_proposal_in_term_nodedec (dss : gmap u64 (list nodedec)) t :=
    longest_proposal_in_term_with (mbind nodedec_to_ledger) dss t.

  Lemma longest_proposal_in_term_nodedec_unfold dss t :
    longest_proposal_in_term_nodedec dss t =
    longest_proposal_in_term_with (mbind nodedec_to_ledger) dss t.
  Proof. done. Qed.

  Lemma longest_proposal_in_term_nodedec_prefixes dss dsslb t :
    map_Forall2 (λ _ dslb ds, prefix dslb ds ∧ (t < length dslb)%nat) dsslb dss ->
    longest_proposal_in_term_nodedec dsslb t = longest_proposal_in_term_nodedec dss t.
  Proof.
    intros Hprefixes.
    rewrite /longest_proposal_in_term_nodedec /longest_proposal_in_term_with.
    f_equal.
    apply map_eq.
    intros nid.
    rewrite 2!lookup_fmap.
    specialize (Hprefixes nid).
    rewrite /ledger_in_term_with.
    destruct (dsslb !! nid) as [dslb |], (dss !! nid) as [ds |]; [| done | done | done].
    simpl. simpl in Hprefixes.
    f_equal.
    destruct Hprefixes as [Hprefix Hlen].
    by rewrite (prefix_lookup_lt _ _ _ Hlen Hprefix).
  Qed.

  Lemma fixed_proposals_longest_proposal_in_term_nodedec dss (bs : gmap u64 proposals) t :
    map_Forall2 (λ _ ds psa, fixed_proposals ds psa ∧ (t < length ds)%nat) dss bs ->
    longest_proposal_in_term_nodedec dss t = longest_proposal_in_term bs t.
  Proof.
    intros Hfixed.
    rewrite /longest_proposal_in_term_nodedec /longest_proposal_in_term.
    rewrite /longest_proposal_in_term_with.
    f_equal.
    apply map_eq.
    intros x.
    rewrite 2!lookup_fmap.
    specialize (Hfixed x).
    destruct (dss !! x) as [ds |], (bs !! x) as [ps |]; [| done | done | done].
    simpl.
    f_equal.
    destruct Hfixed as [Hfixed Hlen].
    by apply fixed_proposals_ledger_in_term_nodedec.
  Qed.

  Lemma fixed_proposals_equal_latest_longest_proposal_nodedec dss bs t v :
    map_Forall2 (λ _ ds psa, fixed_proposals ds psa ∧ (t ≤ length ds)%nat) dss bs ->
    equal_latest_longest_proposal_nodedec dss t v ->
    equal_latest_longest_proposal bs t v.
  Proof.
    rewrite /equal_latest_longest_proposal /equal_latest_longest_proposal_nodedec.
    rewrite /equal_latest_longest_proposal_with.
    intros Hfixed Heq.
    case_decide as Hv; first done.
    rewrite -Heq -latest_term_before_quorum_nodedec_unfold.
    rewrite (fixed_proposals_latest_term_before_quorum_nodedec _ _ _ Hfixed).
    set t' := latest_term_before_quorum _ _.
    rewrite -longest_proposal_in_term_nodedec_unfold.
    unshelve erewrite (fixed_proposals_longest_proposal_in_term_nodedec dss bs t' _).
    { intros nid.
      specialize (Hfixed nid).
      destruct (dss !! nid) as [ds |], (bs !! nid) as [ps |]; [| done | done | done].
      simpl. simpl in Hfixed.
      destruct Hfixed as [Hfixed Hlen].
      split; first done.
      subst t'.
      eapply Nat.lt_le_trans; last apply Hlen.
      by apply latest_term_before_quorum_with_lt.
    }
    done.
  Qed.

  Definition past_nodedecs_latest_before γ nid termc terml v : iProp Σ :=
    ∃ ds,
      "#Hpastd"  ∷ is_past_nodedecs_lb γ nid ds ∗
      "%Hlends"  ∷ ⌜length ds = termc⌝ ∗
      "%Hlatest" ∷ ⌜latest_term_nodedec ds = terml⌝ ∗
      "%Hacpt"   ∷ ⌜ds !! terml = Some (Accept v)⌝.

  Definition paxos_inv γ nids : iProp Σ :=
    ∃ log cpool logi ps psb termlm,
      (* external states *)
      "Hlog"   ∷ own_log_half γ log ∗
      "Hcpool" ∷ own_cpool_half γ cpool ∗
      (* internal states *)
      "Hlogi" ∷ own_internal_log γ logi ∗
      "Hps"   ∷ own_proposals γ ps ∗
      "Hpsb"  ∷ own_base_proposals γ psb ∗
      (* node states *)
      "Hnodes" ∷ ([∗ map] nid ↦ terml ∈ termlm, node_inv γ nid terml) ∗
      (* TODO: constraints between internal and external states *)
      (* constraints on internal states *)
      "#Hsafelogi"  ∷ safe_ledger γ nids logi ∗
      "#Hsafepsb"   ∷ ([∗ map] t ↦ v ∈ psb, safe_base_proposal γ nids t v) ∗
      "%Hvp"        ∷ ⌜valid_proposals ps psb⌝ ∗
      "%Hdomtermlm" ∷ ⌜dom termlm = nids⌝ ∗
      "%Hdompsb"    ∷ ⌜free_terms (dom psb) termlm⌝.

  #[global]
  Instance paxos_inv_timeless γ nids :
    Timeless (paxos_inv γ nids).
  Admitted.

  Definition know_paxos_inv γ nids : iProp Σ :=
    inv paxosNS (paxos_inv γ nids).

End inv.

Section lemma.
  Context `{!paxos_ghostG Σ}.

  Lemma equal_latest_longest_proposal_nodedec_prefix dss dsslb t v :
    map_Forall2 (λ _ dslb ds, prefix dslb ds ∧ (t ≤ length dslb)%nat) dsslb dss ->
    equal_latest_longest_proposal_nodedec dsslb t v ->
    equal_latest_longest_proposal_nodedec dss t v.
  Proof.
    rewrite /equal_latest_longest_proposal_nodedec /equal_latest_longest_proposal_with.
    rewrite -2!latest_term_before_quorum_nodedec_unfold.
    rewrite -2!longest_proposal_in_term_nodedec_unfold.
    intros Hprefixes Heq.
    case_decide as Ht; first done.
    rewrite -(latest_term_before_quorum_nodedec_prefixes _ _ _ Hprefixes).
    set t' := (latest_term_before_quorum_nodedec _ _) in Heq *.
    assert (Hlt : (t' < t)%nat).
    { by apply latest_term_before_quorum_with_lt. }
    rewrite -(longest_proposal_in_term_nodedec_prefixes dss dsslb); first apply Heq.
    apply (map_Forall2_impl _ _ _ _ Hprefixes).
    intros _ dslb ds [Hprefix Hlen].
    split; [done | lia].
  Qed.

  Lemma node_inv_is_accepted_proposal_lb_impl_prefix γ bs nid1 nid2 t v1 v2 :
    nid1 ∈ dom bs ->
    nid2 ∈ dom bs ->
    is_accepted_proposal_lb γ nid1 t v1 -∗
    is_accepted_proposal_lb γ nid2 t v2 -∗
    ([∗ map] nid ↦ psa ∈ bs, node_inv_psa γ nid psa) -∗
    ⌜prefix v1 v2 ∨ prefix v2 v1⌝.
  Proof.
    iIntros (Hnid1 Hnid2) "Hv1 Hv2 Hnodes".
    iAssert (prefix_growing_ledger γ t v1)%I as "#Hvub1".
    { rewrite elem_of_dom in Hnid1.
      destruct Hnid1 as [ps Hps].
      iDestruct (big_sepM_lookup _ _ nid1 with "Hnodes") as "Hnode"; first apply Hps.
      iNamed "Hnode".
      iDestruct (accepted_proposal_lb_lookup with "Hv1 Hpsa") as %(vub & Hvub & Hprefix).
      iDestruct (big_sepM_lookup with "Hpsaubs") as (vub') "[Hvub' %Hprefix']"; first apply Hvub.
      iExists vub'.
      iFrame "Hvub'".
      iPureIntro.
      by trans vub.
    }
    iAssert (prefix_growing_ledger γ t v2)%I as "#Hvub2".
    { rewrite elem_of_dom in Hnid2.
      destruct Hnid2 as [ps Hps].
      iDestruct (big_sepM_lookup _ _ nid2 with "Hnodes") as "Hnode"; first apply Hps.
      iNamed "Hnode".
      iDestruct (accepted_proposal_lb_lookup with "Hv2 Hpsa") as %(vub & Hvub & Hprefix).
      iDestruct (big_sepM_lookup with "Hpsaubs") as (vub') "[Hvub' %Hprefix']"; first apply Hvub.
      iExists vub'.
      iFrame "Hvub'".
      iPureIntro.
      by trans vub.
    }
    iDestruct "Hvub1" as (vub1) "[#Hvub1 %Hprefix1]".
    iDestruct "Hvub2" as (vub2) "[#Hvub2 %Hprefix2]".
    iDestruct (proposal_lb_prefix with "Hvub1 Hvub2") as %Hprefix.
    iPureIntro.
    destruct Hprefix as [Hprefix | Hprefix].
    { apply (prefix_common_ub _ _ vub2); last apply Hprefix2.
      by trans vub1.
    }
    { apply (prefix_common_ub _ _ vub1); first apply Hprefix1.
      by trans vub2.
    }
  Qed.

  Lemma nodes_inv_impl_valid_base_proposals γ nids bs psb dss :
    dom bs = nids ->
    ([∗ map] t ↦ v ∈ psb, safe_base_proposal γ nids t v) -∗
    ([∗ map] nid ↦ ds; psa ∈ dss; bs, node_inv_ds_psa γ nid ds psa) -∗
    ⌜valid_base_proposals bs psb⌝.
  Proof.
    iIntros (Hdombs) "Hsafe Hinv".
    iIntros (t v Hv).
    iDestruct (big_sepM_lookup with "Hsafe") as "Hsafe"; first apply Hv.
    iNamed "Hsafe".
    rewrite /valid_base_proposal.
    rewrite big_sepM2_alt.
    iDestruct "Hinv" as "[%Hdomdss Hinv]".
    iDestruct (big_sepM_dom_subseteq_difference _ _ (dom dssqlb) with "Hinv") as "Hm".
    { rewrite dom_map_zip_with_L Hdomdss intersection_idemp Hdombs.
      by destruct Hquorum as [Hincl _].
    }
    iDestruct "Hm" as (m [Hdomm Hinclm]) "[Hm _]".
    set dssq := fst <$> m.
    set bsq := snd <$> m.
    iExists bsq.
    iAssert (⌜map_Forall2 (λ _ dslb ds, prefix dslb ds ∧ (t ≤ length dslb)%nat) dssqlb dssq⌝)%I
      as %Hprefix.
    { iIntros (x).
      destruct (dssqlb !! x) as [dslb |] eqn:Hdslb, (dssq !! x) as [ds |] eqn:Hds; last first.
      { done. }
      { rewrite -not_elem_of_dom -Hdomm not_elem_of_dom in Hdslb.
        subst dssq.
        by rewrite lookup_fmap Hdslb /= in Hds.
      }
      { subst dssq.
        by rewrite -not_elem_of_dom dom_fmap_L Hdomm not_elem_of_dom Hdslb in Hds.
      }
      simpl.
      iDestruct (big_sepM_lookup with "Hdsq") as "Hdsqx"; first apply Hdslb.
      rewrite lookup_fmap_Some in Hds.
      destruct Hds as ([ds' psa] & Hds & Hmx). simpl in Hds. subst ds'.
      iDestruct (big_sepM_lookup with "Hm") as "Hinv"; first apply Hmx.
      iNamed "Hinv". simpl.
      iDestruct (past_nodedecs_prefix with "Hdsqx Hpastd") as %Hprefix.
      iPureIntro.
      split; first done.
      specialize (Hlen _ _ Hdslb). simpl in Hlen.
      lia.
    }
    pose proof (equal_latest_longest_proposal_nodedec_prefix _ _ _ _ Hprefix Heq) as Heq'.
    iAssert (⌜map_Forall2 (λ _ ds psa, fixed_proposals ds psa ∧ (t ≤ length ds)%nat) dssq bsq⌝)%I
      as %Hfixed.
    { iIntros (x).
      destruct (dssq !! x) as [ds |] eqn:Hds, (bsq !! x) as [psa |] eqn:Hpsa; last first.
      { done. }
      { rewrite -not_elem_of_dom dom_fmap_L in Hds.
        apply elem_of_dom_2 in Hpsa.
        by rewrite dom_fmap_L in Hpsa.
      }
      { rewrite -not_elem_of_dom dom_fmap_L in Hpsa.
        apply elem_of_dom_2 in Hds.
        by rewrite dom_fmap_L in Hds.
      }
      simpl.
      iDestruct (big_sepM_lookup _ _ x (ds, psa) with "Hm") as "Hinv".
      { rewrite lookup_fmap_Some in Hds.
        destruct Hds as ([ds1 psa1] & Hds & Hmx1). simpl in Hds. subst ds1.
        rewrite lookup_fmap_Some in Hpsa.
        destruct Hpsa as ([ds2 psa2] & Hpsa & Hmx2). simpl in Hpsa. subst psa2.
        rewrite Hmx1 in Hmx2.
        by inv Hmx2.
      }
      iNamed "Hinv".
      specialize (Hprefix x).
      assert (is_Some (dssqlb !! x)) as [dslb Hdslb].
      { rewrite -elem_of_dom -Hdomm elem_of_dom.
        apply lookup_fmap_Some in Hds as (dp & _ & Hinv).
        done.
      }
      rewrite Hds Hdslb /= in Hprefix.
      iPureIntro.
      split; first apply Hfixed.
      destruct Hprefix as [Hprefix Hlelen].
      apply prefix_length in Hprefix.
      lia.
    }
    iPureIntro.
    split.
    { subst bsq.
      trans (snd <$> map_zip dss bs).
      { by apply map_fmap_mono. }
      rewrite snd_map_zip; first done.
      intros x Hbsx.
      by rewrite -elem_of_dom -Hdomdss elem_of_dom in Hbsx.
    }
    split.
    { subst bsq.
      rewrite dom_fmap_L Hdomm Hdombs.
      by destruct Hquorum as [_ Hquorum].
    }
    by eapply fixed_proposals_equal_latest_longest_proposal_nodedec.
  Qed.

  Lemma nodes_inv_impl_valid_lb_ballots γ bs psb :
    own_base_proposals γ psb -∗
    ([∗ map] nid ↦ psa ∈ bs, node_inv_psa γ nid psa) -∗
    ⌜valid_lb_ballots bs psb⌝.
  Proof.
    iIntros "Hpsb Hinv".
    iIntros (nid psa Hpsa).
    iDestruct (big_sepM_lookup with "Hinv") as "Hinv"; first apply Hpsa.
    iNamed "Hinv".
    iIntros (t v Hv).
    iDestruct (big_sepM_lookup with "Hpsalbs") as (vlb) "[Hvlb %Hprefix]"; first apply Hv.
    iDestruct (base_proposal_lookup with "Hvlb Hpsb") as %Hvlb.
    by eauto.
  Qed.

  Lemma nodes_inv_impl_valid_ub_ballots γ bs ps :
    own_proposals γ ps -∗
    ([∗ map] nid ↦ psa ∈ bs, node_inv_psa γ nid psa) -∗
    ⌜valid_ub_ballots bs ps⌝.
  Proof.
    iIntros "Hps Hinv".
    iIntros (nid psa Hpsa).
    iDestruct (big_sepM_lookup with "Hinv") as "Hinv"; first apply Hpsa.
    iNamed "Hinv".
    iIntros (t v Hv).
    iDestruct (big_sepM_lookup with "Hpsaubs") as (vlb) "[Hvub %Hprefix]"; first apply Hv.
    iDestruct (proposal_prefix with "Hvub Hps") as %(vub & Hvub & Hprefixvlb).
    iPureIntro.
    exists vub.
    split; first apply Hvub.
    by trans vlb.
  Qed.

  Lemma node_inv_extract_ds_psa γ nid terml :
    node_inv γ nid terml -∗
    ∃ ds psa, node_inv_without_ds_psa γ nid terml ds psa ∗
              node_inv_ds_psa γ nid ds psa.
  Proof. iIntros "Hinv". iNamed "Hinv". iFrame "∗ # %". Qed.

  Lemma nodes_inv_extract_ds_psa γ termlm :
    ([∗ map] nid ↦ terml ∈ termlm, node_inv γ nid terml) -∗
    ∃ dss bs, ([∗ map] nid ↦ terml; dp ∈ termlm; map_zip dss bs,
                 node_inv_without_ds_psa γ nid terml dp.1 dp.2) ∗
              ([∗ map] nid ↦ ds; psa ∈ dss; bs, node_inv_ds_psa γ nid ds psa).
  Proof.
    iIntros "Hinvs".
    set Φ := (λ nid terml dp,
                node_inv_without_ds_psa γ nid terml dp.1 dp.2 ∗
                node_inv_ds_psa γ nid dp.1 dp.2)%I.
    iDestruct (big_sepM_sepM2_exists Φ termlm with "[Hinvs]") as (dpm) "Hdpm".
    { iApply (big_sepM_mono with "Hinvs").
      iIntros (nid terml Hterml) "Hinv".
      subst Φ.
      iNamed "Hinv".
      iExists (ds, psa).
      iFrame "∗ # %".
    }
    iDestruct (big_sepM2_dom with "Hdpm") as %Hdom.
    subst Φ.
    iNamed "Hdpm".
    iDestruct (big_sepM2_sep with "Hdpm") as "[Hinv Hdp]".
    iExists (fst <$> dpm), (snd <$> dpm).
    rewrite map_zip_fst_snd.
    iFrame "Hinv".
    iDestruct (big_sepM2_flip with "Hdp") as "Hdp".
    rewrite -big_sepM_big_sepM2; last apply Hdom.
    rewrite big_sepM2_alt map_zip_fst_snd.
    iFrame "Hdp".
    iPureIntro.
    by rewrite 2!dom_fmap_L.
  Qed.

  Lemma nodes_inv_merge_ds_psa γ termlm dss bs :
    ([∗ map] nid ↦ terml; dp ∈ termlm; map_zip dss bs,
       node_inv_without_ds_psa γ nid terml dp.1 dp.2) -∗
    ([∗ map] nid ↦ ds; psa ∈ dss; bs, node_inv_ds_psa γ nid ds psa) -∗
    ([∗ map] nid ↦ terml ∈ termlm, node_inv γ nid terml).
  Proof.
    iIntros "Hinv Hdp".
    iDestruct (big_sepM2_alt with "Hdp") as "[%Hdom Hdp]".
    iDestruct (big_sepM2_dom with "Hinv") as %Hdomtermlm.
    iDestruct (big_sepM_big_sepM2_1 with "Hdp") as "Hdp".
    { apply Hdomtermlm. }
    rewrite big_sepM2_flip.
    iCombine "Hinv Hdp" as "Hinv".
    rewrite -big_sepM2_sep.
    iApply (big_sepM2_sepM_impl with "Hinv").
    { apply Hdomtermlm. }
    iIntros (nid dp terml terml' Hdp Hterml Hterml') "!> [Hinv Hdp]".
    rewrite Hterml in Hterml'. symmetry in Hterml'. inv Hterml'.
    iNamed "Hinv".
    iNamed "Hdp".
    iNamed "Hpsa".
    iFrame "∗ # %".
  Qed.

  Lemma nodes_inv_ds_psa_impl_nodes_inv_psa γ dss bs :
    ([∗ map] nid ↦ ds; psa ∈ dss; bs, node_inv_ds_psa γ nid ds psa) -∗
    ([∗ map] nid ↦ psa ∈ bs, node_inv_psa γ nid psa).
  Proof.
    iIntros "Hpds".
    rewrite big_sepM2_flip.
    iApply (big_sepM2_sepM_impl with "Hpds"); first done.
    iIntros (nid psa ds psa' Hpsa Hds Hpsa') "!> Hpd".
    rewrite Hpsa in Hpsa'. symmetry in Hpsa'. inv Hpsa'.
    by iNamed "Hpd".
  Qed.

  Lemma nodes_inv_impl_nodes_inv_psa γ termlm :
    ([∗ map] nid ↦ terml ∈ termlm, node_inv γ nid terml) -∗
    ∃ bs, ([∗ map] nid ↦ psa ∈ bs, node_inv_psa γ nid psa) ∗ ⌜dom bs = dom termlm⌝.
  Proof.
    iIntros "Hnodes".
    iDestruct (nodes_inv_extract_ds_psa with "Hnodes") as (dss bs) "[Hxdp Hdp]".
    iDestruct (big_sepM2_dom with "Hxdp") as %Hdom.
    iDestruct (big_sepM2_dom with "Hdp") as %Hdom'.
    rewrite dom_map_zip_with_L Hdom' intersection_idemp_L in Hdom.
    iDestruct (nodes_inv_ds_psa_impl_nodes_inv_psa with "Hdp") as "Hp".
    iExists bs.
    by iFrame.
  Qed.

  Lemma nodes_inv_safe_ledger_in_impl_chosen_in γ nids bs t v :
    dom bs = nids ->
    safe_ledger_in γ nids t v -∗
    ([∗ map] nid ↦ psa ∈ bs, node_inv_psa γ nid psa) -∗
    ⌜chosen_in bs t v⌝.
  Proof.
    iIntros (Hdombs) "#Hsafe Hinv".
    iNamed "Hsafe".
    set bsq := (filter (λ x, x.1 ∈ nidsq) bs).
    iExists bsq.
    rewrite base.and_assoc.
    iSplit.
    { iPureIntro.
      split; first apply map_filter_subseteq.
      rewrite Hdombs.
      subst bsq.
      destruct Hquorum as [Hincl Hquorum].
      rewrite (dom_filter_L _ _ nidsq); first apply Hquorum.
      intros nidx.
      split; last by intros (ps & _ & Hin).
      intros Hin.
      assert (is_Some (bs !! nidx)) as [ps Hps].
      { rewrite -elem_of_dom Hdombs. set_solver. }
      by exists ps.
    }
    iIntros (nid' ps Hps).
    iDestruct (big_sepS_elem_of _ _ nid' with "Hacpt") as "Hvacpt'".
    { by apply map_lookup_filter_Some_1_2 in Hps. }
    iDestruct "Hvacpt'" as (v') "[Hvacpt' %Hlen]".
    iDestruct (node_inv_is_accepted_proposal_lb_impl_prefix with "Hvacpt Hvacpt' Hinv") as %Hprefix.
    { by rewrite -Hdombs in Hmember. }
    { apply elem_of_dom_2 in Hps.
      apply (elem_of_weaken _ (dom bsq)); first done.
      apply dom_filter_subseteq.
    }
    assert (Hvv' : prefix v v').
    { destruct Hprefix as [Hprefix | Hprefix]; first apply Hprefix.
      by rewrite (prefix_length_eq _ _ Hprefix Hlen).
    }
    iDestruct (accepted_proposal_lb_weaken v with "Hvacpt'") as "Hlb"; first apply Hvv'.
    iDestruct (big_sepM_lookup with "Hinv") as "Hnode".
    { eapply lookup_weaken; [apply Hps | apply map_filter_subseteq]. }
    iNamed "Hnode".
    iDestruct (accepted_proposal_prefix with "Hvacpt' Hpsa") as %(va & Hva & Hprefixva).
    iPureIntro.
    exists va.
    split; first apply Hva.
    by trans v'.
  Qed.

End lemma.
