(* autogenerated from github.com/mit-pdos/gokv/asyncfile *)
From New.golang Require Import defn.
From New.code Require github_com.goose_lang.std.
From New.code Require github_com.mit_pdos.gokv.grove_ffi.
From New.code Require sync.

From New Require Import grove_prelude.

Definition AsyncFile : go_type := structT [
  "mu" :: ptrT;
  "data" :: sliceT byteT;
  "filename" :: stringT;
  "index" :: uint64T;
  "indexCond" :: ptrT;
  "durableIndex" :: uint64T;
  "durableIndexCond" :: ptrT;
  "closeRequested" :: boolT;
  "closed" :: boolT;
  "closedCond" :: ptrT
].

Definition AsyncFile__wait : val :=
  rec: "AsyncFile__wait" "s" "index" :=
    exception_do (let: "s" := ref_ty ptrT "s" in
    let: "index" := ref_ty uint64T "index" in
    do:  (sync.Mutex__Lock (![ptrT] (struct.field_ref AsyncFile "mu" (![ptrT] "s")))) #();;;
    (for: (λ: <>, (![uint64T] (struct.field_ref AsyncFile "durableIndex" (![ptrT] "s"))) < (![uint64T] "index")); (λ: <>, Skip) := λ: <>,
      do:  (sync.Cond__Wait (![ptrT] (struct.field_ref AsyncFile "durableIndexCond" (![ptrT] "s")))) #();;;
      do:  #());;;
    do:  (sync.Mutex__Unlock (![ptrT] (struct.field_ref AsyncFile "mu" (![ptrT] "s")))) #();;;
    do:  #()).

Definition AsyncFile__Write : val :=
  rec: "AsyncFile__Write" "s" "data" :=
    exception_do (let: "s" := ref_ty ptrT "s" in
    let: "data" := ref_ty (sliceT byteT) "data" in
    do:  (sync.Mutex__Lock (![ptrT] (struct.field_ref AsyncFile "mu" (![ptrT] "s")))) #();;;
    let: "$a0" := ![sliceT byteT] "data" in
    do:  (struct.field_ref AsyncFile "data" (![ptrT] "s")) <-[sliceT byteT] "$a0";;;
    let: "$a0" := std.SumAssumeNoOverflow (![uint64T] (struct.field_ref AsyncFile "index" (![ptrT] "s"))) #1 in
    do:  (struct.field_ref AsyncFile "index" (![ptrT] "s")) <-[uint64T] "$a0";;;
    let: "index" := ref_ty uint64T (zero_val uint64T) in
    let: "$a0" := ![uint64T] (struct.field_ref AsyncFile "index" (![ptrT] "s")) in
    do:  "index" <-[uint64T] "$a0";;;
    do:  (sync.Cond__Signal (![ptrT] (struct.field_ref AsyncFile "indexCond" (![ptrT] "s")))) #();;;
    do:  (sync.Mutex__Unlock (![ptrT] (struct.field_ref AsyncFile "mu" (![ptrT] "s")))) #();;;
    return: ((λ: <>,
       do:  (AsyncFile__wait (![ptrT] "s")) (![uint64T] "index");;;
       do:  #()
       ));;;
    do:  #()).

Definition AsyncFile__flushThread : val :=
  rec: "AsyncFile__flushThread" "s" <> :=
    exception_do (let: "s" := ref_ty ptrT "s" in
    do:  (sync.Mutex__Lock (![ptrT] (struct.field_ref AsyncFile "mu" (![ptrT] "s")))) #();;;
    (for: (λ: <>, #true); (λ: <>, Skip) := λ: <>,
      (if: ![boolT] (struct.field_ref AsyncFile "closeRequested" (![ptrT] "s"))
      then
        do:  grove_ffi.FileWrite (![stringT] (struct.field_ref AsyncFile "filename" (![ptrT] "s"))) (![sliceT byteT] (struct.field_ref AsyncFile "data" (![ptrT] "s")));;;
        let: "$a0" := ![uint64T] (struct.field_ref AsyncFile "index" (![ptrT] "s")) in
        do:  (struct.field_ref AsyncFile "durableIndex" (![ptrT] "s")) <-[uint64T] "$a0";;;
        do:  (sync.Cond__Broadcast (![ptrT] (struct.field_ref AsyncFile "durableIndexCond" (![ptrT] "s")))) #();;;
        let: "$a0" := #true in
        do:  (struct.field_ref AsyncFile "closed" (![ptrT] "s")) <-[boolT] "$a0";;;
        do:  (sync.Mutex__Unlock (![ptrT] (struct.field_ref AsyncFile "mu" (![ptrT] "s")))) #();;;
        do:  (sync.Cond__Signal (![ptrT] (struct.field_ref AsyncFile "closedCond" (![ptrT] "s")))) #();;;
        return: (#());;;
        do:  #()
      else do:  #());;;
      (if: (![uint64T] (struct.field_ref AsyncFile "durableIndex" (![ptrT] "s"))) ≥ (![uint64T] (struct.field_ref AsyncFile "index" (![ptrT] "s")))
      then
        do:  (sync.Cond__Wait (![ptrT] (struct.field_ref AsyncFile "indexCond" (![ptrT] "s")))) #();;;
        continue: #();;;
        do:  #()
      else do:  #());;;
      let: "index" := ref_ty uint64T (zero_val uint64T) in
      let: "$a0" := ![uint64T] (struct.field_ref AsyncFile "index" (![ptrT] "s")) in
      do:  "index" <-[uint64T] "$a0";;;
      let: "data" := ref_ty (sliceT byteT) (zero_val (sliceT byteT)) in
      let: "$a0" := ![sliceT byteT] (struct.field_ref AsyncFile "data" (![ptrT] "s")) in
      do:  "data" <-[sliceT byteT] "$a0";;;
      do:  (sync.Mutex__Unlock (![ptrT] (struct.field_ref AsyncFile "mu" (![ptrT] "s")))) #();;;
      do:  grove_ffi.FileWrite (![stringT] (struct.field_ref AsyncFile "filename" (![ptrT] "s"))) (![sliceT byteT] "data");;;
      do:  (sync.Mutex__Lock (![ptrT] (struct.field_ref AsyncFile "mu" (![ptrT] "s")))) #();;;
      let: "$a0" := ![uint64T] "index" in
      do:  (struct.field_ref AsyncFile "durableIndex" (![ptrT] "s")) <-[uint64T] "$a0";;;
      do:  (sync.Cond__Broadcast (![ptrT] (struct.field_ref AsyncFile "durableIndexCond" (![ptrT] "s")))) #();;;
      do:  #());;;
    do:  #()).

Definition AsyncFile__Close : val :=
  rec: "AsyncFile__Close" "s" <> :=
    exception_do (let: "s" := ref_ty ptrT "s" in
    do:  (sync.Mutex__Lock (![ptrT] (struct.field_ref AsyncFile "mu" (![ptrT] "s")))) #();;;
    let: "$a0" := #true in
    do:  (struct.field_ref AsyncFile "closeRequested" (![ptrT] "s")) <-[boolT] "$a0";;;
    do:  (sync.Cond__Signal (![ptrT] (struct.field_ref AsyncFile "indexCond" (![ptrT] "s")))) #();;;
    (for: (λ: <>, (~ (![boolT] (struct.field_ref AsyncFile "closed" (![ptrT] "s"))))); (λ: <>, Skip) := λ: <>,
      do:  (sync.Cond__Wait (![ptrT] (struct.field_ref AsyncFile "closedCond" (![ptrT] "s")))) #();;;
      do:  #());;;
    do:  (sync.Mutex__Unlock (![ptrT] (struct.field_ref AsyncFile "mu" (![ptrT] "s")))) #();;;
    do:  #()).

(* returns the state, then the File object *)
Definition MakeAsyncFile : val :=
  rec: "MakeAsyncFile" "filename" :=
    exception_do (let: "filename" := ref_ty stringT "filename" in
    let: "mu" := ref_ty sync.Mutex (zero_val sync.Mutex) in
    let: "s" := ref_ty ptrT (zero_val ptrT) in
    let: "$a0" := ref_ty AsyncFile (struct.make AsyncFile {[
      #(str "mu") := "mu";
      #(str "indexCond") := sync.NewCond "mu";
      #(str "closedCond") := sync.NewCond "mu";
      #(str "durableIndexCond") := sync.NewCond "mu";
      #(str "filename") := ![stringT] "filename";
      #(str "data") := grove_ffi.FileRead (![stringT] "filename");
      #(str "index") := #0;
      #(str "durableIndex") := #0;
      #(str "closed") := #false;
      #(str "closeRequested") := #false
    ]}) in
    do:  "s" <-[ptrT] "$a0";;;
    let: "data" := ref_ty (sliceT byteT) (zero_val (sliceT byteT)) in
    let: "$a0" := ![sliceT byteT] (struct.field_ref AsyncFile "data" (![ptrT] "s")) in
    do:  "data" <-[sliceT byteT] "$a0";;;
    do:  let: "$go" := AsyncFile__flushThread (![ptrT] "s") in
    Fork ("$go" #());;;
    return: (![sliceT byteT] "data", ![ptrT] "s");;;
    do:  #()).
