(* autogenerated by goose axiom generator; do not modify *)
From New.golang Require Import defn.

Section axioms.
Context `{ffi_syntax}.

Axiom CompareType : go_type.
Axiom CompareType__mset : list (string * val).
Axiom CompareType__mset_ptr : list (string * val).
Axiom Greater : val.
Axiom GreaterOrEqual : val.
Axiom Less : val.
Axiom LessOrEqual : val.
Axiom Positive : val.
Axiom Negative : val.
Axiom Conditionf : val.
Axiom Containsf : val.
Axiom DirExistsf : val.
Axiom ElementsMatchf : val.
Axiom Emptyf : val.
Axiom Equalf : val.
Axiom EqualErrorf : val.
Axiom EqualExportedValuesf : val.
Axiom EqualValuesf : val.
Axiom Errorf : val.
Axiom ErrorAsf : val.
Axiom ErrorContainsf : val.
Axiom ErrorIsf : val.
Axiom Eventuallyf : val.
Axiom EventuallyWithTf : val.
Axiom Exactlyf : val.
Axiom Failf : val.
Axiom FailNowf : val.
Axiom Falsef : val.
Axiom FileExistsf : val.
Axiom Greaterf : val.
Axiom GreaterOrEqualf : val.
Axiom HTTPBodyContainsf : val.
Axiom HTTPBodyNotContainsf : val.
Axiom HTTPErrorf : val.
Axiom HTTPRedirectf : val.
Axiom HTTPStatusCodef : val.
Axiom HTTPSuccessf : val.
Axiom Implementsf : val.
Axiom InDeltaf : val.
Axiom InDeltaMapValuesf : val.
Axiom InDeltaSlicef : val.
Axiom InEpsilonf : val.
Axiom InEpsilonSlicef : val.
Axiom IsDecreasingf : val.
Axiom IsIncreasingf : val.
Axiom IsNonDecreasingf : val.
Axiom IsNonIncreasingf : val.
Axiom IsTypef : val.
Axiom JSONEqf : val.
Axiom Lenf : val.
Axiom Lessf : val.
Axiom LessOrEqualf : val.
Axiom Negativef : val.
Axiom Neverf : val.
Axiom Nilf : val.
Axiom NoDirExistsf : val.
Axiom NoErrorf : val.
Axiom NoFileExistsf : val.
Axiom NotContainsf : val.
Axiom NotEmptyf : val.
Axiom NotEqualf : val.
Axiom NotEqualValuesf : val.
Axiom NotErrorIsf : val.
Axiom NotImplementsf : val.
Axiom NotNilf : val.
Axiom NotPanicsf : val.
Axiom NotRegexpf : val.
Axiom NotSamef : val.
Axiom NotSubsetf : val.
Axiom NotZerof : val.
Axiom Panicsf : val.
Axiom PanicsWithErrorf : val.
Axiom PanicsWithValuef : val.
Axiom Positivef : val.
Axiom Regexpf : val.
Axiom Samef : val.
Axiom Subsetf : val.
Axiom Truef : val.
Axiom WithinDurationf : val.
Axiom WithinRangef : val.
Axiom YAMLEqf : val.
Axiom Zerof : val.
Axiom Assertions__Condition : val.
Axiom Assertions__Conditionf : val.
Axiom Assertions__Contains : val.
Axiom Assertions__Containsf : val.
Axiom Assertions__DirExists : val.
Axiom Assertions__DirExistsf : val.
Axiom Assertions__ElementsMatch : val.
Axiom Assertions__ElementsMatchf : val.
Axiom Assertions__Empty : val.
Axiom Assertions__Emptyf : val.
Axiom Assertions__Equal : val.
Axiom Assertions__EqualError : val.
Axiom Assertions__EqualErrorf : val.
Axiom Assertions__EqualExportedValues : val.
Axiom Assertions__EqualExportedValuesf : val.
Axiom Assertions__EqualValues : val.
Axiom Assertions__EqualValuesf : val.
Axiom Assertions__Equalf : val.
Axiom Assertions__Error : val.
Axiom Assertions__ErrorAs : val.
Axiom Assertions__ErrorAsf : val.
Axiom Assertions__ErrorContains : val.
Axiom Assertions__ErrorContainsf : val.
Axiom Assertions__ErrorIs : val.
Axiom Assertions__ErrorIsf : val.
Axiom Assertions__Errorf : val.
Axiom Assertions__Eventually : val.
Axiom Assertions__EventuallyWithT : val.
Axiom Assertions__EventuallyWithTf : val.
Axiom Assertions__Eventuallyf : val.
Axiom Assertions__Exactly : val.
Axiom Assertions__Exactlyf : val.
Axiom Assertions__Fail : val.
Axiom Assertions__FailNow : val.
Axiom Assertions__FailNowf : val.
Axiom Assertions__Failf : val.
Axiom Assertions__False : val.
Axiom Assertions__Falsef : val.
Axiom Assertions__FileExists : val.
Axiom Assertions__FileExistsf : val.
Axiom Assertions__Greater : val.
Axiom Assertions__GreaterOrEqual : val.
Axiom Assertions__GreaterOrEqualf : val.
Axiom Assertions__Greaterf : val.
Axiom Assertions__HTTPBodyContains : val.
Axiom Assertions__HTTPBodyContainsf : val.
Axiom Assertions__HTTPBodyNotContains : val.
Axiom Assertions__HTTPBodyNotContainsf : val.
Axiom Assertions__HTTPError : val.
Axiom Assertions__HTTPErrorf : val.
Axiom Assertions__HTTPRedirect : val.
Axiom Assertions__HTTPRedirectf : val.
Axiom Assertions__HTTPStatusCode : val.
Axiom Assertions__HTTPStatusCodef : val.
Axiom Assertions__HTTPSuccess : val.
Axiom Assertions__HTTPSuccessf : val.
Axiom Assertions__Implements : val.
Axiom Assertions__Implementsf : val.
Axiom Assertions__InDelta : val.
Axiom Assertions__InDeltaMapValues : val.
Axiom Assertions__InDeltaMapValuesf : val.
Axiom Assertions__InDeltaSlice : val.
Axiom Assertions__InDeltaSlicef : val.
Axiom Assertions__InDeltaf : val.
Axiom Assertions__InEpsilon : val.
Axiom Assertions__InEpsilonSlice : val.
Axiom Assertions__InEpsilonSlicef : val.
Axiom Assertions__InEpsilonf : val.
Axiom Assertions__IsDecreasing : val.
Axiom Assertions__IsDecreasingf : val.
Axiom Assertions__IsIncreasing : val.
Axiom Assertions__IsIncreasingf : val.
Axiom Assertions__IsNonDecreasing : val.
Axiom Assertions__IsNonDecreasingf : val.
Axiom Assertions__IsNonIncreasing : val.
Axiom Assertions__IsNonIncreasingf : val.
Axiom Assertions__IsType : val.
Axiom Assertions__IsTypef : val.
Axiom Assertions__JSONEq : val.
Axiom Assertions__JSONEqf : val.
Axiom Assertions__Len : val.
Axiom Assertions__Lenf : val.
Axiom Assertions__Less : val.
Axiom Assertions__LessOrEqual : val.
Axiom Assertions__LessOrEqualf : val.
Axiom Assertions__Lessf : val.
Axiom Assertions__Negative : val.
Axiom Assertions__Negativef : val.
Axiom Assertions__Never : val.
Axiom Assertions__Neverf : val.
Axiom Assertions__Nil : val.
Axiom Assertions__Nilf : val.
Axiom Assertions__NoDirExists : val.
Axiom Assertions__NoDirExistsf : val.
Axiom Assertions__NoError : val.
Axiom Assertions__NoErrorf : val.
Axiom Assertions__NoFileExists : val.
Axiom Assertions__NoFileExistsf : val.
Axiom Assertions__NotContains : val.
Axiom Assertions__NotContainsf : val.
Axiom Assertions__NotEmpty : val.
Axiom Assertions__NotEmptyf : val.
Axiom Assertions__NotEqual : val.
Axiom Assertions__NotEqualValues : val.
Axiom Assertions__NotEqualValuesf : val.
Axiom Assertions__NotEqualf : val.
Axiom Assertions__NotErrorIs : val.
Axiom Assertions__NotErrorIsf : val.
Axiom Assertions__NotImplements : val.
Axiom Assertions__NotImplementsf : val.
Axiom Assertions__NotNil : val.
Axiom Assertions__NotNilf : val.
Axiom Assertions__NotPanics : val.
Axiom Assertions__NotPanicsf : val.
Axiom Assertions__NotRegexp : val.
Axiom Assertions__NotRegexpf : val.
Axiom Assertions__NotSame : val.
Axiom Assertions__NotSamef : val.
Axiom Assertions__NotSubset : val.
Axiom Assertions__NotSubsetf : val.
Axiom Assertions__NotZero : val.
Axiom Assertions__NotZerof : val.
Axiom Assertions__Panics : val.
Axiom Assertions__PanicsWithError : val.
Axiom Assertions__PanicsWithErrorf : val.
Axiom Assertions__PanicsWithValue : val.
Axiom Assertions__PanicsWithValuef : val.
Axiom Assertions__Panicsf : val.
Axiom Assertions__Positive : val.
Axiom Assertions__Positivef : val.
Axiom Assertions__Regexp : val.
Axiom Assertions__Regexpf : val.
Axiom Assertions__Same : val.
Axiom Assertions__Samef : val.
Axiom Assertions__Subset : val.
Axiom Assertions__Subsetf : val.
Axiom Assertions__True : val.
Axiom Assertions__Truef : val.
Axiom Assertions__WithinDuration : val.
Axiom Assertions__WithinDurationf : val.
Axiom Assertions__WithinRange : val.
Axiom Assertions__WithinRangef : val.
Axiom Assertions__YAMLEq : val.
Axiom Assertions__YAMLEqf : val.
Axiom Assertions__Zero : val.
Axiom Assertions__Zerof : val.
Axiom IsIncreasing : val.
Axiom IsNonIncreasing : val.
Axiom IsDecreasing : val.
Axiom IsNonDecreasing : val.
Axiom TestingT : go_type.
Axiom TestingT__mset : list (string * val).
Axiom TestingT__mset_ptr : list (string * val).
Axiom ComparisonAssertionFunc : go_type.
Axiom ComparisonAssertionFunc__mset : list (string * val).
Axiom ComparisonAssertionFunc__mset_ptr : list (string * val).
Axiom ValueAssertionFunc : go_type.
Axiom ValueAssertionFunc__mset : list (string * val).
Axiom ValueAssertionFunc__mset_ptr : list (string * val).
Axiom BoolAssertionFunc : go_type.
Axiom BoolAssertionFunc__mset : list (string * val).
Axiom BoolAssertionFunc__mset_ptr : list (string * val).
Axiom ErrorAssertionFunc : go_type.
Axiom ErrorAssertionFunc__mset : list (string * val).
Axiom ErrorAssertionFunc__mset_ptr : list (string * val).
Axiom Comparison : go_type.
Axiom Comparison__mset : list (string * val).
Axiom Comparison__mset_ptr : list (string * val).
Axiom ObjectsAreEqual : val.
Axiom ObjectsExportedFieldsAreEqual : val.
Axiom ObjectsAreEqualValues : val.
Axiom CallerInfo : val.
Axiom FailNow : val.
Axiom Fail : val.
Axiom Implements : val.
Axiom NotImplements : val.
Axiom IsType : val.
Axiom Equal : val.
Axiom Same : val.
Axiom NotSame : val.
Axiom EqualValues : val.
Axiom EqualExportedValues : val.
Axiom Exactly : val.
Axiom NotNil : val.
Axiom Nil : val.
Axiom Empty : val.
Axiom NotEmpty : val.
Axiom Len : val.
Axiom True : val.
Axiom False : val.
Axiom NotEqual : val.
Axiom NotEqualValues : val.
Axiom Contains : val.
Axiom NotContains : val.
Axiom Subset : val.
Axiom NotSubset : val.
Axiom ElementsMatch : val.
Axiom Condition : val.
Axiom PanicTestFunc : go_type.
Axiom PanicTestFunc__mset : list (string * val).
Axiom PanicTestFunc__mset_ptr : list (string * val).
Axiom Panics : val.
Axiom PanicsWithValue : val.
Axiom PanicsWithError : val.
Axiom NotPanics : val.
Axiom WithinDuration : val.
Axiom WithinRange : val.
Axiom InDelta : val.
Axiom InDeltaSlice : val.
Axiom InDeltaMapValues : val.
Axiom InEpsilon : val.
Axiom InEpsilonSlice : val.
Axiom NoError : val.
Axiom Error : val.
Axiom EqualError : val.
Axiom ErrorContains : val.
Axiom Regexp : val.
Axiom NotRegexp : val.
Axiom Zero : val.
Axiom NotZero : val.
Axiom FileExists : val.
Axiom NoFileExists : val.
Axiom DirExists : val.
Axiom NoDirExists : val.
Axiom JSONEq : val.
Axiom YAMLEq : val.
Axiom Eventually : val.
Axiom CollectT : go_type.
Axiom CollectT__mset : list (string * val).
Axiom CollectT__mset_ptr : list (string * val).
Axiom CollectT__Errorf : val.
Axiom CollectT__FailNow : val.
Axiom CollectT__Reset : val.
Axiom CollectT__Copy : val.
Axiom EventuallyWithT : val.
Axiom Never : val.
Axiom ErrorIs : val.
Axiom NotErrorIs : val.
Axiom ErrorAs : val.
Axiom Assertions : go_type.
Axiom Assertions__mset : list (string * val).
Axiom Assertions__mset_ptr : list (string * val).
Axiom New : val.
Axiom HTTPSuccess : val.
Axiom HTTPRedirect : val.
Axiom HTTPError : val.
Axiom HTTPStatusCode : val.
Axiom HTTPBody : val.
Axiom HTTPBodyContains : val.
Axiom HTTPBodyNotContains : val.

End axioms.
