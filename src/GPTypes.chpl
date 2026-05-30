// Grand Pattern Fibonacci Dual-Direction Architecture
// Core type definitions
module GPTypes {
  param embedDim = 8;
  type realType = real(64);

  // Embedding vector
  record Embedding {
    var data: [0..#embedDim] realType;

    proc init() { data = 0.0; }
    proc init(data: [0..#embedDim] realType) { this.data = data; }

    proc norm() {
      return sqrt(+ reduce(data * data));
    }
  }

  // Tick record
  record Tick {
    var timestamp: realType;
    var sensorId: int;
    var emb: Embedding;
    var strength: realType = 1.0;

    proc init() {
      emb = new Embedding();
    }
  }

  // Vibe: position, velocity, acceleration on embedding manifold
  record Vibe {
    var position: Embedding;
    var velocity: Embedding;
    var acceleration: Embedding;
    var strength: realType = 1.0;

    proc init() {
      position = new Embedding();
      velocity = new Embedding();
      acceleration = new Embedding();
    }
  }

  // Database of ticks
  class TickDB {
    var entries: list(Tick);
    var count: int;

    proc init() {
      entries = new list(Tick);
      count = 0;
    }

    proc push(entry: Tick) {
      entries.append(entry);
      count += 1;
    }

    proc last(): Tick {
      if count > 0 then return entries.last();
      var empty: Tick;
      return empty;
    }
  }

  // Room: a node in the cellular graph
  record Room {
    var id: int;
    var perceptionDB: owned TickDB;
    var predictionDB: owned TickDB;
    var vibe: Vibe;

    proc init(id: int = 0) {
      this.id = id;
      perceptionDB = new TickDB();
      predictionDB = new TickDB();
      vibe = new Vibe();
    }
  }

  // Edge between rooms
  record Edge {
    var fromId: int;
    var toId: int;
    var weight: realType = 1.0;
  }

  // GC report
  record GCReport {
    var merged: int = 0;
    var decayed: int = 0;
    var pruned: int = 0;
  }

  // Cellular Graph
  class CellularGraph {
    var rooms: map(int, owned Room);
    var edges: list(Edge);
    var roomIdList: list(int);

    proc init() {
      rooms = new map(int, owned Room);
      edges = new list(Edge);
      roomIdList = new list(int);
    }

    proc addRoom(id: int) {
      if !rooms.contains(id) {
        rooms.add(id, new Room(id));
        roomIdList.append(id);
      }
    }

    proc addEdge(fromId: int, toId: int, weight: realType = 1.0) {
      var e: Edge;
      e.fromId = fromId;
      e.toId = toId;
      e.weight = weight;
      edges.append(e);
    }

    proc getRoom(id: int): borrowed Room {
      return rooms.getBorrowed(id);
    }
  }
}
