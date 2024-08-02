(* autogenerated from github.com/mit-pdos/gokv/bank *)
From New.golang Require Import defn.
From New.code Require github_com.goose_lang.primitive.
From New.code Require github_com.mit_pdos.gokv.kv.
From New.code Require github_com.mit_pdos.gokv.lockservice.
From New.code Require github_com.tchajed.marshal.

Section code.
Context `{ffi_syntax}.
Local Coercion Var' s: expr := Var s.

Definition BAL_TOTAL : expr := #1000.

Definition BankClerk : go_type := structT [
  "lck" :: ptrT;
  "kvck" :: kv.Kv;
  "accts" :: sliceT stringT
].

Definition BankClerk__mset : list (string * val) := [
].

(* go: bank.go:47:6 *)
Definition decodeInt : val :=
  rec: "decodeInt" "a" :=
    exception_do (let: "a" := ref_ty stringT "a" in
    let: <> := ref_ty (sliceT byteT) (zero_val (sliceT byteT)) in
    let: "v" := ref_ty uint64T (zero_val uint64T) in
    let: ("$ret0", "$ret1") := let: "$a0" := string.to_bytes (![stringT] "a") in
    marshal.ReadInt "$a0" in
    let: "$r0" := "$ret0" in
    let: "$r1" := "$ret1" in
    do:  ("v" <-[uint64T] "$r0");;;
    do:  "$r1";;;
    return: (![uint64T] "v");;;
    do:  #()).

(* go: bank.go:76:23 *)
Definition BankClerk__get_total : val :=
  rec: "BankClerk__get_total" "bck" <> :=
    exception_do (let: "bck" := ref_ty ptrT "bck" in
    let: "sum" := ref_ty uint64T (zero_val uint64T) in
    do:  (let: "$range" := ![sliceT stringT] (struct.field_ref BankClerk "accts" (![ptrT] "bck")) in
    slice.for_range stringT "$range" (λ: <> "acct",
      let: "acct" := ref_ty stringT "acct" in
      do:  (let: "$a0" := ![stringT] "acct" in
      (lockservice.LockClerk__Lock (![ptrT] (struct.field_ref BankClerk "lck" (![ptrT] "bck")))) "$a0");;;
      let: "$r0" := (![uint64T] "sum") + (let: "$a0" := let: "$a0" := ![stringT] "acct" in
      (interface.get "Get" (![kv.Kv] (struct.field_ref BankClerk "kvck" (![ptrT] "bck")))) "$a0" in
      decodeInt "$a0") in
      do:  ("sum" <-[uint64T] "$r0");;;
      do:  #()));;;
    do:  (let: "$range" := ![sliceT stringT] (struct.field_ref BankClerk "accts" (![ptrT] "bck")) in
    slice.for_range stringT "$range" (λ: <> "acct",
      let: "acct" := ref_ty stringT "acct" in
      do:  (let: "$a0" := ![stringT] "acct" in
      (lockservice.LockClerk__Unlock (![ptrT] (struct.field_ref BankClerk "lck" (![ptrT] "bck")))) "$a0");;;
      do:  #()));;;
    return: (![uint64T] "sum");;;
    do:  #()).

(* go: bank.go:92:23 *)
Definition BankClerk__SimpleAudit : val :=
  rec: "BankClerk__SimpleAudit" "bck" <> :=
    exception_do (let: "bck" := ref_ty ptrT "bck" in
    (for: (λ: <>, #true); (λ: <>, Skip) := λ: <>,
      (if: ((BankClerk__get_total (![ptrT] "bck")) #()) ≠ BAL_TOTAL
      then
        do:  (Panic "Balance total invariant violated");;;
        do:  #()
      else do:  #());;;
      do:  #());;;
    do:  #()).

(* go: bank.go:37:6 *)
Definition release_two : val :=
  rec: "release_two" "lck" "l1" "l2" :=
    exception_do (let: "l2" := ref_ty stringT "l2" in
    let: "l1" := ref_ty stringT "l1" in
    let: "lck" := ref_ty ptrT "lck" in
    do:  (let: "$a0" := ![stringT] "l1" in
    (lockservice.LockClerk__Unlock (![ptrT] "lck")) "$a0");;;
    do:  (let: "$a0" := ![stringT] "l2" in
    (lockservice.LockClerk__Unlock (![ptrT] "lck")) "$a0");;;
    return: (#());;;
    do:  #()).

(* go: bank.go:43:6 *)
Definition encodeInt : val :=
  rec: "encodeInt" "a" :=
    exception_do (let: "a" := ref_ty uint64T "a" in
    return: (string.from_bytes (let: "$a0" := slice.nil in
     let: "$a1" := ![uint64T] "a" in
     marshal.WriteInt "$a0" "$a1"));;;
    do:  #()).

(* go: bank.go:30:6 *)
Definition acquire_two : val :=
  rec: "acquire_two" "lck" "l1" "l2" :=
    exception_do (let: "l2" := ref_ty stringT "l2" in
    let: "l1" := ref_ty stringT "l1" in
    let: "lck" := ref_ty ptrT "lck" in
    do:  (let: "$a0" := ![stringT] "l1" in
    (lockservice.LockClerk__Lock (![ptrT] "lck")) "$a0");;;
    do:  (let: "$a0" := ![stringT] "l2" in
    (lockservice.LockClerk__Lock (![ptrT] "lck")) "$a0");;;
    return: (#());;;
    do:  #()).

(* Requires that the account numbers are smaller than num_accounts
   If account balance in acc_from is at least amount, transfer amount to acc_to

   go: bank.go:54:23 *)
Definition BankClerk__transfer_internal : val :=
  rec: "BankClerk__transfer_internal" "bck" "acc_from" "acc_to" "amount" :=
    exception_do (let: "bck" := ref_ty ptrT "bck" in
    let: "amount" := ref_ty uint64T "amount" in
    let: "acc_to" := ref_ty stringT "acc_to" in
    let: "acc_from" := ref_ty stringT "acc_from" in
    do:  (let: "$a0" := ![ptrT] (struct.field_ref BankClerk "lck" (![ptrT] "bck")) in
    let: "$a1" := ![stringT] "acc_from" in
    let: "$a2" := ![stringT] "acc_to" in
    acquire_two "$a0" "$a1" "$a2");;;
    let: "old_amount" := ref_ty uint64T (zero_val uint64T) in
    let: "$r0" := let: "$a0" := let: "$a0" := ![stringT] "acc_from" in
    (interface.get "Get" (![kv.Kv] (struct.field_ref BankClerk "kvck" (![ptrT] "bck")))) "$a0" in
    decodeInt "$a0" in
    do:  ("old_amount" <-[uint64T] "$r0");;;
    (if: (![uint64T] "old_amount") ≥ (![uint64T] "amount")
    then
      do:  (let: "$a0" := ![stringT] "acc_from" in
      let: "$a1" := let: "$a0" := (![uint64T] "old_amount") - (![uint64T] "amount") in
      encodeInt "$a0" in
      (interface.get "Put" (![kv.Kv] (struct.field_ref BankClerk "kvck" (![ptrT] "bck")))) "$a0" "$a1");;;
      do:  (let: "$a0" := ![stringT] "acc_to" in
      let: "$a1" := let: "$a0" := (let: "$a0" := let: "$a0" := ![stringT] "acc_to" in
      (interface.get "Get" (![kv.Kv] (struct.field_ref BankClerk "kvck" (![ptrT] "bck")))) "$a0" in
      decodeInt "$a0") + (![uint64T] "amount") in
      encodeInt "$a0" in
      (interface.get "Put" (![kv.Kv] (struct.field_ref BankClerk "kvck" (![ptrT] "bck")))) "$a0" "$a1");;;
      do:  #()
    else do:  #());;;
    do:  (let: "$a0" := ![ptrT] (struct.field_ref BankClerk "lck" (![ptrT] "bck")) in
    let: "$a1" := ![stringT] "acc_from" in
    let: "$a2" := ![stringT] "acc_to" in
    release_two "$a0" "$a1" "$a2");;;
    do:  #()).

(* go: bank.go:65:23 *)
Definition BankClerk__SimpleTransfer : val :=
  rec: "BankClerk__SimpleTransfer" "bck" <> :=
    exception_do (let: "bck" := ref_ty ptrT "bck" in
    (for: (λ: <>, #true); (λ: <>, Skip) := λ: <>,
      let: "src" := ref_ty uint64T (zero_val uint64T) in
      let: "$r0" := primitive.RandomUint64 #() in
      do:  ("src" <-[uint64T] "$r0");;;
      let: "dst" := ref_ty uint64T (zero_val uint64T) in
      let: "$r0" := primitive.RandomUint64 #() in
      do:  ("dst" <-[uint64T] "$r0");;;
      let: "amount" := ref_ty uint64T (zero_val uint64T) in
      let: "$r0" := primitive.RandomUint64 #() in
      do:  ("amount" <-[uint64T] "$r0");;;
      (if: (((![uint64T] "src") < (slice.len (![sliceT stringT] (struct.field_ref BankClerk "accts" (![ptrT] "bck"))))) && ((![uint64T] "dst") < (slice.len (![sliceT stringT] (struct.field_ref BankClerk "accts" (![ptrT] "bck")))))) && ((![uint64T] "src") ≠ (![uint64T] "dst"))
      then
        do:  (let: "$a0" := ![stringT] (slice.elem_ref stringT (![sliceT stringT] (struct.field_ref BankClerk "accts" (![ptrT] "bck"))) (![uint64T] "src")) in
        let: "$a1" := ![stringT] (slice.elem_ref stringT (![sliceT stringT] (struct.field_ref BankClerk "accts" (![ptrT] "bck"))) (![uint64T] "dst")) in
        let: "$a2" := ![uint64T] "amount" in
        (BankClerk__transfer_internal (![ptrT] "bck")) "$a0" "$a1" "$a2");;;
        do:  #()
      else do:  #());;;
      do:  #());;;
    do:  #()).

Definition BankClerk__mset_ptr : list (string * val) := [
  ("SimpleAudit", BankClerk__SimpleAudit);
  ("SimpleTransfer", BankClerk__SimpleTransfer);
  ("get_total", BankClerk__get_total);
  ("transfer_internal", BankClerk__transfer_internal)
].

(* go: bank.go:19:6 *)
Definition acquire_two_good : val :=
  rec: "acquire_two_good" "lck" "l1" "l2" :=
    exception_do (let: "l2" := ref_ty stringT "l2" in
    let: "l1" := ref_ty stringT "l1" in
    let: "lck" := ref_ty ptrT "lck" in
    (if: (![stringT] "l1") < (![stringT] "l2")
    then
      do:  (let: "$a0" := ![stringT] "l1" in
      (lockservice.LockClerk__Lock (![ptrT] "lck")) "$a0");;;
      do:  (let: "$a0" := ![stringT] "l2" in
      (lockservice.LockClerk__Lock (![ptrT] "lck")) "$a0");;;
      do:  #()
    else
      do:  (let: "$a0" := ![stringT] "l2" in
      (lockservice.LockClerk__Lock (![ptrT] "lck")) "$a0");;;
      do:  (let: "$a0" := ![stringT] "l1" in
      (lockservice.LockClerk__Lock (![ptrT] "lck")) "$a0");;;
      do:  #());;;
    return: (#());;;
    do:  #()).

(* go: bank.go:100:6 *)
Definition MakeBankClerkSlice : val :=
  rec: "MakeBankClerkSlice" "lck" "kv" "init_flag" "accts" :=
    exception_do (let: "accts" := ref_ty (sliceT stringT) "accts" in
    let: "init_flag" := ref_ty stringT "init_flag" in
    let: "kv" := ref_ty kv.Kv "kv" in
    let: "lck" := ref_ty ptrT "lck" in
    let: "bck" := ref_ty ptrT (zero_val ptrT) in
    let: "$r0" := ref_ty BankClerk (zero_val BankClerk) in
    do:  ("bck" <-[ptrT] "$r0");;;
    let: "$r0" := ![ptrT] "lck" in
    do:  ((struct.field_ref BankClerk "lck" (![ptrT] "bck")) <-[ptrT] "$r0");;;
    let: "$r0" := ![kv.Kv] "kv" in
    do:  ((struct.field_ref BankClerk "kvck" (![ptrT] "bck")) <-[kv.Kv] "$r0");;;
    let: "$r0" := ![sliceT stringT] "accts" in
    do:  ((struct.field_ref BankClerk "accts" (![ptrT] "bck")) <-[sliceT stringT] "$r0");;;
    do:  (let: "$a0" := ![stringT] "init_flag" in
    (lockservice.LockClerk__Lock (![ptrT] (struct.field_ref BankClerk "lck" (![ptrT] "bck")))) "$a0");;;
    (if: (let: "$a0" := ![stringT] "init_flag" in
    (interface.get "Get" (![kv.Kv] (struct.field_ref BankClerk "kvck" (![ptrT] "bck")))) "$a0") = #(str "")
    then
      do:  (let: "$a0" := ![stringT] (slice.elem_ref stringT (![sliceT stringT] (struct.field_ref BankClerk "accts" (![ptrT] "bck"))) #0) in
      let: "$a1" := let: "$a0" := BAL_TOTAL in
      encodeInt "$a0" in
      (interface.get "Put" (![kv.Kv] (struct.field_ref BankClerk "kvck" (![ptrT] "bck")))) "$a0" "$a1");;;
      do:  (let: "$range" := let: "$s" := ![sliceT stringT] (struct.field_ref BankClerk "accts" (![ptrT] "bck")) in
      slice.slice stringT "$s" #1 (slice.len "$s") in
      slice.for_range stringT "$range" (λ: <> "acct",
        let: "acct" := ref_ty stringT "acct" in
        do:  (let: "$a0" := ![stringT] "acct" in
        let: "$a1" := let: "$a0" := #0 in
        encodeInt "$a0" in
        (interface.get "Put" (![kv.Kv] (struct.field_ref BankClerk "kvck" (![ptrT] "bck")))) "$a0" "$a1");;;
        do:  #()));;;
      do:  (let: "$a0" := ![stringT] "init_flag" in
      let: "$a1" := #(str "1") in
      (interface.get "Put" (![kv.Kv] (struct.field_ref BankClerk "kvck" (![ptrT] "bck")))) "$a0" "$a1");;;
      do:  #()
    else do:  #());;;
    do:  (let: "$a0" := ![stringT] "init_flag" in
    (lockservice.LockClerk__Unlock (![ptrT] (struct.field_ref BankClerk "lck" (![ptrT] "bck")))) "$a0");;;
    return: (![ptrT] "bck");;;
    do:  #()).

(* go: bank.go:120:6 *)
Definition MakeBankClerk : val :=
  rec: "MakeBankClerk" "lck" "kv" "init_flag" "acc1" "acc2" :=
    exception_do (let: "acc2" := ref_ty stringT "acc2" in
    let: "acc1" := ref_ty stringT "acc1" in
    let: "init_flag" := ref_ty stringT "init_flag" in
    let: "kv" := ref_ty kv.Kv "kv" in
    let: "lck" := ref_ty ptrT "lck" in
    let: "accts" := ref_ty (sliceT stringT) (zero_val (sliceT stringT)) in
    let: "$r0" := slice.append stringT (![sliceT stringT] "accts") (slice.literal stringT [![stringT] "acc1"]) in
    do:  ("accts" <-[sliceT stringT] "$r0");;;
    let: "$r0" := slice.append stringT (![sliceT stringT] "accts") (slice.literal stringT [![stringT] "acc2"]) in
    do:  ("accts" <-[sliceT stringT] "$r0");;;
    return: (let: "$a0" := ![ptrT] "lck" in
     let: "$a1" := ![kv.Kv] "kv" in
     let: "$a2" := ![stringT] "init_flag" in
     let: "$a3" := ![sliceT stringT] "accts" in
     MakeBankClerkSlice "$a0" "$a1" "$a2" "$a3");;;
    do:  #()).

End code.