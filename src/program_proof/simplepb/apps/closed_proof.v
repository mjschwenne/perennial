From Perennial.program_proof Require Import grove_prelude.
From Goose.github_com.mit_pdos.gokv.simplepb.apps Require Import closed.

From Perennial.goose_lang Require adequacy dist_adequacy.
From Perennial.goose_lang.ffi Require grove_ffi_adequacy.
From Perennial.program_logic Require dist_lang.

From Perennial.program_proof.simplepb Require Import config_proof.
From Perennial.program_proof.grove_shared Require Import urpc_proof.

Module closed.

Import adequacy dist_adequacy grove_ffi_adequacy dist_lang.

Definition grove_dist_adequate
           (enonidempσs: list (node_init_cfg (Λ:=goose_lang)))
           (ebσs: list (goose_lang.expr * goose_lang.state))
           (g: goose_lang.global_state) :=
  let ρs := fmap (λ ebσ, {| init_thread := fst ebσ;
                           init_restart := fst ebσ;
                           init_local_state := snd ebσ |})
               ebσs in
  dist_adequacy.dist_adequate (CS := goose_crash_lang) (enonidempσs ++ ρs) g.

Definition kv_pbΣ := #[heapΣ; mono_natΣ; ghost_varΣ (list u64); urpcregΣ].

Definition configHost : chan := U64 10.

Lemma kv_pb_boot :
  ∀ σconfig σsrv1 σsrv2 (g : goose_lang.global_state),
  (* *)
  ffi_initgP g.(global_world) →

  ffi_initP σconfig.(world) g.(global_world) →
  ffi_initP σsrv1.(world) g.(global_world) →
  ffi_initP σsrv2.(world) g.(global_world) →
  (*
  g.(global_world).(grove_net) !! shardId = Some (∅ : gset message) →
  g.(global_world).(grove_net) !! coordId = Some (∅ : gset message) → *)
  grove_dist_adequate
    [ {| init_thread := config_main #() ; init_restart := of_val #(); init_local_state := σconfig |}]
    [(kv_replica_main1 #(), σsrv1); (kv_replica_main2 #(), σsrv2)] g (λ _, True).
Proof.
  intros ????.
  intros Hinitg Hinitconfig Hinitr1 Hinitr2.
  eapply (grove_ffi_dist_adequacy (kv_pbΣ)).
  { assumption. }
  { repeat constructor; naive_solver. }

  intros Hheap.
  iIntros "Hchan".
  iSplitR ""; last first.
  { iModIntro. iMod (fupd_mask_subseteq ∅); eauto. }

  (* TODO: initialize ghost state, including RPC stuff *)

  iMod (config_ghost_init) as (γconf) "HconfInit".
  iMod (config_server_init configHost γconf with "[]") as "#HisConf".
  { admit. }

  iModIntro.
  simpl. iSplitL "HconfInit".
  {
    iIntros (HL) "Hfiles".
    iModIntro.
    iExists (λ _, True%I), (λ _, True%I), (λ _ _, True%I).
    set (hG' := HeapGS _ _ _). (* overcome impedence mismatch between heapGS (bundled) and gooseGLobalGS+gooseLocalGS (split) proofs *)
    iApply (idempotence_wpr with "[HconfInit] []").
    {
      instantiate (1:=λ _, True%I).
      simpl.
      iApply wp_wpc.
      wp_call.
      iDestruct "HconfInit" as "(H1 & H2 & _)".
      wp_apply (config_proof.wp_MakeServer with "[H1 H2]").
      {
        iFrame.
      }
      iIntros (?) "#Hisconf_server".
      wp_apply (config_proof.wp_Server__Serve with "[$]").
      { iFrame "#". }
      wp_pures.
      by iModIntro.
    }
    { (* crash; there should actually be no crashes *)
      iModIntro.
      iIntros.
      iModIntro.
      admit.
    }
  }
  (* other servers remain *)
Admitted.

Print Assumptions kv_pb_boot.

End closed.
