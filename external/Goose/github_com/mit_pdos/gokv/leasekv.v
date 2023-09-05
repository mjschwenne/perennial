(* autogenerated from github.com/mit-pdos/gokv/leasekv *)
From Perennial.goose_lang Require Import prelude.
From Goose Require github_com.mit_pdos.gokv.kv.
From Goose Require github_com.tchajed.marshal.

From Perennial.goose_lang Require Import ffi.grove_prelude.

Definition cacheValue := struct.decl [
  "v" :: stringT;
  "l" :: uint64T
].

Definition LeaseKv := struct.decl [
  "kv" :: ptrT;
  "mu" :: ptrT;
  "cache" :: mapT (struct.t cacheValue)
].

Definition DecodeValue: val :=
  rec: "DecodeValue" "v" :=
    let: "e" := ref_to (slice.T byteT) (StringToBytes "v") in
    let: ("l", "vBytes") := marshal.ReadInt (![slice.T byteT] "e") in
    struct.mk cacheValue [
      "l" ::= "l";
      "v" ::= StringFromBytes "vBytes"
    ].

Definition EncodeValue: val :=
  rec: "EncodeValue" "c" :=
    let: "e" := ref_to (slice.T byteT) (NewSlice byteT #0) in
    "e" <-[slice.T byteT] (marshal.WriteInt (![slice.T byteT] "e") (struct.get cacheValue "l" "c"));;
    "e" <-[slice.T byteT] (marshal.WriteBytes (![slice.T byteT] "e") (StringToBytes (struct.get cacheValue "v" "c")));;
    StringFromBytes (![slice.T byteT] "e").

Definition max: val :=
  rec: "max" "a" "b" :=
    (if: "a" > "b"
    then "a"
    else "b").

Definition Make: val :=
  rec: "Make" "kv" :=
    struct.new LeaseKv [
      "kv" ::= "kv";
      "mu" ::= lock.new #();
      "cache" ::= NewMap stringT (struct.t cacheValue) #()
    ].

Definition LeaseKv__Get: val :=
  rec: "LeaseKv__Get" "k" "key" :=
    lock.acquire (struct.loadF LeaseKv "mu" "k");;
    let: ("cv", "ok") := MapGet (struct.loadF LeaseKv "cache" "k") "key" in
    let: (<>, "high") := grove_ffi.GetTimeRange #() in
    (if: "ok" && ("high" < (struct.get cacheValue "l" "cv"))
    then
      lock.release (struct.loadF LeaseKv "mu" "k");;
      struct.get cacheValue "v" "cv"
    else
      MapDelete (struct.loadF LeaseKv "cache" "k") "key";;
      lock.release (struct.loadF LeaseKv "mu" "k");;
      struct.get cacheValue "v" (DecodeValue ((struct.loadF kv.Kv "Get" (struct.loadF LeaseKv "kv" "k")) "key"))).

Definition LeaseKv__GetAndCache: val :=
  rec: "LeaseKv__GetAndCache" "k" "key" "cachetime" :=
    Skip;;
    (for: (λ: <>, #true); (λ: <>, Skip) := λ: <>,
      let: "enc" := (struct.loadF kv.Kv "Get" (struct.loadF LeaseKv "kv" "k")) "key" in
      let: "old" := DecodeValue "enc" in
      let: (<>, "latest") := grove_ffi.GetTimeRange #() in
      let: "newLeaseExpiration" := max ("latest" + "cachetime") (struct.get cacheValue "l" "old") in
      let: "resp" := (struct.loadF kv.Kv "ConditionalPut" (struct.loadF LeaseKv "kv" "k")) "key" "enc" (EncodeValue (struct.mk cacheValue [
        "v" ::= struct.get cacheValue "v" "old";
        "l" ::= "newLeaseExpiration"
      ])) in
      (if: "resp" = #(str"ok")
      then
        lock.acquire (struct.loadF LeaseKv "mu" "k");;
        MapInsert (struct.loadF LeaseKv "cache" "k") "key" (struct.mk cacheValue [
          "v" ::= struct.get cacheValue "v" "old";
          "l" ::= "newLeaseExpiration"
        ]);;
        Break
      else Continue));;
    let: "ret" := struct.get cacheValue "v" (Fst (MapGet (struct.loadF LeaseKv "cache" "k") "key")) in
    lock.release (struct.loadF LeaseKv "mu" "k");;
    "ret".

Definition LeaseKv__Put: val :=
  rec: "LeaseKv__Put" "k" "key" "val" :=
    Skip;;
    (for: (λ: <>, #true); (λ: <>, Skip) := λ: <>,
      let: "enc" := (struct.loadF kv.Kv "Get" (struct.loadF LeaseKv "kv" "k")) "key" in
      let: "leaseExpiration" := struct.get cacheValue "l" (DecodeValue "enc") in
      let: ("earliest", <>) := grove_ffi.GetTimeRange #() in
      (if: "leaseExpiration" > "earliest"
      then Continue
      else
        let: "resp" := (struct.loadF kv.Kv "ConditionalPut" (struct.loadF LeaseKv "kv" "k")) "key" "enc" (EncodeValue (struct.mk cacheValue [
          "v" ::= "val";
          "l" ::= #0
        ])) in
        (if: "resp" = #(str"ok")
        then Break
        else Continue)));;
    #().
