(* autogenerated from github.com/mit-pdos/gokv/goosekv *)
From Perennial.goose_lang Require Import prelude.
From Perennial.program_proof.lockservice Require Import grove_prelude.
From Goose Require github_com.mit_pdos.lockservice.lockservice.
                

From Goose Require github_com.mit_pdos.gokv.aof.
From Goose Require github_com.tchajed.marshal.

Definition ValueType: ty := uint64T.

Module GoKVServer.
  Definition S := struct.decl [
    "mu" :: lockRefT;
    "lastReply" :: mapT uint64T;
    "lastSeq" :: mapT uint64T;
    "kvs" :: mapT ValueType;
    "opLog" :: struct.ptrT aof.AppendOnlyFile.S
  ].
End GoKVServer.

Module PutArgs.
  Definition S := struct.decl [
    "Key" :: uint64T;
    "Value" :: ValueType
  ].
End PutArgs.

Definition encodeReq: val :=
  rec: "encodeReq" "optype" "args" :=
    let: "num_bytes" := #8 + #8 + #8 + #8 + #8 in
    let: "e" := marshal.NewEnc "num_bytes" in
    marshal.Enc__PutInt "e" "optype";;
    marshal.Enc__PutInt "e" (struct.loadF lockservice.RPCRequest.S "CID" "args");;
    marshal.Enc__PutInt "e" (struct.loadF lockservice.RPCRequest.S "Seq" "args");;
    marshal.Enc__PutInt "e" (struct.get lockservice.RPCVals.S "U64_1" (struct.loadF lockservice.RPCRequest.S "Args" "args"));;
    marshal.Enc__PutInt "e" (struct.get lockservice.RPCVals.S "U64_2" (struct.loadF lockservice.RPCRequest.S "Args" "args"));;
    marshal.Enc__Finish "e".

Definition GoKVServer__put_inner: val :=
  rec: "GoKVServer__put_inner" "s" "args" "reply" :=
    (if: lockservice.CheckReplyTable (struct.loadF GoKVServer.S "lastSeq" "s") (struct.loadF GoKVServer.S "lastReply" "s") (struct.loadF lockservice.RPCRequest.S "CID" "args") (struct.loadF lockservice.RPCRequest.S "Seq" "args") "reply"
    then #()
    else
      MapInsert (struct.loadF GoKVServer.S "kvs" "s") (struct.get lockservice.RPCVals.S "U64_1" (struct.loadF lockservice.RPCRequest.S "Args" "args")) (struct.get lockservice.RPCVals.S "U64_2" (struct.loadF lockservice.RPCRequest.S "Args" "args"));;
      struct.storeF lockservice.RPCReply.S "Ret" "reply" #0;;
      MapInsert (struct.loadF GoKVServer.S "lastReply" "s") (struct.loadF lockservice.RPCRequest.S "CID" "args") #0).

Definition GoKVServer__Put: val :=
  rec: "GoKVServer__Put" "s" "args" "reply" :=
    lock.acquire (struct.loadF GoKVServer.S "mu" "s");;
    GoKVServer__put_inner "s" "args" "reply";;
    let: "l" := aof.AppendOnlyFile__Append (struct.loadF GoKVServer.S "opLog" "s") (encodeReq #0 "args") in
    lock.release (struct.loadF GoKVServer.S "mu" "s");;
    aof.AppendOnlyFile__WaitAppend (struct.loadF GoKVServer.S "opLog" "s") "l";;
    #false.

Definition GoKVServer__Get: val :=
  rec: "GoKVServer__Get" "s" "args" "reply" :=
    lock.acquire (struct.loadF GoKVServer.S "mu" "s");;
    (if: lockservice.CheckReplyTable (struct.loadF GoKVServer.S "lastSeq" "s") (struct.loadF GoKVServer.S "lastReply" "s") (struct.loadF lockservice.RPCRequest.S "CID" "args") (struct.loadF lockservice.RPCRequest.S "Seq" "args") "reply"
    then #()
    else struct.storeF lockservice.RPCReply.S "Ret" "reply" (Fst (MapGet (struct.loadF GoKVServer.S "kvs" "s") (struct.get lockservice.RPCVals.S "U64_1" (struct.loadF lockservice.RPCRequest.S "Args" "args")))));;
    let: "l" := aof.AppendOnlyFile__Append (struct.loadF GoKVServer.S "opLog" "s") (encodeReq #1 "args") in
    lock.release (struct.loadF GoKVServer.S "mu" "s");;
    aof.AppendOnlyFile__WaitAppend (struct.loadF GoKVServer.S "opLog" "s") "l";;
    #false.

Definition MakeGoKVServer: val :=
  rec: "MakeGoKVServer" <> :=
    let: "srv" := struct.alloc GoKVServer.S (zero_val (struct.t GoKVServer.S)) in
    struct.storeF GoKVServer.S "mu" "srv" (lock.new #());;
    struct.storeF GoKVServer.S "lastReply" "srv" (NewMap uint64T);;
    struct.storeF GoKVServer.S "lastSeq" "srv" (NewMap uint64T);;
    struct.storeF GoKVServer.S "kvs" "srv" (NewMap ValueType);;
    struct.storeF GoKVServer.S "opLog" "srv" (aof.CreateAppendOnlyFile #(str"kvdur_log"));;
    "srv".
