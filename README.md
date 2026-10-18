# Procedural Fire Hose & Suppression System for FiveM (WIP)

A realistic, multiplayer-synchronized, and performance-optimized fire suppression framework designed for FiveM (OneSync). This resource simulates dynamic procedural hose deployment, tanker/hydrant supply lines, and real-time fluid physics.

> **Project Status:** Work In Progress (WIP). Core geometric procedural generation, network replication architecture, and safety layers are implemented. Current focus is centered on comprehensive network verification, fluid particle synchronization, and ground collision conformances.

---

## Technical Overview

### 1. Procedural 3D Geometry & Math Simulation
* **Quadratic Bézier Curves:** Computes dynamic curves in real time between the fire engine connection panel and the firefighter nozzle or supply hydrant.
* **Coil & Spiral Mathematics:** Simulates remaining stored hose using continuous Archimedean/spiral trigonometric formulas (`coilPos`, `coilTangent`) based on deployment distance.
* **Orientation & Transformation Vectors:** Dynamically aligns individual segments using vector mathematics (computing yaw and pitch angles via `RotationToFace`).
* **Custom Blender 3D Asset:** The segment asset (`prop_pipe_firefighter`) was custom-modeled in **Blender**, featuring a low-poly topology designed specifically for chaining hundreds of procedural instances with minimal overhead.

### 2. Networking & OneSync Architecture
* **State Synchronization:** Centralized truck states (`TrucksClient` table and server-side authority) managing water capacity, active holders, and hose attachments.
* **Resilient Attachment Resolution (`ptB`):**
  * **Local Owner:** Direct pointer to the local entity (`HoseObject`) for instantaneous zero-latency camera feedback.
  * **Remote Clients:** Network resolution via `NetToObj(hoseNetId)` to accurately track the nozzle attached to another player.
  * **Streaming Fallback:** Fallback logic tracking the right-hand bone (`SKEL_R_Hand` / `57005`) if the networked nozzle entity is temporarily outside the local client's streaming radius.
* **Session Lifecycle & Cleanup:** Robust garbage collection handling (`playerDropped` and `onResourceStop`) ensuring no orphaned network entities remain detached in the game world.

### 3. Safety Mechanics & Vehicle Logic
* **Nozzle Carrier Safeguards:** Disables vehicle entry controls (`INPUT_VEH_ENTER` / Control `23`) while carrying an attack or refill hose to prevent animation glitches and physics desyncs.
* **Apparatus Immobilization:** Automatically shuts down the vehicle engine (`SetVehicleEngineOn`) and disables throttle/brake inputs (`71`, `72`) for the driver whenever any line is deployed from the apparatus.

### 4. Fluid Simulation & Extinction Mechanics
* **Dynamic Raycasting:** Raycast probes (`StartShapeTestLosProbe`) launched from the nozzle direction to detect line-of-sight impacts and suppress active script fires (`StopFireInRange`).
* **Synchronized Hydrant Supply:** Enables bidirectional water flow—consuming onboard tank capacity during attack operations and refilling when connected to municipal hydrants (`prop_fire_hydrant_*`).

---

## Performance & Optimization

To ensure a steady 60+ FPS while managing up to 600 procedural segments per line:
* **Zero Collision Overhead:** All procedural segments have physics collisions fully disabled (`SetEntityCollision(false)`).
* **Streaming Culling:** Inactive or out-of-range segments are culled from rendering (`SetEntityVisible(false)`).
* **Entity Pooling:** Pre-allocated tables prevent runtime memory churn and garbage collection spikes.

---

## Upcoming Features & Roadmap

- [ ] **Refined 3D Asset:** Upgrade the custom Blender pipe mesh with enhanced topology, baked high-poly textures, and distinct coupling connectors.
- [ ] **Sinusoidal Hose Physics:** Transition from quadratic Bézier approximations to grounded sinusoidal wave equations to accurately simulate hose slack, kinks, and pressurized rigidity.
- [ ] **Comprehensive Network Sync:** Complete multiplayer replication for water jet stream particles across all clients using `isShootingWater`.
- [ ] **Grace-Period Culling (Hysteresis):** Implement a timed decay system before physically deleting entities when players step outside the streaming boundary, preventing micro-stutters during repeated boundary crossing.
- [ ] **Terrain & Ground Collision Conformance:** Sample terrain elevation dynamically using ground probes (`GetGroundZFor_3dCoord`) to drape hose segments over curbs, steps, and uneven surfaces.

---

## Author & Credits

* **Developer:** Bouzaouach Adam
* **3D Modeling & Assets:** Custom assets modeled in Blender
* **Platform:** FiveM / CitizenFX (Lua & OneSync)