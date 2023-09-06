(* autogenerated from github.com/mit-pdos/gokv/simplepb/apps/closed *)
From Perennial.goose_lang Require Import prelude.
From Goose Require github_com.mit_pdos.gokv.bank.
From Goose Require github_com.mit_pdos.gokv.lockservice.
From Goose Require github_com.mit_pdos.gokv.simplepb.apps.kv.
From Goose Require github_com.mit_pdos.gokv.simplepb.config.

From Perennial.goose_lang Require Import ffi.grove_prelude.

Definition dr1 : expr := #1.

Definition dr2 : expr := #2.

Definition dconfigHost : expr := #10.

Definition lr1 : expr := #101.

Definition lr2 : expr := #102.

Definition lconfigHost : expr := #110.

Definition lconfig_main: val :=
  rec: "lconfig_main" <> :=
    let: "servers" := ref_to (slice.T uint64T) (NewSlice uint64T #0) in
    "servers" <-[slice.T uint64T] (SliceAppend uint64T (![slice.T uint64T] "servers") lr1);;
    "servers" <-[slice.T uint64T] (SliceAppend uint64T (![slice.T uint64T] "servers") lr2);;
    config.Server__Serve (config.MakeServer (![slice.T uint64T] "servers")) lconfigHost;;
    #().

Definition dconfig_main: val :=
  rec: "dconfig_main" <> :=
    let: "servers" := ref_to (slice.T uint64T) (NewSlice uint64T #0) in
    "servers" <-[slice.T uint64T] (SliceAppend uint64T (![slice.T uint64T] "servers") dr1);;
    "servers" <-[slice.T uint64T] (SliceAppend uint64T (![slice.T uint64T] "servers") dr2);;
    config.Server__Serve (config.MakeServer (![slice.T uint64T] "servers")) dconfigHost;;
    #().

Definition kv_replica_main: val :=
  rec: "kv_replica_main" "fname" "me" "configHost" :=
    let: "x" := ref (zero_val uint64T) in
    "x" <-[uint64T] #1;;
    kv.Start "fname" "me" "configHost";;
    #().

Definition makeBankClerk: val :=
  rec: "makeBankClerk" <> :=
    let: "kvck" := kv.MakeKv dconfigHost in
    let: "lck" := lockservice.MakeLockClerk (kv.MakeKv lconfigHost) in
    bank.MakeBankClerk "lck" "kvck" #(str"init") #(str"a1") #(str"a2").

Definition bank_transferer_main: val :=
  rec: "bank_transferer_main" <> :=
    let: "bck" := makeBankClerk #() in
    Skip;;
    (for: (λ: <>, #true); (λ: <>, Skip) := λ: <>,
      bank.BankClerk__SimpleTransfer "bck";;
      Continue);;
    #().

Definition bank_auditor_main: val :=
  rec: "bank_auditor_main" <> :=
    let: "bck" := makeBankClerk #() in
    Skip;;
    (for: (λ: <>, #true); (λ: <>, Skip) := λ: <>,
      bank.BankClerk__SimpleAudit "bck";;
      Continue);;
    #().
