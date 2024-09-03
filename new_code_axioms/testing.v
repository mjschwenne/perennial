(* autogenerated by goose axiom generator; do not modify *)
From New.golang Require Import defn.

Section axioms.
Context `{ffi_syntax}.

Axiom AllocsPerRun : val.
Axiom durationOrCountFlag__String : val.
Axiom durationOrCountFlag__Set : val.
Axiom InternalBenchmark : go_type.
Axiom InternalBenchmark__mset : list (string * val).
Axiom InternalBenchmark__mset_ptr : list (string * val).
Axiom B : go_type.
Axiom B__mset : list (string * val).
Axiom B__mset_ptr : list (string * val).
Axiom B__StartTimer : val.
Axiom B__StopTimer : val.
Axiom B__ResetTimer : val.
Axiom B__SetBytes : val.
Axiom B__ReportAllocs : val.
Axiom B__Elapsed : val.
Axiom B__ReportMetric : val.
Axiom BenchmarkResult : go_type.
Axiom BenchmarkResult__mset : list (string * val).
Axiom BenchmarkResult__mset_ptr : list (string * val).
Axiom BenchmarkResult__NsPerOp : val.
Axiom BenchmarkResult__AllocsPerOp : val.
Axiom BenchmarkResult__AllocedBytesPerOp : val.
Axiom BenchmarkResult__String : val.
Axiom BenchmarkResult__MemString : val.
Axiom RunBenchmarks : val.
Axiom B__Run : val.
Axiom PB : go_type.
Axiom PB__mset : list (string * val).
Axiom PB__mset_ptr : list (string * val).
Axiom PB__Next : val.
Axiom B__RunParallel : val.
Axiom B__SetParallelism : val.
Axiom Benchmark : val.
Axiom discard__Write : val.
Axiom CoverBlock : go_type.
Axiom CoverBlock__mset : list (string * val).
Axiom CoverBlock__mset_ptr : list (string * val).
Axiom Cover : go_type.
Axiom Cover__mset : list (string * val).
Axiom Cover__mset_ptr : list (string * val).
Axiom Coverage : val.
Axiom RegisterCover : val.
Axiom InternalExample : go_type.
Axiom InternalExample__mset : list (string * val).
Axiom InternalExample__mset_ptr : list (string * val).
Axiom RunExamples : val.
Axiom InternalFuzzTarget : go_type.
Axiom InternalFuzzTarget__mset : list (string * val).
Axiom InternalFuzzTarget__mset_ptr : list (string * val).
Axiom F : go_type.
Axiom F__mset : list (string * val).
Axiom F__mset_ptr : list (string * val).
Axiom F__Helper : val.
Axiom F__Fail : val.
Axiom F__Skipped : val.
Axiom F__Add : val.
Axiom F__Fuzz : val.
Axiom fuzzResult__String : val.
Axiom Init : val.
Axiom chattyFlag__IsBoolFlag : val.
Axiom chattyFlag__Set : val.
Axiom chattyFlag__String : val.
Axiom chattyFlag__Get : val.
Axiom chattyPrinter__Updatef : val.
Axiom chattyPrinter__Printf : val.
Axiom Short : val.
Axiom Testing : val.
Axiom CoverMode : val.
Axiom Verbose : val.
Axiom indenter__Write : val.
Axiom TB : go_type.
Axiom TB__mset : list (string * val).
Axiom TB__mset_ptr : list (string * val).
Axiom T : go_type.
Axiom T__mset : list (string * val).
Axiom T__mset_ptr : list (string * val).
Axiom common__Name : val.
Axiom common__Fail : val.
Axiom common__Failed : val.
Axiom common__FailNow : val.
Axiom common__Log : val.
Axiom common__Logf : val.
Axiom common__Error : val.
Axiom common__Errorf : val.
Axiom common__Fatal : val.
Axiom common__Fatalf : val.
Axiom common__Skip : val.
Axiom common__Skipf : val.
Axiom common__SkipNow : val.
Axiom common__Skipped : val.
Axiom common__Helper : val.
Axiom common__Cleanup : val.
Axiom common__TempDir : val.
Axiom common__Setenv : val.
Axiom T__Parallel : val.
Axiom T__Setenv : val.
Axiom InternalTest : go_type.
Axiom InternalTest__mset : list (string * val).
Axiom InternalTest__mset_ptr : list (string * val).
Axiom T__Run : val.
Axiom T__Deadline : val.
Axiom matchStringOnly__MatchString : val.
Axiom matchStringOnly__StartCPUProfile : val.
Axiom matchStringOnly__StopCPUProfile : val.
Axiom matchStringOnly__WriteProfileTo : val.
Axiom matchStringOnly__ImportPath : val.
Axiom matchStringOnly__StartTestLog : val.
Axiom matchStringOnly__StopTestLog : val.
Axiom matchStringOnly__SetPanicOnExit0 : val.
Axiom matchStringOnly__CoordinateFuzzing : val.
Axiom matchStringOnly__RunFuzzWorker : val.
Axiom matchStringOnly__ReadCorpus : val.
Axiom matchStringOnly__CheckCorpus : val.
Axiom matchStringOnly__ResetCoverage : val.
Axiom matchStringOnly__SnapshotCoverage : val.
Axiom matchStringOnly__InitRuntimeCoverage : val.
Axiom Main : val.
Axiom M : go_type.
Axiom M__mset : list (string * val).
Axiom M__mset_ptr : list (string * val).
Axiom MainStart : val.
Axiom M__Run : val.
Axiom RunTests : val.

End axioms.
