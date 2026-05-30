// Grand Pattern Fibonacci Dual-Direction Architecture
// Comprehensive test suite
module TestGP {
  use GPTypes;
  use GPOps;

  var passCount = 0;
  var failCount = 0;
  var total = 0;

  proc assert(cond: bool, testName: string) {
    total += 1;
    if cond {
      passCount += 1;
      writeln("  PASS: ", testName);
    } else {
      failCount += 1;
      writeln("  FAIL: ", testName);
    }
  }

  proc main() {
    testTickUpdatesPerceptionDB();
    testPredictGeneratesEmbedding();
    testBalanceCheckPasses();
    testBalanceCheckFails();
    testVibeComputation();
    testMergeReducesCount();
    testDecayReducesStrengths();
    testPruneRemovesWeak();
    testFullGCCycle();
    testCrossRoomCorrelation();
    testMurmurBetweenRooms();
    testGraphConstruction();
    testTickPropagation();

    writeln();
    writef("Results: %i passed, %i failed\n", passCount, failCount);
    if failCount > 0 {
      writeln("FAIL: Some tests failed");
      exit(1);
    } else {
      writeln("ALL TESTS PASSED");
    }
  }

  proc testTickUpdatesPerceptionDB() {
    var r = new Room(1);
    var reading = new Embedding();
    reading.data[0] = 1.0;

    var (err, surprise) = tickRoom(r, reading, 1.0, 42, 0.5);

    assert(r.perceptionDB.count == 1, "tick updates perception DB count");
    assert(r.perceptionDB.entries[0].emb.data[0] == 1.0, "tick stores correct embedding");
    assert(r.perceptionDB.entries[0].sensorId == 42, "tick stores correct sensor_id");
  }

  proc testPredictGeneratesEmbedding() {
    var r = new Room(1);
    r.vibe.position.data = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0];
    r.vibe.velocity.data = [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8];
    r.vibe.acceleration.data = [0.01, 0.02, 0.03, 0.04, 0.05, 0.06, 0.07, 0.08];

    var pred = predict(r);

    assert(pred.data[0] > 0.0, "predict generates non-zero embedding");
    assert(abs(pred.data[0] - 1.105) < 1.0e-10, "predict computes correct value");
  }

  proc testBalanceCheckPasses() {
    var r = new Room(1);
    var t: Tick;
    t.emb = new Embedding();
    t.strength = 1.0;

    r.perceptionDB.push(t);
    r.predictionDB.push(t);
    r.perceptionDB.push(t);
    r.predictionDB.push(t);

    assert(balanceCheck(r), "balance check passes when equal");
  }

  proc testBalanceCheckFails() {
    var r = new Room(1);
    var t: Tick;
    t.emb = new Embedding();
    t.strength = 1.0;

    r.perceptionDB.push(t);
    r.perceptionDB.push(t);
    r.predictionDB.push(t);

    assert(!balanceCheck(r), "balance check fails when unequal");
  }

  proc testVibeComputation() {
    var r = new Room(1);
    for i in 1..3 {
      var t: Tick;
      t.timestamp = i: realType;
      t.strength = 1.0;
      t.emb = new Embedding();
      t.emb.data[0] = i: realType;
      r.perceptionDB.push(t);
    }

    computeVibe(r);

    assert(r.vibe.position.data[0] == 3.0, "vibe position is last entry");
    assert(r.vibe.velocity.data[0] == 1.0, "vibe velocity is diff");
    assert(r.vibe.acceleration.data[0] == 0.0, "vibe acceleration is diff-of-diff");
    assert(r.vibe.strength == 3.0, "vibe strength is entry count");
  }

  proc testMergeReducesCount() {
    var db = new TickDB();
    var t: Tick;
    t.emb = new Embedding();
    t.emb.data[0] = 1.0;
    t.strength = 1.0;

    db.push(t);
    db.push(t);
    db.push(t);

    var merged = mergeSimilar(db, 0.99);

    assert(merged > 0, "merge found similar entries");
    assert(db.count < 3, "merge reduced count");
  }

  proc testDecayReducesStrengths() {
    var db = new TickDB();
    var t: Tick;
    t.emb = new Embedding();
    t.strength = 1.0;

    db.push(t);
    db.push(t);

    decay(db, 0.9);

    assert(db.entries[0].strength < 1.0, "decay reduces strength");
    assert(abs(db.entries[0].strength - 0.9) < 1.0e-10, "decay by correct amount");
  }

  proc testPruneRemovesWeak() {
    var db = new TickDB();

    var t1: Tick;
    t1.emb = new Embedding();
    t1.strength = 1.0;
    db.push(t1);

    var t2: Tick;
    t2.emb = new Embedding();
    t2.strength = 0.01;
    db.push(t2);

    var t3: Tick;
    t3.emb = new Embedding();
    t3.strength = 0.5;
    db.push(t3);

    var pruned = prune(db, 0.1);

    assert(pruned == 1, "prune removes exactly 1 weak entry");
    assert(db.count == 2, "prune leaves 2 entries");
  }

  proc testFullGCCycle() {
    var r = new Room(1);
    for i in 1..5 {
      var reading = new Embedding();
      reading.data[0] = i: realType;
      tickRoom(r, reading, i: realType, 1, 0.5);
    }

    var report = gc(r, 0.99, 0.8, 0.5);

    assert(balanceCheck(r), "GC maintains balance");
    assert(report.merged >= 0, "GC returns merge count");
    assert(report.pruned >= 0, "GC returns prune count");
  }

  proc testCrossRoomCorrelation() {
    var a = new Room(1);
    var b = new Room(2);

    a.vibe.position.data[0] = 1.0;
    b.vibe.position.data[0] = 1.0;

    assert(abs(correlate(a, b) - 1.0) < 1.0e-10, "identical vibes correlate at 1.0");

    b.vibe.position.data[0] = 0.0;
    b.vibe.position.data[1] = 1.0;

    assert(abs(correlate(a, b)) < 1.0e-10, "orthogonal vibes correlate at 0.0");
  }

  proc testMurmurBetweenRooms() {
    var a = new Room(1);
    var b = new Room(2);

    a.vibe.position.data[0] = 1.0;
    b.vibe.position.data[0] = 0.0;

    murmur(a, b, 0.5);

    assert(abs(b.vibe.position.data[0] - 0.5) < 1.0e-10, "murmur blends vibe position");
  }

  proc testGraphConstruction() {
    var graph = new CellularGraph();

    graph.addRoom(1);
    graph.addRoom(2);
    graph.addRoom(3);

    assert(graph.rooms.size == 3, "graph has 3 rooms");

    graph.addEdge(1, 2, 1.0);
    graph.addEdge(2, 3, 0.5);

    assert(graph.edges.size == 2, "graph has 2 edges");
    assert(graph.edges.first().fromId == 1, "edge 1 from correct");
  }

  proc testTickPropagation() {
    var graph = new CellularGraph();
    graph.addRoom(1);
    graph.addRoom(2);
    graph.addEdge(1, 2, 1.0);

    graph.getRoom(1).vibe.position.data[0] = 1.0;
    graph.getRoom(2).vibe.position.data[0] = 0.0;

    var reading = new Embedding();
    reading.data[0] = 2.0;

    propagateTick(graph, graph.getRoom(1), reading, 1.0, 1, 0.5, 0.5);

    assert(graph.getRoom(2).vibe.position.data[0] > 0.0,
           "tick propagation influences connected room via murmur");
  }
}
