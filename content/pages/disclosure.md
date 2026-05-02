+++
title = "Disclosure Policy"
path = "disclosure"
+++

Coordinated disclosure. The goal is fixing vulnerabilities, not racing exploits to publication.

## Contact

- Email: <enderaoelyther@gmail.com>
- PGP key: pending — until published, send only minimal trigger details over plaintext and request a key exchange.

## Timeline

- **Day 0**: Private report sent to vendor with reproduction steps and impact analysis.
- **Day 0–90**: Vendor triage, fix development, patch validation. Status syncs at least every 14 days.
- **Day 90**: Default public disclosure deadline, regardless of patch status, unless a written extension is mutually agreed.
- **Earlier disclosure** if the issue is being exploited in the wild, the vendor publicly downplays severity, or the vendor stops responding for 14+ days.

## What gets published

- Root cause, affected versions, mitigations.
- Proof-of-concept sufficient to verify the fix — never weaponized exploit code aimed at unpatched users.
- Credit to vendor security teams that engaged in good faith.

## What does not get published

- Live customer data, internal credentials, or anything obtained outside the scope of the report.
- Exploit chains for CVEs whose patches have not yet shipped to the majority of affected users.

## Bug bounties

Bounty payments are accepted but never traded for silence beyond the timeline above.
