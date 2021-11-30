(* autogenerated from github.com/mit-pdos/go-journal/buf *)
From Perennial.goose_lang Require Import prelude.
From Perennial.goose_lang Require Import ffi.disk_prelude.

From Goose Require github_com.mit_pdos.go_journal.addr.
From Goose Require github_com.mit_pdos.go_journal.common.
From Goose Require github_com.mit_pdos.go_journal.util.
From Goose Require github_com.tchajed.marshal.

(* buf.go *)

(* buf manages sub-block disk objects, to be packed into disk blocks *)

(* A Buf is a write to a disk object (inode, a bitmap bit, or disk block) *)
Definition Buf := struct.decl [
  "Addr" :: struct.t addr.Addr;
  "Sz" :: uint64T;
  "Data" :: slice.T byteT;
  "dirty" :: boolT
].

Definition MkBuf: val :=
  rec: "MkBuf" "addr" "sz" "data" :=
    let: "b" := struct.new Buf [
      "Addr" ::= "addr";
      "Sz" ::= "sz";
      "Data" ::= "data";
      "dirty" ::= #false
    ] in
    "b".

(* Load the bits of a disk block into a new buf, as specified by addr *)
Definition MkBufLoad: val :=
  rec: "MkBufLoad" "addr" "sz" "blk" :=
    let: "bytefirst" := (struct.get addr.Addr "Off" "addr") `quot` #8 in
    let: "bytelast" := (struct.get addr.Addr "Off" "addr" + "sz" - #1) `quot` #8 in
    let: "data" := SliceSubslice byteT "blk" "bytefirst" ("bytelast" + #1) in
    let: "b" := struct.new Buf [
      "Addr" ::= "addr";
      "Sz" ::= "sz";
      "Data" ::= "data";
      "dirty" ::= #false
    ] in
    "b".

(* Install 1 bit from src into dst, at offset bit. return new dst. *)
Definition installOneBit: val :=
  rec: "installOneBit" "src" "dst" "bit" :=
    let: "new" := ref_to byteT "dst" in
    (if: ("src" `and` (#(U8 1)) ≪ "bit") ≠ ("dst" `and` (#(U8 1)) ≪ "bit")
    then
      (if: ("src" `and` (#(U8 1)) ≪ "bit") = #(U8 0)
      then "new" <-[byteT] (![byteT] "new" `and` ~ ((#(U8 1)) ≪ "bit"))
      else "new" <-[byteT] ![byteT] "new" `or` (#(U8 1)) ≪ "bit")
    else #());;
    ![byteT] "new".

(* Install bit from src to dst, at dstoff in destination. dstoff is in bits. *)
Definition installBit: val :=
  rec: "installBit" "src" "dst" "dstoff" :=
    let: "dstbyte" := "dstoff" `quot` #8 in
    SliceSet byteT "dst" "dstbyte" (installOneBit (SliceGet byteT "src" #0) (SliceGet byteT "dst" "dstbyte") ("dstoff" `rem` #8));;
    #().

(* Install bytes from src to dst. *)
Definition installBytes: val :=
  rec: "installBytes" "src" "dst" "dstoff" "nbit" :=
    let: "sz" := "nbit" `quot` #8 in
    SliceCopy byteT (SliceSkip byteT "dst" ("dstoff" `quot` #8)) (SliceTake "src" "sz");;
    #().

(* Install the bits from buf into blk.  Two cases: a bit or an inode *)
Definition Buf__Install: val :=
  rec: "Buf__Install" "buf" "blk" :=
    util.DPrintf #5 (#(str"%v: install
    ")) #();;
    (if: (struct.loadF Buf "Sz" "buf" = #1)
    then installBit (struct.loadF Buf "Data" "buf") "blk" (struct.get addr.Addr "Off" (struct.loadF Buf "Addr" "buf"))
    else
      (if: ((struct.loadF Buf "Sz" "buf") `rem` #8 = #0) && ((struct.get addr.Addr "Off" (struct.loadF Buf "Addr" "buf")) `rem` #8 = #0)
      then installBytes (struct.loadF Buf "Data" "buf") "blk" (struct.get addr.Addr "Off" (struct.loadF Buf "Addr" "buf")) (struct.loadF Buf "Sz" "buf")
      else
        Panic ("Install unsupported
        ")));;
    util.DPrintf #20 (#(str"install -> %v
    ")) #();;
    #().

Definition Buf__IsDirty: val :=
  rec: "Buf__IsDirty" "buf" :=
    struct.loadF Buf "dirty" "buf".

Definition Buf__SetDirty: val :=
  rec: "Buf__SetDirty" "buf" :=
    struct.storeF Buf "dirty" "buf" #true;;
    #().

Definition Buf__WriteDirect: val :=
  rec: "Buf__WriteDirect" "buf" "d" :=
    Buf__SetDirty "buf";;
    (if: (struct.loadF Buf "Sz" "buf" = disk.BlockSize)
    then
      disk.Write (struct.get addr.Addr "Blkno" (struct.loadF Buf "Addr" "buf")) (struct.loadF Buf "Data" "buf");;
      #()
    else
      let: "blk" := disk.Read (struct.get addr.Addr "Blkno" (struct.loadF Buf "Addr" "buf")) in
      Buf__Install "buf" "blk";;
      disk.Write (struct.get addr.Addr "Blkno" (struct.loadF Buf "Addr" "buf")) "blk";;
      #()).

Definition Buf__BnumGet: val :=
  rec: "Buf__BnumGet" "buf" "off" :=
    let: "dec" := marshal.NewDec (SliceSubslice byteT (struct.loadF Buf "Data" "buf") "off" ("off" + #8)) in
    marshal.Dec__GetInt "dec".

Definition Buf__BnumPut: val :=
  rec: "Buf__BnumPut" "buf" "off" "v" :=
    let: "enc" := marshal.NewEnc #8 in
    marshal.Enc__PutInt "enc" "v";;
    SliceCopy byteT (SliceSubslice byteT (struct.loadF Buf "Data" "buf") "off" ("off" + #8)) (marshal.Enc__Finish "enc");;
    Buf__SetDirty "buf";;
    #().

(* bufmap.go *)

Definition BufMap := struct.decl [
  "addrs" :: mapT ptrT
].

Definition MkBufMap: val :=
  rec: "MkBufMap" <> :=
    let: "a" := struct.new BufMap [
      "addrs" ::= NewMap ptrT #()
    ] in
    "a".

Definition BufMap__Insert: val :=
  rec: "BufMap__Insert" "bmap" "buf" :=
    MapInsert (struct.loadF BufMap "addrs" "bmap") (addr.Addr__Flatid (struct.loadF Buf "Addr" "buf")) "buf";;
    #().

Definition BufMap__Lookup: val :=
  rec: "BufMap__Lookup" "bmap" "addr" :=
    Fst (MapGet (struct.loadF BufMap "addrs" "bmap") (addr.Addr__Flatid "addr")).

Definition BufMap__Del: val :=
  rec: "BufMap__Del" "bmap" "addr" :=
    MapDelete (struct.loadF BufMap "addrs" "bmap") (addr.Addr__Flatid "addr");;
    #().

Definition BufMap__Ndirty: val :=
  rec: "BufMap__Ndirty" "bmap" :=
    MapLen (struct.loadF BufMap "addrs" "bmap");;
    let: "n" := ref_to uint64T #0 in
    MapIter (struct.loadF BufMap "addrs" "bmap") (λ: <> "buf",
      (if: struct.loadF Buf "dirty" "buf"
      then "n" <-[uint64T] ![uint64T] "n" + #1
      else #()));;
    ![uint64T] "n".

Definition BufMap__DirtyBufs: val :=
  rec: "BufMap__DirtyBufs" "bmap" :=
    let: "bufs" := ref (zero_val (slice.T ptrT)) in
    MapIter (struct.loadF BufMap "addrs" "bmap") (λ: <> "buf",
      (if: struct.loadF Buf "dirty" "buf"
      then "bufs" <-[slice.T ptrT] SliceAppend ptrT (![slice.T ptrT] "bufs") "buf"
      else #()));;
    ![slice.T ptrT] "bufs".
