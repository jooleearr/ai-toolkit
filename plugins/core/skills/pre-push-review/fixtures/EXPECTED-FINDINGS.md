# Expected findings — `smelly-order-service.js`

The smells the **code-smell pass** (step 4 of [`../SKILL.md`](../SKILL.md)) should surface when the whole of [`smelly-order-service.js`](smelly-order-service.js) is treated as the diff under review. Use this as a fixture: run the pass over the sample and check each row is reported with its `file:line`, the signal that fired, and the paired refactoring — and that nothing outside this list is invented.

Line numbers key into `smelly-order-service.js`.

| # | Smell | Where | Signal | Suggested refactoring |
| :- | :---- | :---- | :----- | :-------------------- |
| 1 | **Long Parameter List** | `createOrder`, line 9 | Six parameters on one function. | Introduce Parameter Object. |
| 2 | **Data Clumps** | `createOrder`, line 9 | `street, city, postcode` travel together. | Introduce Parameter Object / Extract Class — an `Address`. |
| 3 | **Primitive Obsession** | line 15 | Order status carried as a magic string `'PENDING_PAYMENT'`. | Replace Type Code with Subclasses / a status value type. |
| 4 | **Message Chains** | `shippingCity`, line 24 | `getCustomer().getProfile().getAddress().getCity()` — a train of accessors. | Hide Delegate; Extract Function for what the chain computes. |
| 5 | **Feature Envy** | `formatCustomerLabel`, lines 29–42 | Reaches into `customer.*` repeatedly, nothing of its own. | Move Function onto `customer`. |
| 6 | **Loops** | `paidOrderTotals`, lines 46–54 | Hand-rolled filter+map accumulate. | Replace Loop with Pipeline (`filter` then `map`). |
| 7 | **Duplicated Code** | `priceStandard` / `priceExpress`, lines 58–70 | Two blocks identical but for the rate constant. | Extract Function parameterised by the rate. |

## Precision check

These should **not** be flagged — they exercise the precision-over-recall rule:

- The `let t` / `let result` locals are conventional accumulators, not a **Mutable Data** smell worth a finding.
- `module.exports` at the foot is idiomatic, not a **Lazy Element**.

A pass that flags either of the above is over-firing; tighten toward the diff-scoped, high-precision behaviour the catalogue asks for.
