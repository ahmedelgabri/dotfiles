# Dotfiles tests

Run these commands from the repository root. Offline checks also run through `nix flake check`; live tests are separate because they need network access or desktop services.

## Prayer wrapper

```sh
nix build .#checks.aarch64-darwin.get-prayer
python3 tests/get_prayer_test.py
python3 tests/live/get_prayer_test.py
```

The offline suite tests source selection and argument preservation with a substitute CLI, plus failure propagation with the real `next-prayer` executable. `NEXT_PRAYER_BIN` can select a built executable; otherwise it comes from `PATH`. Python, Bash, jq, and next-prayer are required.

The live E2E test uses both real provider APIs, discovers a mosque near Amsterdam, and checks JSON output and fallback with isolated config and cache directories. It requires `MAWAQIT_USERNAME` and `MAWAQIT_PASSWORD` in the environment. No credentials are written to fixtures or passed as command arguments.

Missing location fields must remain empty rather than shifting subsequent arguments. If both providers fail, the wrapper returns the Aladhan failure status instead of reporting success.
