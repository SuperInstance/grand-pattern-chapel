# Grand Pattern Fibonacci Dual-Direction Architecture - Chapel

Chapel 2.x implementation of the Grand Pattern cellular graph system, leveraging Chapel's native parallel features.

## Architecture

The core system is a cellular graph where each cell (room) maintains:
- **Perception DB (Z_in)**: incoming sensor embeddings
- **Prediction DB (Z_out)**: predicted future embeddings
- **JEPA mapping**: cross-DB comparison computing prediction error (surprise)
- **Double-entry bookkeeping**: every tick updates BOTH databases, must balance
- **Vibe**: (position, velocity, acceleration) tuple on the embedding manifold
- **GC**: 3-phase (merge similar → decay old → prune weak)
- **Cellular graph**: rooms as nodes, algorithms as edges, murmur as gossip protocol

## Building

```bash
make
```

## Testing

```bash
make test
```

## Project Structure

- `src/GPTypes.chpl` - Core type definitions (Embedding, Tick, Vibe, Room, CellularGraph)
- `src/GPOps.chpl` - Core operations (tick, predict, balance_check, compute_vibe, gc, murmur, correlate)
- `tests/test_gp.chpl` - Comprehensive test suite (13 tests)

## Requirements

- Chapel 2.x compiler
- No external dependencies
