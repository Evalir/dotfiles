# Mac security remediation runbook — October 2026

Use this checklist for the October Node, browser, and certificate-trust updates.
Machine-specific findings, backups, and remaining exposures belong in the private
operations record. This document neither provisions a machine nor certifies every
installed application or project dependency.

## Preserve state and repair trust

1. Record package versions, running executable versions, shell runtime selection,
   firewall exceptions, and listener addresses. Preserve existing repository work.
2. Back up CA files with their permissions, shell aliases, application configuration,
   and consistent databases in a private directory. Keep secrets and backups out of Git.
3. Obtain updates over an independently trusted path. Validate vendor signatures or
   reviewed integrity data; a checksum fetched through the same affected trust store
   is insufficient on its own.
4. Install a fixed Homebrew CA package and certifi 2026.10.19 or later. Inventory each
   Python interpreter and environment separately; updating one does not update all.
   Check pip's vendored roots and whether its configured CA file applies to the
   invocation being used.
5. For the system curl bundle, prefer Apple's update. If a manual mitigation is
   necessary, review the certificate incident guidance, back up the exact original,
   and remove only the implicated roots. Preserve ownership and permissions. Never
   disable certificate verification to make an update work.

Homebrew can expand a targeted upgrade into dependent upgrades. Review the proposed
work and use these controls when unrelated upgrades must be excluded:

```sh
env HOMEBREW_NO_INSTALLED_DEPENDENTS_CHECK=1 HOMEBREW_NO_INSTALL_CLEANUP=1 HOMEBREW_NO_AUTO_UPDATE=1 brew upgrade --formula ca-certificates
```

These settings do not prevent installation of dependencies required by the target.
Do not trust unrelated taps or remove Command Line Tools to bypass an unrelated
package-manager failure. Check the resulting installed and running software directly.

## Update consumers independently

- Select a patched Node release: 22.23.4, 24.22.1, or 26.12.1 are the October security
  baselines for their release lines. Respect project major-version constraints.
  Check fresh fish/zsh sessions, noninteractive commands, absolute-path consumers,
  and launch services separately. Existing terminals can retain an old PATH.
- Update browser applications through official vendor distributions. Preserve tabs
  before relaunch; validate downloaded applications' developer signatures and
  notarization. Inspect the running engine after relaunch, including Chromium-based
  browsers with independent update schedules.
- Inspect applications that bundle Node independently of the shell runtime. A new
  Homebrew Node does not patch them. Use a vendor release; never substitute binaries
  inside signed applications. Record unavailable fixes explicitly. A CA mitigation
  does not resolve the separate Brotli runtime vulnerability.
- Bind local dashboards to loopback. Back up their configuration and database before
  upgrade. Rehearse migrations on a database copy and a separate loopback port; verify
  dashboard documents, data sources, authentication, and health before the live restart.
- Enable the application firewall after reviewing existing exceptions. Confirm remote
  administration and required services still work.

## Verify results

For each relevant curl, Node, and Python client, test both compromised-chain endpoints
and a normal trusted HTTPS endpoint:

```sh
curl -q -I --max-time 10 https://dv-g3b-emudhra.we-have-a-problem.com/
curl -q -I --max-time 10 https://dv-g3b-aaa-noct-emudhra.we-have-a-problem.com/
curl -q -I --max-time 10 https://nodejs.org
```

The first two requests must fail with certificate-validation errors (curl exit 60);
the third must succeed. A timeout, DNS error, or reset is inconclusive. Confirm the
actual serving chain when interpreting results, since test infrastructure can change.

For a Homebrew Node 24 installation and local Grafana service:

```sh
/opt/homebrew/opt/node@24/bin/node --version
env PATH=/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin /bin/zsh -lic 'command -v node; node --version'
env PATH=/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin /opt/homebrew/bin/fish -lc 'command -s node; node --version'
/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate
/usr/sbin/lsof -nP -iTCP:3000 -sTCP:LISTEN
curl -q --max-time 10 http://127.0.0.1:3000/api/health
curl -q -o /dev/null -w '%{http_code}\n' http://127.0.0.1:3000/api/search
```

Require a patched Node release in each context, firewall state 1, a loopback-only
Grafana listener, healthy database, and 401 for unauthenticated protected API access.
Attempt a connection to the dashboard port from a separate machine. Exercise actual
development tools and check their processes, not only installer output.

## Recovery

Restore a dashboard's matching binary, database, and configuration together, retaining
its loopback-only listener. Do not restore compromised CA roots as a routine rollback;
diagnose the failing certificate chain instead. Retained old runtimes can help recover
project compatibility, but selecting them reintroduces their known vulnerabilities.
Keep blocked vendor updates and untested consumers visible in the private record.

## References

- [Node October security releases](https://nodejs.org/en/blog/vulnerability/october-2026-security-releases)
- [Certificate incident and validation endpoints](https://emudhra.we-have-a-problem.com/)
- [Chrome October 20 security update](https://chromereleases.googleblog.com/2026/10/stable-channel-update-for-desktop_02018666648.html)
