(* autogenerated from github.com/mit-pdos/gokv/simplepb/clerk *)
From Perennial.goose_lang Require Import prelude.
From Goose Require github_com.mit_pdos.gokv.simplepb.config.
From Goose Require github_com.mit_pdos.gokv.simplepb.e.
From Goose Require github_com.mit_pdos.gokv.simplepb.pb.

From Perennial.goose_lang Require Import ffi.grove_prelude.

Definition Clerk := struct.decl [
  "confCk" :: ptrT;
  "primaryCk" :: ptrT
].

Definition Make: val :=
  rec: "Make" "confHost" :=
    let: "ck" := struct.alloc Clerk (zero_val (struct.t Clerk)) in
    struct.storeF Clerk "confCk" "ck" (config.MakeClerk "confHost");;
    Skip;;
    (for: (λ: <>, #true); (λ: <>, Skip) := λ: <>,
      let: "config" := config.Clerk__GetConfig (struct.loadF Clerk "confCk" "ck") in
      (if: (slice.len "config" = #0)
      then Continue
      else
        struct.storeF Clerk "primaryCk" "ck" (pb.MakeClerk (SliceGet uint64T "config" #0));;
        Break));;
    "ck".

(* will retry forever *)
Definition Clerk__Apply: val :=
  rec: "Clerk__Apply" "ck" "op" :=
    let: "ret" := ref (zero_val (slice.T byteT)) in
    Skip;;
    (for: (λ: <>, #true); (λ: <>, Skip) := λ: <>,
      let: "err" := ref (zero_val uint64T) in
      let: ("0_ret", "1_ret") := pb.Clerk__Apply (struct.loadF Clerk "primaryCk" "ck") "op" in
      "err" <-[uint64T] "0_ret";;
      "ret" <-[slice.T byteT] "1_ret";;
      (if: (![uint64T] "err" = e.None)
      then Break
      else
        time.Sleep (#100 * #1000000);;
        let: "config" := config.Clerk__GetConfig (struct.loadF Clerk "confCk" "ck") in
        (if: slice.len "config" > #0
        then struct.storeF Clerk "primaryCk" "ck" (pb.MakeClerk (SliceGet uint64T "config" #0))
        else #());;
        Continue));;
    ![slice.T byteT] "ret".

Definition Clerk__ApplyRo: val :=
  rec: "Clerk__ApplyRo" "ck" "op" :=
    let: "ret" := ref (zero_val (slice.T byteT)) in
    Skip;;
    (for: (λ: <>, #true); (λ: <>, Skip) := λ: <>,
      let: "err" := ref (zero_val uint64T) in
      let: ("0_ret", "1_ret") := pb.Clerk__ApplyRo (struct.loadF Clerk "primaryCk" "ck") "op" in
      "err" <-[uint64T] "0_ret";;
      "ret" <-[slice.T byteT] "1_ret";;
      (if: (![uint64T] "err" = e.None)
      then Break
      else
        time.Sleep (#100 * #1000000);;
        let: "config" := config.Clerk__GetConfig (struct.loadF Clerk "confCk" "ck") in
        (if: slice.len "config" > #0
        then struct.storeF Clerk "primaryCk" "ck" (pb.MakeClerk (SliceGet uint64T "config" #0))
        else #());;
        Continue));;
    ![slice.T byteT] "ret".
