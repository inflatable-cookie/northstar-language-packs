# Vision

This repository is the public source and release-evidence home for official
Northstar language-quality packages. It serves Northstar core and the consumers
that install those packages, and it must never make a consumer install or load a
language it did not request.

## What it does

- Holds one independently addressable package per language under
  `packages/<language>`.
- Keeps each package's manifest, compatibility range, content digest, release
  evidence, and installed payload its own.
- Shares maintenance infrastructure across packages without sharing payloads.

## Success

- A consumer installs exactly one language package and receives exactly that
  package's content.
- Every published package has an immutable commit and an exact content digest.
- Adding a language never widens an installed payload.

## Not this

- Not Northstar core. Discovery, trust, installation, activation, and routing
  protocol are owned upstream.
- Not a consumer profile, deviation, or evidence home. Those stay with the
  consumer repository.
- Not a monolith: repository growth must not force a consumer to carry every
  language.
