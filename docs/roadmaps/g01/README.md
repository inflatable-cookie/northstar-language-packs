# g01 — Official Package Source

## Generation Runway

| Goal | State | Governing refs | Frontier |
| --- | --- | --- | --- |
| Establish independent official package source and immutable release evidence. | shipped | `docs/architecture/system-architecture.md`, `docs/contracts/001-working-rules.md` | Northstar-owned registry promotion |
| Add later language packages without widening every installed payload. | shipped | Northstar `g02.048/119` | Northstar-owned Convergence canary |

## Shipped Outcomes

- `@northstar/typescript-quality` `0.1.0` under `packages/typescript`.
  Merged as `09ef174`, invocation-repaired as `d18dc33b`, adapter-closed in
  PR 3 (`c9ef2a2`). Tree
  `sha256:259cccdbacd7e2e293389efaf72cab005d0c275bd7cb600c99f30bfbfe071843`,
  manifest
  `sha256:e5e32f2baeda2e901b8c327436adf0bfd5955a9de080887660684ad4583185ca`.
- `@northstar/rust-quality` `0.1.0` under `packages/rust`. Merged in PR 4
  (`56b2e11`). Tree
  `sha256:e5cf9c5da4a30c0f5164f2ea0c5e9d87d544c0c32f09f3c139a386c56154dba0`,
  manifest
  `sha256:dd71d04efd67cc7805f417a79666dd920ea1811ee252d941108dfbeca8aab612`.
- Full proof maps live in `docs/logs/2026-09/`.

## Queue lifecycle adoption

- [g01.001 Effigy-hosted lifecycle hook](001-adopt-effigy-hosted-lifecycle-hook.md)
  is an operator-approved, configuration-only maintenance lane. It follows its
  declared Queue dependencies and may run without changing product priority.
  Existing next-task text continues to describe product sequencing; this entry
  authorizes no sibling product work.

## Next Task

No active Northstar task. Both package outcomes are merged; registry
promotion and the Convergence canary are Northstar-owned lanes. This
repository dispatches nothing until Northstar returns a new pinned source
boundary.
<!-- northstar:lifecycle:begin schema=northstar.lifecycle.projection.v2 digest=sha256:5b1153631abb9501746b1717eafd111b237aa404914005501e34751642f092cf -->
| Generation | Disposition | Runway state |
| --- | --- | --- |
| g01 | open | planning_required |
| Task | Status | Stage | Revision | Record digest |
| --- | --- | --- | --- | --- |
| g01.001 | complete | none | 8 | sha256:245f4b30e07c4306fc10dc69e74783c10ab4c99d1f29b338bc14045c4677d949 |
<!-- northstar:lifecycle:end -->
