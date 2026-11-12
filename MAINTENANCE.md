# EtherMail maintenance

This fork is maintained on `main`, based on the upstream `develop` branch of [web3swift](https://github.com/web3swift-team/web3swift). The initial compatibility baseline is release 3.3.2, with the following upstream changes merged while they await an upstream release:

- [PR #910](https://github.com/web3swift-team/web3swift/pull/910): give the HTTP request helper a distinct name and validate the HTTP response type.
- [PR #918](https://github.com/web3swift-team/web3swift/pull/918): replace ambiguous byte-array accesses in HD wallet derivation.

The merge commits retain both contributors' original history. The upstream license and attribution are unchanged.

## Regression checks

The Xcode 27 compatibility workflow runs the offline wallet and HTTP suites. Its dependency fixture at `.github/compatibility/Package.resolved` matches the current app baseline: BigInt 5.4.1, CryptoSwift 1.5.1, and secp256k1.swift 0.10.0.

Run the same checks locally with Xcode 27 selected:

```sh
cp .github/compatibility/Package.resolved Package.resolved
swift test --force-resolved-versions --filter 'localTests\.(BIP32KeystoreTests|BIP32MnemonicPhraseStringTests|BIP32MnemonicPhraseStringArrayTests|BIP44Tests|BIP44ErrorTests|HDversionTest|HTTPCompatibilityTests)'
```

The selected suites do not require a blockchain node or external RPC access. The remaining upstream suites keep their existing setup requirements.

## Updating the fork

1. Review changes from upstream `develop` and merge them into `main`.
2. Keep the dependency fixture aligned with the app when updating dependency versions.
3. Run the compatibility checks and the app's simulator build.
4. Resolve the app's `main` branch dependency and rebuild before shipping updates.

Upstream release tags retain their original meaning. The app tracks this fork's `main` branch for fork-specific fixes.
