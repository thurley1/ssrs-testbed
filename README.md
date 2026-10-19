# `ssrs-testbed`

The committed fixture for spec `354` — the SSRS report parser.

**Asserted exactly. Never mutate it casually** — the same rule the other testbeds carry.

## Why reports matter, and what this fixture cannot prove

Reports are the **downstream end of the lineage**. A table that no CLI tool and no SSIS package reads
may still be read by six reports, and until the reports are parsed that table looks unused — so *"which
of these tables can we stop maintaining"* is a question the analysis cannot answer honestly without
them.

**There is no `.rdl` in any of the estate's three repositories.** This fixture's shape is authored from
published RDL schema versions, so it proves the **mechanism**, never this estate's real reports.
Confirmation is spec `361`'s, and the acquisition that produces real input at all is `352`'s.

One correction to the spec worth recording: `354` said "the namespace is shared across RDL versions, the
version attribute is the only discriminator". That is not how RDL works — the **namespace URI itself**
carries the version, and `Report` has no version attribute. Discriminating on the namespace is both
simpler and correct, and it delivers what the criterion reached for: three distinguishable answers.

## Files

| Path | Holds |
|---|---|
| `Reports/OpenOrders.rdl` | The main report: 6 datasets, 2 parameters, an embedded connection string with a plaintext password |
| `Reports/RevenueByRegion.rdl` | References a shared data source **that is in this tree** |
| `Reports/StaleReference.rdl` | References a shared data source **that is not** |
| `Reports/Malformed.rdl` | Unclosed element — partial with its reason, never a throw |
| `Reports/AncientSchema.rdl` | A 2003 schema namespace, outside the supported set |
| `Reports/notareport.xml` | Ordinary XML. Must **not** be claimed |
| `Shared/OrdersShared.rds` | The shared data source, integrated security (so **no** password) |
| `Database/schema.sql` | The tables and the procedure the reports read |

## Counts, through the resolved parser set

One project, `SSRS (reports)`, language `SSRS`:

| | Count |
|---|---|
| Types | **5** |
| — reports read | 3 |
| — markers for a report that could not be read | 2 |
| Members | **10** (8 on `OpenOrders`, 1 each on the other two) |
| Edges | **7** |
| — `TableRead` | 6 |
| — `ProcedureCall` | 1 |
| Data sources for `349`'s inventory | **4** (3 resolved, 1 unresolved) |

Edge kinds are **reused, not minted**: a SQL dataset *reads* its tables (`TableRead`, spec 351) and a
procedure-backed dataset *executes* its procedure (`ProcedureCall`). SSRS-specific twins would hand spec
`357`'s lineage two vocabularies for one relationship — the mistake `350` avoided by reusing
`DataAccess`/`FileUsage`.

Every dataset member carries `Kind = "Method"` with a **null body**, and every parameter `Kind =
"Field"`. The dataset kind is deliberate: the natural word `"Dataset"` is outside the quality
denominator, so it would drop every report out of complexity, the quality gate and the hotspot list —
and that presents as *clean code* rather than as an error.

## The planted answer key

### The four kinds of dataset command

| Dataset | Command | Yields |
|---|---|---|
| `OpenOrderLines` | SQL text | reads `Orders`, `OrderLines` |
| `CustomerLookup` | SQL, **`CommandType` omitted** | reads `Customers` — RDL defaults to `Text`, so an absent `CommandType` is SQL rather than unknown; treating it as unknown would make most real reports unresolved |
| `OrderSummary` | `StoredProcedure` | a `ProcedureCall` to `usp_LoadOrders`, and **no tables** |
| `DynamicPivot` | an expression (`="SELECT * FROM " & …`) | **nothing**, recorded unresolved with its reason |
| `Placeholder` | no command at all | **nothing**, unresolved for a *different* reason |

**`OrderSummary` is the load-bearing hop for the whole lineage claim.** A proc-backed dataset never
names its tables, so the only route from the report to the data is through the procedure — and that
means a spelling mismatch with how `351` emits a procedure type deletes the finding *silently*. The
procedure is in this corpus (`Database/schema.sql`) precisely so the hop can be asserted against what
`SqlSchemaParser` actually emits rather than against a literal.

### "No reports read this table" vs "no reports we could resolve read it"

**Two datasets in this fixture cannot be resolved** — the expression and the empty one — and each
carries its reason on the dataset member. That count is what keeps those two statements apart.

Without it, this spec's own headline (*a table nothing reads still feeds six reports*) licenses the
inverse conclusion — *stop maintaining this table* — from an unmeasured absence. That is the
not-measured-is-not-zero rule this codebase has already paid for twice.

### Shared data sources — resolving and genuinely missing

| Report | Reference | Outcome |
|---|---|---|
| `RevenueByRegion` | `/Shared/OrdersShared` | **resolves** to `sql01/Orders` |
| `StaleReference` | `/Shared/DecommissionedWarehouse` | **unresolved**, naming what it looked for |

The pair is the point: a reference that resolves must not report as missing, and one that is genuinely
missing must not quietly resolve to nothing. It decides whether the report appears in the connection
inventory at all.

Note the reference is a **report-server path**, which has no relationship to where the `.rds` sits on
disk — so resolution matches on the data source's **name**. Matching on the path would resolve nothing,
and resolving nothing reads as every shared source in the estate being missing.

**A report that uses a shared credential is a usage of it.** `OrdersShared.rds` declares the credential
and `RevenueByRegion` consumes it, so `349`'s inventory sees **two** usages of that one credential. One
password shared by a package, a tool and three reports is `349`'s headline finding, and it only appears
if each consumer counts.

### The credential, and where it must not go

`OpenOrders.rdl` embeds a connection string with a plaintext password. `.rdl` files really do carry
these inline, and `352` confirms `ReportServer`'s `DataSource` table holds stored credentials.

`SsrsDataSourceRecord` has **no field that could carry a connection string** — asserted over its
property list, the shape `SsisConnectionRecord` established — and the salted fingerprint is computed
**inside the reader**, where the string still exists. Matched on server, database and user alone, a data
source could not be told from a *different* credential on the same database, so the reports would
contribute nothing to the dedup deliverable.

`OrdersShared.rds` uses integrated security, so the inventory must report **no** password for it. A
reader that labelled every data source as credentialed would manufacture findings from Windows auth.

### The three ways a report is unreadable

| Report | Answer |
|---|---|
| `Malformed.rdl` | not well-formed XML — partial with that reason |
| `AncientSchema.rdl` | a 2003 namespace — partial **naming the schema it found**, plus an `unsupported-rdl-version` modifier |
| `notareport.xml` | **not claimed at all** |

The second is a different answer from the first: the document is fine and we cannot vouch for its
element paths. A wrong supported set then **over**-reports partial parses — which is visible — instead of
silently mis-parsing reports into a lineage diagram that reads as complete.

Both unreadable reports still reach the model as types carrying their reason, because emitting nothing
makes an unreadable report indistinguishable from an estate that has none.

### Provenance independence

The parser reads `.rdl` files off disk and knows nothing about where they came from, so a report
recovered from `352`'s `ReportServer.Catalog` extract parses identically to one committed in a
repository. That is a property of the entry point, not a behaviour that needs testing twice — which is
what lets the criterion be proven here rather than in the container-gated suite.
