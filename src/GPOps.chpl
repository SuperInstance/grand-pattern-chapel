// Grand Pattern Fibonacci Dual-Direction Architecture
// Core operations
module GPOps {
  use GPTypes;
  use Math;

  // ---- Embedding operations ----

  proc cosineSimilarity(a: Embedding, b: Embedding): realType {
    var dotP = + reduce(a.data * b.data);
    var na = a.norm();
    var nb = b.norm();
    if na < 1.0e-12 || nb < 1.0e-12 then return 0.0;
    return dotP / (na * nb);
  }

  proc cosineDistance(a: Embedding, b: Embedding): realType {
    return 1.0 - cosineSimilarity(a, b);
  }

  proc embeddingZero(): Embedding {
    return new Embedding();
  }

  // ---- Core architecture functions ----

  // Process a tick: update perception DB, generate prediction, compute error
  proc tickRoom(ref room: Room, reading: Embedding, timestamp: realType,
                sensorId: int, threshold: realType): (realType, bool) {
    // 1. Store perception in Z_in
    var pTick: Tick;
    pTick.timestamp = timestamp;
    pTick.sensorId = sensorId;
    pTick.emb = reading;
    pTick.strength = 1.0;
    room.perceptionDB.push(pTick);

    // 2. Generate prediction from current vibe
    var predicted = predict(room);
    var predTick: Tick;
    predTick.timestamp = timestamp;
    predTick.sensorId = sensorId;
    predTick.emb = predicted;
    predTick.strength = 1.0;
    room.predictionDB.push(predTick);

    // 3. Compute prediction error
    var err = cosineDistance(reading, predicted);

    // 4. Surprise check
    var isSurprise = err > threshold;

    // 5. Update vibe
    computeVibe(room);

    return (err, isSurprise);
  }

  // Predict next embedding from current vibe trajectory
  proc predict(room: Room): Embedding {
    var pred = new Embedding();
    // p + v + 0.5*a
    for i in 0..#embedDim {
      pred.data[i] = room.vibe.position.data[i] +
                     room.vibe.velocity.data[i] +
                     0.5 * room.vibe.acceleration.data[i];
    }
    return pred;
  }

  // Verify double-entry bookkeeping
  proc balanceCheck(room: Room): bool {
    return room.perceptionDB.count == room.predictionDB.count;
  }

  // Compute vibe from DB history
  proc computeVibe(ref room: Room) {
    var n = room.perceptionDB.count;

    if n == 0 {
      room.vibe.position = new Embedding();
      room.vibe.velocity = new Embedding();
      room.vibe.acceleration = new Embedding();
      room.vibe.strength = 0.0;
      return;
    }

    // Position = last entry
    room.vibe.position = room.perceptionDB.entries[n-1].emb;

    if n >= 2 {
      for i in 0..#embedDim {
        room.vibe.velocity.data[i] = room.perceptionDB.entries[n-1].emb.data[i] -
                                     room.perceptionDB.entries[n-2].emb.data[i];
      }
    } else {
      room.vibe.velocity = new Embedding();
    }

    if n >= 3 {
      var prevDiff: [0..#embedDim] realType;
      for i in 0..#embedDim {
        prevDiff[i] = room.perceptionDB.entries[n-2].emb.data[i] -
                      room.perceptionDB.entries[n-3].emb.data[i];
      }
      for i in 0..#embedDim {
        room.vibe.acceleration.data[i] = room.vibe.velocity.data[i] - prevDiff[i];
      }
    } else {
      room.vibe.acceleration = new Embedding();
    }

    room.vibe.strength = n: realType;
  }

  // Merge embeddings within cosine similarity threshold
  proc mergeSimilar(ref db: TickDB, threshold: realType): int {
    var merged = 0;
    var n = db.count;
    var alive: [0..#n] bool;
    alive = true;

    for i in 0..#n {
      if !alive[i] then continue;
      for j in (i+1)..#(n-i-1) {
        if !alive[j] then continue;
        if cosineSimilarity(db.entries[i].emb, db.entries[j].emb) > threshold {
          // Average the embeddings
          for k in 0..#embedDim {
            db.entries[i].emb.data[k] = 0.5 * (db.entries[i].emb.data[k] +
                                                db.entries[j].emb.data[k]);
          }
          db.entries[i].strength += db.entries[j].strength;
          alive[j] = false;
          merged += 1;
        }
      }
    }

    // Compact
    var newEntries = new list(Tick);
    for i in 0..#n {
      if alive[i] then newEntries.append(db.entries[i]);
    }
    db.entries = newEntries;
    db.count = newEntries.size;

    return merged;
  }

  // Exponential decay on all embedding strengths
  proc decay(ref db: TickDB, rate: realType) {
    for i in 0..#db.count {
      db.entries[i].strength *= rate;
    }
  }

  // Remove embeddings below minimum strength
  proc prune(ref db: TickDB, minStrength: realType): int {
    var pruned = 0;
    var newEntries = new list(Tick);
    for i in 0..#db.count {
      if db.entries[i].strength >= minStrength {
        newEntries.append(db.entries[i]);
      } else {
        pruned += 1;
      }
    }
    db.entries = newEntries;
    db.count = newEntries.size;
    return pruned;
  }

  // Full GC cycle: merge → decay → prune
  proc gc(ref room: Room, mergeThreshold: realType,
          decayRate: realType, minStrength: realType): GCReport {
    var report = new GCReport();

    // Phase 1: Merge similar
    report.merged = mergeSimilar(room.perceptionDB, mergeThreshold);
    report.merged += mergeSimilar(room.predictionDB, mergeThreshold);

    // Phase 2: Decay
    decay(room.perceptionDB, decayRate);
    decay(room.predictionDB, decayRate);
    report.decayed = room.perceptionDB.count + room.predictionDB.count;

    // Phase 3: Prune weak
    report.pruned = prune(room.perceptionDB, minStrength);
    report.pruned += prune(room.predictionDB, minStrength);

    // Rebalance
    rebalance(room);

    return report;
  }

  // Send vibe summary from one room to another (murmur/gossip)
  proc murmur(from: Room, ref to: Room, influence: realType) {
    for i in 0..#embedDim {
      to.vibe.position.data[i] = to.vibe.position.data[i] * (1.0 - influence) +
                                 from.vibe.position.data[i] * influence;
    }
  }

  // Cosine similarity of vibe positions between two rooms
  proc correlate(roomA: Room, roomB: Room): realType {
    return cosineSimilarity(roomA.vibe.position, roomB.vibe.position);
  }

  // Propagate a tick through all edges from a room
  proc propagateTick(ref graph: CellularGraph, ref fromRoom: Room,
                     reading: Embedding, timestamp: realType,
                     sensorId: int, threshold: realType,
                     murmurInfluence: realType) {
    for edge in graph.edges {
      if edge.fromId == fromRoom.id {
        if graph.rooms.contains(edge.toId) {
          murmur(fromRoom, graph.getRoom(edge.toId), murmurInfluence);
        }
      }
    }
  }

  // ---- Internal helpers ----

  proc rebalance(ref room: Room) {
    var target = min(room.perceptionDB.count, room.predictionDB.count);
    // Trim from end if needed
    while room.perceptionDB.count > target {
      room.perceptionDB.entries.pop();
      room.perceptionDB.count -= 1;
    }
    while room.predictionDB.count > target {
      room.predictionDB.entries.pop();
      room.predictionDB.count -= 1;
    }
  }
}
