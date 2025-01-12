// RUN: %target-swift-frontend -emit-silgen %s -module-name test -swift-version 5  -disable-availability-checking -parse-stdlib -sil-verify-all | %FileCheck %s
// REQUIRES: concurrency

import Swift

public struct X {
  // CHECK-LABEL: sil hidden [ossa] @$s4test1XV14getCurrentTaskBoyYaF
  func getCurrentTask() async -> Builtin.NativeObject {
    // CHECK: builtin "getCurrentAsyncTask"() : $Builtin.NativeObject
    return Builtin.getCurrentAsyncTask()
  }

  // CHECK-LABEL: sil hidden [ossa] @$s4test1XV8doCancel4taskyBo_tF : $@convention(method) (@guaranteed Builtin.NativeObject, X) -> ()
  func doCancel(task: Builtin.NativeObject) {
    // CHECK: builtin "cancelAsyncTask"(%0 : $Builtin.NativeObject) : $()
    Builtin.cancelAsyncTask(task)
  }

  // CHECK-LABEL: sil hidden [ossa] @$s4test1XV12launchFutureyyxlF : $@convention(method) <T> (@in_guaranteed T, X) -> ()
  func launchFuture<T>(_ value: T) {
    // CHECK: builtin "createAsyncTask"<T>([[ZERO:%.*]] : $Int, [[FN:%.*]] : $@async @callee_guaranteed @substituted <τ_0_0> () -> (@out τ_0_0, @error any Error) for <T>) : $(Builtin.NativeObject, Builtin.RawPointer)
    _ = Builtin.createAsyncTask(0) { () async throws -> T in
      return value
    }
  }

  // CHECK-LABEL: sil hidden [ossa] @$s4test1XV16launchGroupChild_5groupyx_BptlF : $@convention(method) <T> (@in_guaranteed T, Builtin.RawPointer, X) -> () {
  func launchGroupChild<T>(_ value: T, group: Builtin.RawPointer) {
    // CHECK: builtin "createAsyncTaskInGroup"<T>([[ZERO:%.*]] : $Int, [[GROUP:%.*]] : $Builtin.RawPointer, [[FN:%.*]] : $@async @callee_guaranteed @substituted <τ_0_0> () -> (@out τ_0_0, @error any Error) for <T>) : $(Builtin.NativeObject, Builtin.RawPointer)
    _ = Builtin.createAsyncTaskInGroup(0, group) { () async throws -> T in
      return value
    }
  }

  // CHECK-LABEL: sil hidden [ossa] @$s4test1XV26launchDiscardingGroupChild5groupyBp_tF : $@convention(method) (Builtin.RawPointer, X) -> () {
  func launchDiscardingGroupChild(group: Builtin.RawPointer) {
    // CHECK: [[VOID:%.*]] = metatype $@thick ().Type
    // CHECK: [[VOID_THICK:%.*]] = init_existential_metatype [[VOID]] : $@thick ().Type, $@thick any Any.Type
    // CHECK: builtin "createAsyncDiscardingTaskInGroup"([[ZERO:%.*]] : $Int, [[GROUP:%.*]] : $Builtin.RawPointer, [[VOID_THICK]] : $@thick any Any.Type, [[FN:%.*]] : $@async @callee_guaranteed () -> @error any Error) : $(Builtin.NativeObject, Builtin.RawPointer)
    _ = Builtin.createAsyncDiscardingTaskInGroup(0, group) { () async throws in
      return
    }
  }

  public func launchRocker<T>(closure: @escaping () async throws -> T) {
    _ = Builtin.createAsyncTask(0, closure)
  }

  // CHECK-LABEL: sil hidden [ossa] @$s4test1XV24launchFutureWithExecutor_8executoryx_BetlF : $@convention(method) <T> (@in_guaranteed T, Builtin.Executor, X) -> () {
  func launchFutureWithExecutor<T>(_ value: T, executor: Builtin.Executor) {
    // CHECK: bb0([[ZERO:%[0-9]+]] : $*T, [[EXECUTOR:%[0-9]+]] : $Builtin.Executor, [[TWO:%[0-9]+]] : $X):
    // CHECK: [[TASK:%[0-9]+]] = builtin "createAsyncTaskWithExecutor"<T>([[NINE:%[0-9]+]] : $Int, [[EXECUTOR]] : $Builtin.Executor, [[TYPE:%[0-9]+]] : $@thick any Any.Type, [[FN:%[0-9]+]] : $@async @callee_guaranteed @substituted <τ_0_0> () -> (@out τ_0_0, @error any Error) for <T>) : $(Builtin.NativeObject, Builtin.RawPointer)
    _ = Builtin.createAsyncTaskWithExecutor(0, executor) { () async throws -> T in
      return value
    }
  }

  // CHECK-LABEL: sil hidden [ossa] @$s4test1XV34launchDiscardingFutureWithExecutor5group8executoryBp_BetF : $@convention(method) (Builtin.RawPointer, Builtin.Executor, X) -> () {
  func launchDiscardingFutureWithExecutor(group: Builtin.RawPointer, executor: Builtin.Executor) {
    // CHECK: [[VOID:%.*]] = metatype $@thick ().Type
    // CHECK: [[VOID_THICK:%.*]] = init_existential_metatype [[VOID]] : $@thick ().Type, $@thick any Any.Type
    // CHECK: builtin "createAsyncTaskInGroupWithExecutor"([[ZERO:%.*]] : $Int, [[GROUP:%.*]] : $Builtin.RawPointer, [[EXECUTOR:%[0-9]+]] : $Builtin.Executor, [[VOID_THICK]] : $@thick any Any.Type, [[FN:%.*]] : $@async @callee_guaranteed () -> @error any Error) : $(Builtin.NativeObject, Builtin.RawPointer)
    _ = Builtin.createAsyncDiscardingTaskInGroupWithExecutor(0, group, executor) { () async throws in
      return
    }
  }
}

// CHECK-LABEL: sil [ossa] @$s4test26usesWithUnsafeContinuationyyYaF : $@convention(thin) @async () -> () {
public func usesWithUnsafeContinuation() async {
  // trivial resume type
  let _: Int = await Builtin.withUnsafeContinuation { c in }

  // CHECK: [[FN:%.*]] = function_ref @$s4test26usesWithUnsafeContinuationyyYaFyBcXEfU_ : $@convention(thin) (Builtin.RawUnsafeContinuation) -> ()
  // CHECK: [[CLOSURE:%.*]] = thin_to_thick_function [[FN]]
  // CHECK: [[BOX:%.*]] = alloc_stack $Int
  // CHECK: [[CC:%.*]] = get_async_continuation_addr Int, [[BOX]] : $*Int
  // CHECK: apply [[CLOSURE]]([[CC]]) : $@noescape @callee_guaranteed (Builtin.RawUnsafeContinuation) -> ()
  // CHECK: await_async_continuation [[CC]] : $Builtin.RawUnsafeContinuation, resume bb1

  // CHECK: bb1:
  // CHECK: [[RESULT:%.*]] = load [trivial] [[BOX]] : $*Int
  // CHECK: dealloc_stack [[BOX]]

  // loadable resume type
  let _: String = await Builtin.withUnsafeContinuation { c in }

  // CHECK: [[FN:%.*]] = function_ref @$s4test26usesWithUnsafeContinuationyyYaFyBcXEfU0_ : $@convention(thin) (Builtin.RawUnsafeContinuation) -> ()
  // CHECK: [[CLOSURE:%.*]] = thin_to_thick_function [[FN]]
  // CHECK: [[BOX:%.*]] = alloc_stack $String
  // CHECK: [[CC:%.*]] = get_async_continuation_addr String, [[BOX]] : $*String
  // CHECK: apply [[CLOSURE]]([[CC]]) : $@noescape @callee_guaranteed (Builtin.RawUnsafeContinuation) -> ()
  // CHECK: await_async_continuation [[CC]] : $Builtin.RawUnsafeContinuation, resume bb2

  // CHECK: bb2:
  // CHECK: [[RESULT:%.*]] = load [take] [[BOX]] : $*String
  // CHECK: destroy_value [[RESULT]]
  // CHECK: dealloc_stack [[BOX]]

  // address-only resume type
  let _: Any = await Builtin.withUnsafeContinuation { c in }

  // CHECK: [[FN:%.*]] = function_ref @$s4test26usesWithUnsafeContinuationyyYaFyBcXEfU1_ : $@convention(thin) (Builtin.RawUnsafeContinuation) -> ()
  // CHECK: [[CLOSURE:%.*]] = thin_to_thick_function [[FN]]
  // CHECK: [[BOX:%.*]] = alloc_stack $Any
  // CHECK: [[CC:%.*]] = get_async_continuation_addr Any, [[BOX]] : $*Any
  // CHECK: apply [[CLOSURE]]([[CC]]) : $@noescape @callee_guaranteed (Builtin.RawUnsafeContinuation) -> ()
  // CHECK: await_async_continuation [[CC]] : $Builtin.RawUnsafeContinuation, resume bb3

  // CHECK: bb3:
  // CHECK: [[COPY:%.*]] = alloc_stack $Any
  // CHECK: copy_addr [take] [[BOX]] to [init] [[COPY]]
  // CHECK: destroy_addr [[COPY]]
  // CHECK: dealloc_stack [[COPY]]
  // CHECK: dealloc_stack [[BOX]]
}

// CHECK-LABEL: sil [ossa] @$s4test34usesWithUnsafeThrowingContinuationyyYaKF : $@convention(thin) @async () -> @error any Error {
public func usesWithUnsafeThrowingContinuation() async throws {
  let _: Int = try await Builtin.withUnsafeThrowingContinuation { c in }

  // CHECK: [[FN:%.*]] = function_ref @$s4test34usesWithUnsafeThrowingContinuationyyYaKFyBcXEfU_ : $@convention(thin) (Builtin.RawUnsafeContinuation) -> ()
  // CHECK: [[CLOSURE:%.*]] = thin_to_thick_function [[FN]]
  // CHECK: [[BOX:%.*]] = alloc_stack $Int
  // CHECK: [[CC:%.*]] = get_async_continuation_addr [throws] Int, [[BOX]] : $*Int
  // CHECK: apply [[CLOSURE]]([[CC]]) : $@noescape @callee_guaranteed (Builtin.RawUnsafeContinuation) -> ()
  // CHECK: await_async_continuation [[CC]] : $Builtin.RawUnsafeContinuation, resume bb1, error bb2

  // CHECK: bb1:
  // CHECK: [[RESULT:%.*]] = load [trivial] [[BOX]] : $*Int
  // CHECK: dealloc_stack [[BOX]]

  // CHECK: bb2([[ERROR:%.*]] : @owned $any Error):
  // CHECK: builtin "willThrow"([[ERROR]] : $any Error) : $()
  // CHECK: dealloc_stack [[BOX]]
  // CHECK: throw [[ERROR]]
}

// Make sure we do the right thing when the closure value is non-trivial,
// because it has captures and was formed by a partial_apply.
public func usesWithUnsafeContinuationCaptures(fn: (Builtin.RawUnsafeContinuation) -> ()) async throws {
  let _: Int = await Builtin.withUnsafeContinuation { c in fn(c) }
}

// CHECK-LABEL: sil [ossa] @$s4test29resumeNonThrowingContinuationyyBc_SSntF
public func resumeNonThrowingContinuation(_ cont: Builtin.RawUnsafeContinuation,
                                          _ value: __owned String) {
  // CHECK: bb0(%0 : $Builtin.RawUnsafeContinuation, %1 : @owned $String):
  // CHECK:      debug_value
  // CHECK:      [[BORROW:%.*]] = begin_borrow %1 : $String
  // CHECK-NEXT: [[COPY:%.*]] = copy_value [[BORROW]] : $String
  // CHECK-NEXT: builtin "resumeNonThrowingContinuationReturning"<String>(%0 : $Builtin.RawUnsafeContinuation, [[COPY]] : $String)
  // CHECK-NEXT: end_borrow [[BORROW]] : $String
  // CHECK-NEXT: destroy_value %1 : $String
  Builtin.resumeNonThrowingContinuationReturning(cont, value)
}

// CHECK-LABEL: sil [ossa] @$s4test26resumeThrowingContinuationyyBc_SSntF
public func resumeThrowingContinuation(_ cont: Builtin.RawUnsafeContinuation,
                                       _ value: __owned String) {
  // CHECK: bb0(%0 : $Builtin.RawUnsafeContinuation, %1 : @owned $String):
  // CHECK:      debug_value
  // CHECK:      [[BORROW:%.*]] = begin_borrow %1 : $String
  // CHECK-NEXT: [[COPY:%.*]] = copy_value [[BORROW]] : $String
  // CHECK-NEXT: builtin "resumeThrowingContinuationReturning"<String>(%0 : $Builtin.RawUnsafeContinuation, [[COPY]] : $String)
  // CHECK-NEXT: end_borrow [[BORROW]] : $String
  // CHECK-NEXT: destroy_value %1 : $String
  Builtin.resumeThrowingContinuationReturning(cont, value)
}

// CHECK-LABEL: sil [ossa] @$s4test026resumeThrowingContinuationC0yyBc_s5Error_pntF
public func resumeThrowingContinuationThrowing(_ cont: Builtin.RawUnsafeContinuation,
                                               _ error: __owned Error) {
  // CHECK: bb0(%0 : $Builtin.RawUnsafeContinuation, %1 : @owned $any Error):
  // CHECK:      debug_value
  // CHECK:      [[BORROW:%.*]] = begin_borrow %1 : $any Error
  // CHECK-NEXT: [[COPY:%.*]] = copy_value [[BORROW]] : $any Error
  // CHECK-NEXT: builtin "resumeThrowingContinuationThrowing"(%0 : $Builtin.RawUnsafeContinuation, [[COPY]] : $any Error)
  // CHECK-NEXT: end_borrow [[BORROW]] : $any Error
  // CHECK-NEXT: destroy_value %1 : $any Error
  Builtin.resumeThrowingContinuationThrowing(cont, error)
}
