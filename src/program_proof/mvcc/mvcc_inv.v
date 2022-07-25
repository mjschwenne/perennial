From Perennial.program_proof Require Export grove_prelude.
From Perennial.program_proof.mvcc Require Import mvcc_ghost proph_proof.

(* Invariant namespaces. *)
Definition mvccN := nroot.
Definition mvccNTuple := nroot .@ "tuple".
Definition mvccNGC := nroot .@ "gc".
Definition mvccNSST := nroot .@ "sst".

Section def.
Context `{!heapGS Σ, !mvcc_ghostG Σ}.

(* GC invariants. *)
Definition mvcc_inv_gc_def γ : iProp Σ :=
  [∗ list] sid ∈ sids_all,
    ∃ (tids : gmap u64 unit) (tidmin : u64),
      site_active_tids_half_auth γ sid tids ∗
      site_min_tid_half_auth γ sid (int.nat tidmin) ∗
      ∀ tid, ⌜tid ∈ (dom tids) -> (int.nat tidmin) ≤ (int.nat tid)⌝.

Definition mvcc_inv_gc γ : iProp Σ :=
  inv mvccNGC (mvcc_inv_gc_def γ).

(* SST invariants. *)
(* TODO *)
Definition ptuple_past_rel (key : u64) (phys : list dbval) (past : list action) :=
  True.

Definition per_key_inv_def
           (γ : mvcc_names) (key : u64) (tmods : gset (u64 * dbmap))
           (m : dbmap) (past : list action)
  : iProp Σ :=
  ∃ (phys logi : list dbval),
    "Hptuple" ∷ ptuple_auth γ (1 / 2) key phys ∗
    "Hltuple" ∷ ltuple_auth γ key logi ∗
    "%Htmrel" ∷ ⌜tuple_mods_rel phys logi (per_tuple_mods tmods key)⌝ ∗
    "%Hpprel" ∷ ⌜ptuple_past_rel key phys past⌝ ∗
    "%Hlmrel" ∷ ⌜last logi = m !! key⌝.

Definition cmt_inv_def
           (γ : mvcc_names) (tmods : gset (u64 * dbmap)) (future : list action)
  : iProp Σ :=
  "HcmtAuth" ∷ commit_tmods_auth γ tmods ∗
  "%Hcmt"    ∷ ⌜set_Forall (uncurry (first_commit_compatible future)) tmods⌝.

Definition nca_inv_def (γ : mvcc_names) (future : list action) : iProp Σ :=
  ∃ (tids_nca : gset u64),
    "HncaAuth" ∷ nca_tids_auth γ tids_nca ∗
    "%Hnca"    ∷ ⌜set_Forall (no_commit_abort future) tids_nca⌝.

Definition fa_inv_def (γ : mvcc_names) (future : list action) : iProp Σ :=
  ∃ (tids_fa : gset u64),
    "HfaAuth" ∷ fa_tids_auth γ tids_fa ∗
    "%Hfa"    ∷ ⌜set_Forall (first_abort future) tids_fa⌝.

Definition fci_inv_def (γ : mvcc_names) (past future : list action) : iProp Σ :=
  ∃ (tmods_fci : gset (u64 * dbmap)),
    "HfciAuth" ∷ fci_tmods_auth γ tmods_fci ∗
    "%Hfci"    ∷ ⌜set_Forall (uncurry (first_commit_incompatible (past ++ future))) tmods_fci⌝.

Definition fcc_inv_def (γ : mvcc_names) (future : list action) : iProp Σ :=
  ∃ (tmods_fcc : gset (u64 * dbmap)),
    "HfccAuth" ∷ fcc_tmods_auth γ tmods_fcc ∗
    "%Hfcc"    ∷ ⌜set_Forall (uncurry (first_commit_compatible future)) tmods_fcc⌝.

Definition mvcc_inv_sst_def γ p : iProp Σ :=
  ∃ (tmods : gset (u64 * dbmap)) (m : dbmap) (past future : list action),
    (* Prophcy. *)
    "Hproph" ∷ mvcc_proph γ p future ∗
    (* Global database map, i.e., auth element of the global ptsto. *)
    "Hm" ∷ dbmap_auth γ m ∗
    (* Per-key invariants. *)
    "Hkeys" ∷ ([∗ set] key ∈ keys_all, per_key_inv_def γ key tmods m past) ∗
    (* Ok txns. *)
    "Hcmt"  ∷ cmt_inv_def γ tmods future ∗
    (* Doomed txns. *)
    "Hnca"  ∷ nca_inv_def γ future ∗
    "Hfa"   ∷ fa_inv_def  γ future ∗
    "Hfci"  ∷ fci_inv_def γ past future ∗
    "Hfcc"  ∷ fcc_inv_def γ future.

Instance mvcc_inv_sst_timeless γ p :
  Timeless (mvcc_inv_sst_def γ p).
Proof. unfold mvcc_inv_sst_def. apply _. Defined.

Definition mvcc_inv_sst γ p : iProp Σ :=
  inv mvccNSST (mvcc_inv_sst_def γ p).

End def.

Section theorem.
Context `{!heapGS Σ, !mvcc_ghostG Σ}.

Theorem active_ge_min γ (tid tidlb : u64) (sid : u64) :
  mvcc_inv_gc_def γ -∗
  active_tid γ tid sid -∗
  min_tid_lb γ (int.nat tidlb) -∗
  ⌜int.Z tidlb ≤ int.Z tid⌝.
Proof using heapGS0 mvcc_ghostG0 Σ.
  (* Q: How to remove [using]? *)
  iIntros "Hinv Hactive Hlb".
  iDestruct "Hactive" as "[[Htid %Hlookup] _]".
  apply sids_all_lookup in Hlookup.
  apply elem_of_list_lookup_2 in Hlookup.
  iDestruct (big_sepL_elem_of with "Hlb") as "Htidlb"; first done.
  iDestruct (big_sepL_elem_of with "Hinv") as (tids tidmin) "(Htids & Htidmin & %Hle)"; first done.
  (* Obtaining [tidmin ≤ tid]. *)
  iDestruct (site_active_tids_elem_of with "Htids Htid") as "%Helem".
  apply Hle in Helem.
  (* Obtaining [tidlb ≤ tidmin]. *)
  iDestruct (site_min_tid_valid with "Htidmin Htidlb") as "%Hle'".
  iPureIntro.
  apply Z.le_trans with (int.Z tidmin); word.
Qed.

End theorem.