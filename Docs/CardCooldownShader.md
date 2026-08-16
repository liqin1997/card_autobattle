# Card Cooldown Sweep

The production effect is split into two UI layers. `CooldownFill` uses standard alpha
blending for the dark/charged surface state. `CooldownFrontFx` uses additive blending
for the moving white core, broad halo, rising wisps, vertical light shafts and glints.
Keeping the luminous front separate prevents the old thick, noisy "rope" look.

## Runtime contract

`BattleCardView` drives `_Progress` from `0` to `1`:

```csharp
progress = 1f - remainingCooldown / totalCooldown;
```

Both shaders interpret UV Y from bottom to top. The front shader evaluates its texture
in `localY = uv.y - _Progress`, so the flowing field remains attached to the rising
boundary. At cooldown completion, `_TriggerFlash` is pulsed from `1` back to `0` while
the card performs its scale punch.

## Packed texture

`Assets/Art/VFX/CardCooldownPackedNoise.asset` is a deterministic, original, seamless 128×128 linear texture used by the surface layer. `Assets/Art/VFX/CardCooldownFrontFlow.asset` is a 256×256 linear, repeatable texture dedicated to the luminous front; its green channel contains vertically directed streaks instead of generic isotropic noise.

- R: multi-octave value noise for the dissolved/wavy boundary.
- G: directional flow bands for charged energy movement.
- B: sparse high-frequency spark mask.
- A: reserved, currently 1.

Both textures are generated in-project and carry no third-party license dependency. The
front layer still samples in progress-local coordinates, so its directed streak texture
moves with the boundary instead of remaining fixed on the card.

## Material controls

| Property | Purpose | Default |
|---|---|---:|
| `_Progress` | bottom-to-top cooldown progress | `0` |
| `_DarkColor` | unready-region dimming tint and alpha | palette-specific |
| `_EnergyColor` | charged-region flowing tint | palette-specific |
| `_EdgeColor` | moving front-line color | palette-specific |
| `_ReadyColor` | sparks and completion flash color | palette-specific |
| `_NoiseScale` | visual frequency | `3.2` |
| `_NoiseStrength` | subtle surface-boundary displacement | `0.005` |
| `_FlowSpeed` | packed texture scroll speed | `0.34` |
| `_EdgeWidth` | faint surface-boundary thickness | `0.006` |
| `_Softness` | boundary antialiasing | `0.004` |
| `_DissolveStrength` | subtle surface breakup | `0.24` |
| `_GlowStrength` | surface-edge brightness | `0.42` |
| `_TriggerFlash` | one-shot completion flash | runtime `0..1` |

`CardCooldownFrontAdditive` adds these main controls:

| Property | Purpose | Default |
|---|---|---:|
| `_CorePixels` | white-hot Gaussian core radius in screen pixels | `0.72` |
| `_InnerPixels` | tight Gaussian glow radius in screen pixels | `2.8` |
| `_GlowAbovePixels` | soft glow radius above the front | `6.5` |
| `_GlowBelowPixels` | longer soft glow radius below the front | `15` |
| `_LineIntensity` | white core intensity | `1.35` |
| `_TrailHeight` | following flow below the line | `0.13` |
| `_HeadHeight` | small rising plume above the line | `0.065` |
| `_FlowTiling` | directed flow texture frequency | `(0.85, 3.2)` |
| `_RiseSpeed` | upward texture motion | `0.85` |
| `_Distortion` | sub-pixel micro-wobble only | `0.002` |
| `_PhaseOffset` | per-card animation variation | runtime `0..1` |

Video calibration (`362×338`, about 30 fps) shows the reference front moving almost
linearly. One unobstructed guitar-card cycle traverses about 61 source pixels in roughly
1.5 seconds. The core remains nearly straight; sparse vertical wisps live for about
2–4 frames. Completion uses a separate top-position flash, so `_FlashProgress` retains
the completed front position while the normal cooldown immediately resets to the bottom.

Player cards use cyan/teal energy. Enemy cards use orange/red energy. The shader includes Unity UI stencil, RectMask clipping, alpha clipping and Canvas vertex tint support.

## Mobile budget

- Shader target: 2.0.
- Each layer uses one packed texture sampler plus the UI main texture.
- No GrabPass, RenderTexture, normal map or scene-color sampling.
- Current prototype creates one material instance per battle card so every card can own `_Progress`; the 18-card cap is acceptable.
- If the board grows substantially, move progress into UV1 and share one material to recover batching.
