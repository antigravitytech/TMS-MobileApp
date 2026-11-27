# Sabi Pipu TMS

Flutter mobile app for Sabi Pipu TMS. Mock mode runs the local workspace previews. Live mode connects authentication, account management, workspace enrollment, and profile setup to the backend.

```sh
./tool/bootstrap
./tool/run
```

The launcher creates a local `.env` on first run. Edit it and relaunch to [switch data modes](docs/development.md#environment-configuration). Run `./tool/check` for analysis and tests.

See the [mobile prototype](design/mobile/sabi-pipu-tms-prototype.html) for design, the [architecture guide](docs/mobile-architecture.md) for feature boundaries, and [AGENTS.md](AGENTS.md) for project instructions.
