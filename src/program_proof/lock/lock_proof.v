From Perennial.program_proof Require Import grove_prelude std_proof.
From Goose.github_com.mit_pdos.gokv Require Import lockservice.
From Perennial.program_proof.kv Require Export interface.

Section lockservice_defns.

(* KV points-to for the internal kv service *)
Context `{!gooseGlobalGS Σ}.

Record lock_names :=
  {
    kvptsto_lock : string → string → iProp Σ
  }
.
End lockservice_defns.

Section lockservice_proof.
Context `{!heapGS Σ}.
Definition lock_inv γ key R : iProp Σ :=
  ∃ b : bool, kvptsto_lock γ key (if b then "1" else "") ∗ if b then True else R.

Context (N: namespace).

Definition is_lock `{invGS Σ} γ key R :=
  inv N (lock_inv γ key R).

Lemma lock_alloc `{invGS Σ} γ E key R :
  kvptsto_lock γ key "" -∗ R ={E}=∗ is_lock γ key R.
Proof.
  iIntros "Hkv HR".
  iMod (inv_alloc _ _ (lock_inv γ key R) with "[Hkv HR]").
  { iNext. iExists false. iFrame. }
  eauto.
Qed.

Definition is_LockClerk (ck:loc) γ : iProp Σ :=
  ∃ (kvCk : loc),
    "#Hkv" ∷ readonly (ck ↦[LockClerk :: "kv"] #kvCk) ∗
    "#Hkv_is" ∷ is_Kv (kvptsto:=kvptsto_lock γ) kvCk.

Lemma wp_MakeLockClerk kvCk γ :
  {{{
        is_Kv (kvptsto:=kvptsto_lock γ) kvCk
  }}}
    MakeLockClerk #kvCk
  {{{
       (ck:loc), RET #ck; is_LockClerk ck γ
  }}}
.
Proof.
  iIntros (Φ) "#Hkv_is HΦ".
  rewrite /MakeLockClerk.
  wp_lam.
  iApply wp_fupd.
  wp_pures.
  wp_apply wp_allocStruct; first val_ty.
  iIntros (?) "Hl".
  iDestruct (struct_fields_split with "Hl") as "HH".
  iNamed "HH".
  iMod (readonly_alloc_1 with "kv") as "#Hkv".
  iApply "HΦ". iModIntro.
  repeat iExists _. iFrame "∗#".
Qed.

Lemma wp_LockClerk__Lock ck key γ R :
  {{{
       is_LockClerk ck γ ∗ is_lock γ key R
  }}}
    LockClerk__Lock #ck #(str key)
  {{{
       RET #(); R
  }}}
.
Proof.
  iIntros (Φ) "(#Hck&#Hlock) HΦ".
  wp_lam.
  wp_pures.
  wp_apply (wp_forBreak_cond' with "HΦ").
  iModIntro. iIntros "HΦ".
  wp_pure1_credit "Hlc".
  wp_pures.
  iNamed "Hck".
  wp_loadField.
  iNamed "Hkv_is".
  wp_loadField.
  wp_apply ("HcputSpec" with "[//]").
  rewrite /is_lock.
  replace (⊤ ∖ ∅) with (⊤ : coPset) by set_solver+.
  iInv "Hlock" as "Hlock_inner" "Hclo".
  iMod (lc_fupd_elim_later with "Hlc Hlock_inner") as "Hlock_inner".
  iDestruct "Hlock_inner" as (?) "(Hk&HR)".
  iApply ncfupd_mask_intro.
  { solve_ndisj. }
  iIntros "Hmask".
  iExists _. iFrame "Hk".
  iIntros "Hk".
  iMod "Hmask".
  destruct b.
  - rewrite bool_decide_false //.
    iMod ("Hclo" with "[HR Hk]").
    { iExists true. iFrame. }
    iModIntro. iIntros "Hck". wp_pures. iModIntro. iLeft.
    iSplit; first by eauto.
    iFrame "HΦ".
  - rewrite bool_decide_true //.
    iMod ("Hclo" with "[Hk]").
    { iExists true. iFrame. }
    iModIntro. iIntros "Hck". wp_pures. iModIntro. iRight.
    iSplit; first by eauto.
    wp_pures. iModIntro. iApply "HΦ". iFrame.
Qed.

Lemma wp_LockClerk__Unlock ck key γ R :
  {{{
       is_LockClerk ck γ ∗ is_lock γ key R ∗ R
  }}}
    LockClerk__Unlock #ck #(str key)
  {{{
       RET #(); True
  }}}
.
Proof.
  iIntros (Φ) "(#Hck&#Hlock&HR) HΦ".
  wp_lam.
  wp_pure1_credit "Hlc".
  iNamed "Hck".
  wp_loadField.
  iNamed "Hkv_is".
  wp_loadField.
  wp_apply ("HputSpec" with "[//]").
  rewrite /is_lock.
  replace (⊤ ∖ ∅) with (⊤ : coPset) by set_solver+.
  iInv "Hlock" as "Hlock_inner" "Hclo".
  iMod (lc_fupd_elim_later with "Hlc Hlock_inner") as "Hlock_inner".
  iDestruct "Hlock_inner" as (?) "(Hk&_)".
  iApply ncfupd_mask_intro.
  { solve_ndisj. }
  iIntros "Hmask".
  iExists _. iFrame "Hk".
  iIntros "Hk".
  iMod "Hmask".
  iMod ("Hclo" with "[HR Hk]").
  { iExists false. iFrame. }
  iModIntro. iIntros "Hck".
  wp_pures. by iApply "HΦ".
Qed.

End lockservice_proof.
