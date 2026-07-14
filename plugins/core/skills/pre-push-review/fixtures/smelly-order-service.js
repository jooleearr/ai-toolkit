// Fixture for the code-smell pass (step 4 of ../SKILL.md).
// A deliberately smelly sample: each region below plants one representative
// Fowler smell for the pass to catch. Expected findings are in
// EXPECTED-FINDINGS.md, keyed by the line numbers here — keep them in sync.
// This file is illustrative only; it is not wired into any runtime.

// --- Long Parameter List + Data Clumps ---
// Six parameters, and (street, city, postcode) travel together as a clump.
function createOrder(customerId, sku, quantity, street, city, postcode) {
  const order = {
    customerId,
    sku,
    quantity,
    shipTo: { street, city, postcode },
    status: 'PENDING_PAYMENT', // --- Primitive Obsession: status as a magic string ---
    total: 0,
  };
  return order;
}

// --- Message Chains ---
// A train of accessors couples the caller to the whole object graph.
function shippingCity(order) {
  return order.getCustomer().getProfile().getAddress().getCity();
}

// --- Feature Envy ---
// This function reaches into `customer` far more than into anything of its own.
function formatCustomerLabel(customer) {
  return (
    customer.title +
    ' ' +
    customer.firstName +
    ' ' +
    customer.lastName +
    ' <' +
    customer.email +
    '> (' +
    customer.loyaltyTier +
    ')'
  );
}

// --- Loops (where a pipeline reads clearer) ---
// A hand-rolled accumulate that map/filter/reduce would state directly.
function paidOrderTotals(orders) {
  const result = [];
  for (let i = 0; i < orders.length; i++) {
    if (orders[i].status === 'PAID') {
      result.push(orders[i].total);
    }
  }
  return result;
}

// --- Duplicated Code ---
// Two near-identical blocks differing only in the rate constant.
function priceStandard(order) {
  let t = order.total;
  t = t + t * 0.15;
  t = Math.round(t * 100) / 100;
  return t;
}

function priceExpress(order) {
  let t = order.total;
  t = t + t * 0.25;
  t = Math.round(t * 100) / 100;
  return t;
}

module.exports = {
  createOrder,
  shippingCity,
  formatCustomerLabel,
  paidOrderTotals,
  priceStandard,
  priceExpress,
};
