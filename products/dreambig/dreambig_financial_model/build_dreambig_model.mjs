import fs from "node:fs/promises";
import { SpreadsheetFile, Workbook } from "@oai/artifact-tool";

const outputDir = "/Users/rossegates/Documents/desktop automation/outputs/dreambig_financial_model";
const workbook = Workbook.create();

const actualYear = 2025;
const forecastYear = 2026;
const weeksPerYear = 52;
const revenueRows = weeksPerYear * 2 * 5 * 4;
const inventoryRows = weeksPerYear * 2 * 5;
const marketingRows = weeksPerYear * 2 * 4;
const opexRows = 24 * 16;
const swRows = 24 * 5;

const colors = {
  navy: "#17365D",
  blue: "#1F4E78",
  lightBlue: "#D9EAF7",
  teal: "#0F766E",
  green: "#008000",
  red: "#FF0000",
  gray: "#F3F6F8",
  darkGray: "#666666",
  inputYellow: "#FFF2CC",
  header: "#17365D",
  white: "#FFFFFF",
  black: "#000000",
  border: "#D9E2EA",
  warning: "#FCE4D6",
  ok: "#E2F0D9",
};

const fmt = {
  money: '$#,##0;[Red]($#,##0);-',
  money1: '$#,##0.0;[Red]($#,##0.0);-',
  pct: '0.0%;[Red](0.0%);-',
  num: '#,##0;[Red](#,##0);-',
  num1: '#,##0.0;[Red](#,##0.0);-',
  date: 'yyyy-mm-dd',
};

function addSheet(name) {
  const ws = workbook.worksheets.add(name);
  ws.showGridLines = false;
  return ws;
}

function col(n) {
  let s = "";
  while (n > 0) {
    const m = (n - 1) % 26;
    s = String.fromCharCode(65 + m) + s;
    n = Math.floor((n - m) / 26);
  }
  return s;
}

function addr(row, colIndex) {
  return `${col(colIndex)}${row}`;
}

function rangeAddr(r1, c1, r2, c2) {
  return `${addr(r1, c1)}:${addr(r2, c2)}`;
}

function quoteSheet(name) {
  return `'${name}'`;
}

function setTitle(ws, title, subtitle = null, lastCol = 10) {
  ws.getRange(rangeAddr(1, 1, 1, lastCol)).merge();
  ws.getRange("A1").values = [[title]];
  ws.getRange("A1").format = {
    fill: colors.navy,
    font: { bold: true, color: colors.white, size: 16 },
    horizontalAlignment: "left",
  };
  ws.getRange("A1").format.rowHeight = 28;
  if (subtitle) {
    ws.getRange(rangeAddr(2, 1, 2, lastCol)).merge();
    ws.getRange("A2").values = [[subtitle]];
    ws.getRange("A2").format = {
      fill: colors.lightBlue,
      font: { italic: true, color: colors.black },
      wrapText: true,
    };
  }
}

function styleHeader(range) {
  range.format = {
    fill: colors.header,
    font: { bold: true, color: colors.white },
    horizontalAlignment: "center",
    borders: { preset: "outside", style: "thin", color: colors.border },
  };
}

function styleSection(range, color = colors.blue) {
  range.format = {
    fill: color,
    font: { bold: true, color: colors.white },
    borders: { preset: "outside", style: "thin", color: colors.border },
  };
}

function addTable(ws, address, name, style = "TableStyleMedium2") {
  const table = ws.tables.add(address, true, name);
  table.style = style;
  table.showFilterButton = true;
  return table;
}

function dateUtc(year, month, day) {
  return new Date(Date.UTC(year, month - 1, day));
}

function addDays(date, days) {
  return new Date(date.getTime() + days * 86400000);
}

function monthStart(d) {
  return new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), 1));
}

function monthLabel(d) {
  return d.toLocaleString("en-US", { month: "short", year: "numeric", timeZone: "UTC" });
}

function excelDateString(d) {
  return d.toISOString().slice(0, 10);
}

const skus = [
  {
    sku: "DB-101",
    name: "AeroSip Bottle",
    behavior: "One-time purchase",
    seasonal: "No",
    seasonality: "None",
    status: "Active",
    launch: dateUtc(2024, 12, 1),
    discontinue: null,
    price: 29,
    unitCost: 8.4,
    packaging: 1.15,
    inbound: 0.9,
    duty: 0.35,
    returnRate: 0.045,
    warrantyRate: 0.012,
    warrantyCost: 3,
    startInv: 12000,
    moq: 4500,
    leadWeeks: 8,
    safetyWeeks: 6,
    trafficWeight: 0.26,
    convMult: 0.95,
  },
  {
    sku: "DB-102",
    name: "GlowPatch Balm",
    behavior: "Consumable repeat",
    seasonal: "No",
    seasonality: "None",
    status: "Active",
    launch: dateUtc(2024, 12, 1),
    discontinue: null,
    price: 18,
    unitCost: 4.2,
    packaging: 0.65,
    inbound: 0.42,
    duty: 0.14,
    returnRate: 0.025,
    warrantyRate: 0.004,
    warrantyCost: 1.5,
    startInv: 24000,
    moq: 9000,
    leadWeeks: 6,
    safetyWeeks: 5,
    trafficWeight: 0.21,
    convMult: 1.18,
  },
  {
    sku: "DB-103",
    name: "EmberTrail Camp Mug",
    behavior: "One-time purchase",
    seasonal: "Yes",
    seasonality: "Winter peak",
    status: "Discontinued in forecast",
    launch: dateUtc(2024, 12, 1),
    discontinue: dateUtc(2026, 11, 30),
    price: 34,
    unitCost: 10.8,
    packaging: 1.35,
    inbound: 1.1,
    duty: 0.42,
    returnRate: 0.055,
    warrantyRate: 0.016,
    warrantyCost: 3.5,
    startInv: 10000,
    moq: 5000,
    leadWeeks: 9,
    safetyWeeks: 7,
    trafficWeight: 0.18,
    convMult: 0.9,
  },
  {
    sku: "DB-104",
    name: "SunNest Cooling Towel",
    behavior: "Consumable repeat",
    seasonal: "Yes",
    seasonality: "Summer peak",
    status: "Discontinued in forecast",
    launch: dateUtc(2024, 12, 1),
    discontinue: dateUtc(2026, 8, 31),
    price: 42,
    unitCost: 12.6,
    packaging: 1.05,
    inbound: 1.0,
    duty: 0.4,
    returnRate: 0.05,
    warrantyRate: 0.01,
    warrantyCost: 2.8,
    startInv: 9000,
    moq: 4800,
    leadWeeks: 7,
    safetyWeeks: 6,
    trafficWeight: 0.17,
    convMult: 0.92,
  },
  {
    sku: "DB-105",
    name: "DreamFuel Refill Pack",
    behavior: "Subscription",
    seasonal: "No",
    seasonality: "None",
    status: "Active",
    launch: dateUtc(2024, 12, 1),
    discontinue: null,
    price: 56,
    unitCost: 15.4,
    packaging: 1.45,
    inbound: 1.25,
    duty: 0.52,
    returnRate: 0.02,
    warrantyRate: 0.003,
    warrantyCost: 1.2,
    startInv: 8500,
    moq: 6000,
    leadWeeks: 6,
    safetyWeeks: 5,
    trafficWeight: 0.18,
    convMult: 1.08,
  },
];

const channels = [
  { channel: "Shopify DTC", customerType: "Consumer", mix: 0.5, discount: 0.08, processor: 0.029, marketplace: 0, cpc: 0.78, conversionMult: 1.0, shipCost: 6.4, shipCharged: 2.25, pickPack: 1.65, termsDays: 2 },
  { channel: "Amazon Marketplace", customerType: "Marketplace Consumer", mix: 0.25, discount: 0.05, processor: 0, marketplace: 0.15, cpc: 0.92, conversionMult: 1.18, shipCost: 5.2, shipCharged: 0, pickPack: 2.15, termsDays: 14 },
  { channel: "Wholesale", customerType: "Retailer", mix: 0.15, discount: 0.35, processor: 0, marketplace: 0, cpc: 0.2, conversionMult: 0.55, shipCost: 2.3, shipCharged: 0, pickPack: 0.85, termsDays: 45 },
  { channel: "TikTok Shop", customerType: "Social Commerce", mix: 0.1, discount: 0.12, processor: 0.029, marketplace: 0.06, cpc: 0.62, conversionMult: 1.26, shipCost: 6.1, shipCharged: 1, pickPack: 1.75, termsDays: 7 },
];

const geos = [
  { geo: "US West", mix: 0.34 },
  { geo: "US Central", mix: 0.24 },
  { geo: "US East", mix: 0.32 },
  { geo: "Canada", mix: 0.1 },
];

const months = [];
for (const year of [actualYear, forecastYear]) {
  for (let m = 1; m <= 12; m++) {
    const d = dateUtc(year, m, 1);
    months.push({ date: d, label: monthLabel(d), period: year === actualYear ? "Actual" : "Forecast" });
  }
}

const weeks = [];
for (const config of [
  { year: actualYear, start: dateUtc(actualYear, 1, 6), period: "Actual" },
  { year: forecastYear, start: dateUtc(forecastYear, 1, 5), period: "Forecast" },
]) {
  for (let i = 0; i < weeksPerYear; i++) {
    const d = addDays(config.start, i * 7);
    weeks.push({
      weekNo: i + 1,
      date: d,
      month: monthStart(d),
      monthLabel: monthLabel(monthStart(d)),
      period: config.period,
    });
  }
}

const scenarioRows = [
  ["Downside", 0.85, 0.93, 1.08, 1.08, 1.08, 0.92, 0.96, "Lower traffic/conversion, higher unit and shipping costs"],
  ["Base", 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, "Management base case"],
  ["Upside", 1.18, 1.06, 0.97, 0.96, 0.98, 1.08, 1.04, "Better traffic/conversion and modest operating leverage"],
];

const opexAccounts = [
  ["Sales", "Sales team payroll", "Payroll", "Fixed", "Cash", 48],
  ["Sales", "Retail broker commissions", "Commissions", "Variable", "Cash", 9],
  ["Marketing", "Brand agency retainer", "Services", "Fixed", "Cash", 22],
  ["Marketing", "Creative production", "Services", "Variable", "Cash", 18],
  ["Operations", "Ops team payroll", "Payroll", "Fixed", "Cash", 62],
  ["Operations", "Warehouse rent", "Facilities", "Fixed", "Cash", 28],
  ["Operations", "Inventory systems", "Software", "Fixed", "Cash", 7],
  ["Product", "Product team payroll", "Payroll", "Fixed", "Cash", 36],
  ["Product", "QA and inspections", "Services", "Variable", "Cash", 6],
  ["G&A", "Executive payroll", "Payroll", "Fixed", "Cash", 58],
  ["G&A", "Finance and accounting", "Professional fees", "Fixed", "Cash", 14],
  ["G&A", "Legal", "Professional fees", "Fixed", "Cash", 8],
  ["G&A", "Insurance", "Insurance", "Fixed", "Cash", 6],
  ["G&A", "Software and admin tools", "Software", "Fixed", "Cash", 12],
  ["Customer Support", "Support payroll", "Payroll", "Fixed", "Cash", 24],
  ["Customer Support", "Support variable tools", "Support", "Variable", "Cash", 5],
];

const cover = addSheet("Cover");
const assumptions = addSheet("Assumptions");
const skuSheet = addSheet("SKU_Master");
const channelSheet = addSheet("Channel_Assumptions");
const revenue = addSheet("Revenue_Model");
const geoView = addSheet("Geo_Revenue_View");
const inventory = addSheet("Inventory_Model");
const shipping = addSheet("Shipping_Warehouse");
const marketing = addSheet("Marketing");
const opex = addSheet("Headcount_Opex");
const financial = addSheet("Financial_Model");
const board = addSheet("Monthly_Board");
const scenarios = addSheet("Scenarios");
const sensitivity = addSheet("Sensitivity");
const checks = addSheet("Checks");
const sources = addSheet("Sources");

// Assumptions
setTitle(assumptions, "DreamBig Ecommerce Model Assumptions", "Blue/yellow cells are editable drivers. Forecast formulas use the scenario selector and all cost/revenue assumptions from this tab.", 10);
assumptions.getRange("A4:D4").values = [["Model Control", "Value", "Units", "Notes"]];
styleHeader(assumptions.getRange("A4:D4"));
assumptions.getRange("A5:D22").values = [
  ["Company", "DreamBig", "Text", "Existing ecommerce company"],
  ["Currency Units", "$000s", "Text", "Financial outputs are shown in thousands"],
  ["Forecast Start", dateUtc(forecastYear, 1, 1), "Date", "Forecast year begins in January"],
  ["Historic Period", `${actualYear} actual weekly data`, "Text", "Seeded illustrative actuals to be replaced with real operating exports"],
  ["Forecast Period", `${forecastYear} forecast weekly data`, "Text", "Formula-driven forecast"],
  ["Scenario Selector", "Base", "Case", "Valid cases: Downside, Base, Upside"],
  ["Base Weekly Traffic", 46000, "Sessions", "Total weekly traffic before channel/SKU/geo mix"],
  ["Base Conversion Rate", 0.036, "%", "Site/order conversion before channel and SKU modifiers"],
  ["Actual Year Traffic Ramp", 0.18, "%", "Illustrative actuals ramp from lower base through historic year"],
  ["Forecast Growth", 0.22, "%", "Annual traffic lift in forecast year before scenario"],
  ["Free Shipping Threshold", 50, "$", "Assumed blended customer shipping recovery"],
  ["Benefits + Payroll Tax", 0.24, "% of payroll", "Used for payroll-loaded opex"],
  ["Tax Rate", 0.21, "%", "Simplified cash tax assumption"],
  ["Starting Cash", 1650, "$000s", "Opening cash balance"],
  ["Debt Balance", 750, "$000s", "Illustrative working capital facility"],
  ["Debt Interest Rate", 0.095, "%", "Annual cash interest"],
  ["Capex / Tooling Monthly", 18, "$000s", "Maintenance tooling and warehouse improvements"],
  ["Warehouse Storage / Unit / Week", 0.04, "$/unit/week", "Storage cost applied to average ending inventory"],
];
assumptions.getRange("B7:B22").format = { fill: colors.inputYellow, font: { color: "#0000FF" } };
assumptions.getRange("B10").dataValidation = { rule: { type: "list", values: ["Downside", "Base", "Upside"] } };
assumptions.getRange("B10").format = { fill: colors.inputYellow, font: { color: "#0000FF", bold: true } };
assumptions.getRange("B9:B10").setNumberFormat(fmt.num);
assumptions.getRange("B11:B12").setNumberFormat(fmt.pct);
assumptions.getRange("B16").setNumberFormat(fmt.money);
assumptions.getRange("B18:B19").setNumberFormat(fmt.pct);
assumptions.getRange("B20:B21").setNumberFormat(fmt.money);
assumptions.getRange("B22").setNumberFormat("$0.00");

assumptions.getRange("F4:J4").values = [["Color Legend", "Meaning", "Example", "Owner", "Action"]];
styleHeader(assumptions.getRange("F4:J4"));
assumptions.getRange("F5:J8").values = [
  ["Blue font / yellow fill", "Editable inputs", "Scenario Selector", "Management", "Update"],
  ["Black font", "Formulas/calculations", "Monthly board output", "Model", "Do not hardcode"],
  ["Green font", "Cross-sheet links", "Financial_Model to Board", "Model", "Audit"],
  ["Red font", "External links", "None used", "Model", "Avoid"],
];
assumptions.getRange("F5:F8").format = { fill: colors.inputYellow, font: { color: "#0000FF" } };

assumptions.getRange("A25:J25").values = [["Seasonality Table", "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep"]];
styleSection(assumptions.getRange("A25:J25"));
assumptions.getRange("A26:J28").values = [
  ["None", 1, 1, 1, 1, 1, 1, 1, 1, 1],
  ["Summer peak", 0.75, 0.78, 0.88, 1.05, 1.28, 1.45, 1.42, 1.18, 0.98],
  ["Winter peak", 1.22, 1.08, 0.92, 0.82, 0.78, 0.75, 0.78, 0.86, 0.98],
];
assumptions.getRange("K25:N25").values = [["Oct", "Nov", "Dec", "Notes"]];
styleSection(assumptions.getRange("K25:N25"));
assumptions.getRange("K26:N28").values = [
  [1, 1, 1, "Baseline demand"],
  [0.88, 0.78, 0.72, "Summer SKU demand peaks in Jun/Jul"],
  [1.18, 1.42, 1.55, "Winter SKU demand peaks in Nov/Dec"],
];
assumptions.getRange("B26:M28").setNumberFormat("0.00x");

assumptions.getRange("A31:C31").values = [["Geography", "Traffic Mix", "Notes"]];
styleHeader(assumptions.getRange("A31:C31"));
assumptions.getRange("A32:C35").values = geos.map((g) => [g.geo, g.mix, "Editable geography mix for sortable revenue detail"]);
assumptions.getRange("B32:B35").setNumberFormat(fmt.pct);
assumptions.getRange("B32:B35").format = { fill: colors.inputYellow, font: { color: "#0000FF" } };
addTable(assumptions, "A31:C35", "GeoMixTable", "TableStyleMedium4");

// Scenarios
setTitle(scenarios, "Scenario Drivers", "Scenario multipliers feed traffic, conversion, unit cost, shipping, opex, and pricing assumptions.", 10);
scenarios.getRange("A4:I4").values = [["Scenario", "Traffic Mult.", "Conversion Mult.", "COGS Mult.", "Shipping Mult.", "Opex Mult.", "Marketing Efficiency", "Price Mult.", "Notes"]];
styleHeader(scenarios.getRange("A4:I4"));
scenarios.getRange("A5:I7").values = scenarioRows;
scenarios.getRange("B5:H7").setNumberFormat("0.00x");
scenarios.getRange("A5:H7").format = { fill: colors.inputYellow, font: { color: "#0000FF" } };
addTable(scenarios, "A4:I7", "ScenarioTable", "TableStyleMedium4");

// SKU Master
setTitle(skuSheet, "SKU Master", "Each product has editable price, manufacturing, fulfillment, return, inventory, and lifecycle assumptions.", 18);
const skuHeaders = [
  "SKU", "Product", "Behavior", "Seasonal?", "Seasonality", "Status", "Launch Date", "Discontinue Date", "ASP $",
  "Mfg Cost $", "Packaging $", "Inbound Freight $", "Duty $", "Fully Loaded Unit Cost $", "Return Rate",
  "Warranty Rate", "Warranty Cost $", "Starting Inventory Units", "MOQ Units", "Lead Time Weeks",
  "Safety Stock Weeks", "Traffic Weight", "Conversion Mult."
];
skuSheet.getRange(rangeAddr(4, 1, 4, skuHeaders.length)).values = [skuHeaders];
styleHeader(skuSheet.getRange(rangeAddr(4, 1, 4, skuHeaders.length)));
const skuData = skus.map((s) => [
  s.sku, s.name, s.behavior, s.seasonal, s.seasonality, s.status, s.launch, s.discontinue, s.price,
  s.unitCost, s.packaging, s.inbound, s.duty, null, s.returnRate, s.warrantyRate, s.warrantyCost,
  s.startInv, s.moq, s.leadWeeks, s.safetyWeeks, s.trafficWeight, s.convMult
]);
skuSheet.getRange(rangeAddr(5, 1, 9, skuHeaders.length)).values = skuData;
for (let r = 5; r <= 9; r++) {
  skuSheet.getRange(`N${r}`).formulas = [[`=SUM(J${r}:M${r})`]];
}
skuSheet.getRange("G5:H9").setNumberFormat(fmt.date);
skuSheet.getRange("I5:N9").setNumberFormat("$0.00");
skuSheet.getRange("O5:P9").setNumberFormat(fmt.pct);
skuSheet.getRange("Q5:Q9").setNumberFormat("$0.00");
skuSheet.getRange("R5:U9").setNumberFormat(fmt.num);
skuSheet.getRange("V5:W9").setNumberFormat("0.00x");
skuSheet.getRange("I5:W9").format = { fill: colors.inputYellow, font: { color: "#0000FF" } };
skuSheet.getRange("N5:N9").format = { font: { color: colors.black } };
addTable(skuSheet, rangeAddr(4, 1, 9, skuHeaders.length), "SKUMasterTable", "TableStyleMedium2");
skuSheet.freezePanes.freezeRows(4);

// Channel assumptions
setTitle(channelSheet, "Channel Assumptions", "Channel economics feed traffic allocation, discounts, fees, shipping, and cash timing.", 14);
const channelHeaders = ["Channel", "Customer Type", "Traffic Mix", "Discount Rate", "Processor Fee", "Marketplace Fee", "CPC $", "Conversion Mult.", "Outbound Shipping $", "Customer Shipping Recovery $", "Pick/Pack $", "Collection Terms Days", "Notes"];
channelSheet.getRange(rangeAddr(4, 1, 4, channelHeaders.length)).values = [channelHeaders];
styleHeader(channelSheet.getRange(rangeAddr(4, 1, 4, channelHeaders.length)));
channelSheet.getRange(rangeAddr(5, 1, 8, channelHeaders.length)).values = channels.map((c) => [
  c.channel, c.customerType, c.mix, c.discount, c.processor, c.marketplace, c.cpc, c.conversionMult, c.shipCost, c.shipCharged, c.pickPack, c.termsDays, "Editable channel economics"
]);
channelSheet.getRange("C5:F8").setNumberFormat(fmt.pct);
channelSheet.getRange("G5:K8").setNumberFormat("$0.00");
channelSheet.getRange("L5:L8").setNumberFormat(fmt.num);
channelSheet.getRange("C5:L8").format = { fill: colors.inputYellow, font: { color: "#0000FF" } };
addTable(channelSheet, rangeAddr(4, 1, 8, channelHeaders.length), "ChannelAssumptionTable", "TableStyleMedium2");

// Revenue detail
setTitle(revenue, "Weekly Revenue Model", "Sortable weekly detail by SKU, channel, customer type, geography, and month. Revenue and costs are in $000s except unit metrics and ASP.", 29);
const revHeaders = [
  "Week Start", "Month", "Month Label", "Period", "SKU", "Product", "Behavior", "Seasonality", "Lifecycle",
  "Channel", "Customer Type", "Geography", "Traffic", "Conversion Rate", "Gross Demand Units", "Inventory Fill Rate",
  "Units Sold", "ASP $", "Gross Revenue $000s", "Discount $000s", "Returns $000s", "Net Revenue $000s",
  "COGS $000s", "Payment Fees $000s", "Marketplace Fees $000s", "Outbound Shipping $000s", "Pick/Pack $000s",
  "Warranty $000s", "Contribution Margin $000s", "Contribution Margin %"
];
revenue.getRange(rangeAddr(4, 1, 4, revHeaders.length)).values = [revHeaders];
styleHeader(revenue.getRange(rangeAddr(4, 1, 4, revHeaders.length)));
const revDims = [];
for (const w of weeks) {
  for (const s of skus) {
    for (const c of channels) {
      revDims.push([w.date, w.month, w.monthLabel, w.period, s.sku, null, null, null, null, c.channel, null, "All Geographies"]);
    }
  }
}
revenue.getRange(rangeAddr(5, 1, 4 + revDims.length, 12)).values = revDims;
const revLast = 4 + revDims.length;
const invLast = 4 + inventoryRows;
const skuById = new Map(skus.map((s) => [s.sku, s]));
const channelByName = new Map(channels.map((c) => [c.channel, c]));
const geoByName = new Map(geos.map((g) => [g.geo, g]));
const seasonalityByType = new Map([
  ["None", [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]],
  ["Summer peak", [0.75, 0.78, 0.88, 1.05, 1.28, 1.45, 1.42, 1.18, 0.98, 0.88, 0.78, 0.72]],
  ["Winter peak", [1.22, 1.08, 0.92, 0.82, 0.78, 0.75, 0.78, 0.86, 0.98, 1.18, 1.42, 1.55]],
]);
const revLookupValues = [];
const revCustomerTypeValues = [];
const revCalcValues = [];
for (const row of revDims) {
  const [weekStart, , , period, skuId, , , , , channelName, , geoName] = row;
  const s = skuById.get(skuId);
  const c = channelByName.get(channelName);
  const g = geoByName.get(geoName) ?? { mix: 1 };
  const monthIndex = weekStart.getUTCMonth();
  const weekNo = Math.floor((weekStart - dateUtc(weekStart.getUTCFullYear(), 1, 1)) / (7 * 86400000)) + 1;
  const lifecycle = s.discontinue && weekStart > s.discontinue ? "Discontinued" : "Active";
  const periodTrafficRamp = period === "Actual" ? 0.82 + (weekNo / 52) * 0.18 : 1.22;
  const traffic = Math.round(46000 * periodTrafficRamp * c.mix * g.mix * s.trafficWeight * seasonalityByType.get(s.seasonality)[monthIndex] * (lifecycle === "Discontinued" ? 0 : 1));
  const conversion = 0.036 * c.conversionMult * s.convMult;
  const grossDemand = Math.round(traffic * conversion);
  const fillRate = 1;
  const unitsSold = Math.round(grossDemand * fillRate);
  const asp = s.price;
  const grossRevenue = unitsSold * asp / 1000;
  const discount = grossRevenue * c.discount;
  const returns = (grossRevenue - discount) * s.returnRate;
  const netRevenue = grossRevenue - discount - returns;
  const cogs = unitsSold * (s.unitCost + s.packaging + s.inbound + s.duty) / 1000;
  const processorFees = netRevenue * c.processor;
  const marketplaceFees = netRevenue * c.marketplace;
  const outboundShipping = unitsSold * (c.shipCost - c.shipCharged) / 1000;
  const pickPack = unitsSold * c.pickPack / 1000;
  const warranty = unitsSold * s.warrantyRate * s.warrantyCost / 1000;
  const contribution = netRevenue - cogs - processorFees - marketplaceFees - outboundShipping - pickPack - warranty;
  revLookupValues.push([s.name, s.behavior, s.seasonality, lifecycle]);
  revCustomerTypeValues.push([c.customerType]);
  revCalcValues.push([
    traffic, conversion, grossDemand, fillRate, unitsSold, asp, grossRevenue, discount, returns, netRevenue, cogs,
    processorFees, marketplaceFees, outboundShipping, pickPack, warranty, contribution, netRevenue === 0 ? 0 : contribution / netRevenue,
  ]);
}
revenue.getRange(`F5:I${revLast}`).values = revLookupValues;
revenue.getRange(`K5:K${revLast}`).values = revCustomerTypeValues;
revenue.getRange(`M5:AD${revLast}`).values = revCalcValues;
revenue.getRange(`A5:B${revLast}`).setNumberFormat(fmt.date);
revenue.getRange(`M5:M${revLast}`).setNumberFormat(fmt.num);
revenue.getRange(`N5:N${revLast}`).setNumberFormat(fmt.pct);
revenue.getRange(`O5:Q${revLast}`).setNumberFormat(fmt.num);
revenue.getRange(`R5:R${revLast}`).setNumberFormat("$0.00");
revenue.getRange(`S5:AC${revLast}`).setNumberFormat(fmt.money1);
revenue.getRange(`AD5:AD${revLast}`).setNumberFormat(fmt.pct);
addTable(revenue, rangeAddr(4, 1, revLast, revHeaders.length), "RevenueDetailTable", "TableStyleMedium9");
revenue.freezePanes.freezeRows(4);

// Geography revenue view
setTitle(geoView, "Geography Revenue View", "Filterable monthly allocation by SKU, channel, customer type, and geography. Geography mix is sourced from Assumptions.", 12);
const geoHeaders = ["Month", "Month Label", "Period", "SKU", "Product", "Channel", "Customer Type", "Geography", "Units Sold", "Net Revenue $000s", "Contribution Margin $000s", "Contribution Margin %"];
geoView.getRange(rangeAddr(4, 1, 4, geoHeaders.length)).values = [geoHeaders];
styleHeader(geoView.getRange(rangeAddr(4, 1, 4, geoHeaders.length)));
const geoRows = [];
const revenueByMonthSkuChannel = new Map();
revDims.forEach((row, i) => {
  const key = `${excelDateString(row[1])}|${row[4]}|${row[9]}`;
  const existing = revenueByMonthSkuChannel.get(key) ?? { units: 0, netRevenue: 0, contribution: 0 };
  existing.units += revCalcValues[i][4];
  existing.netRevenue += revCalcValues[i][9];
  existing.contribution += revCalcValues[i][16];
  revenueByMonthSkuChannel.set(key, existing);
});
for (const m of months) {
  for (const s of skus) {
    for (const c of channels) {
      const agg = revenueByMonthSkuChannel.get(`${excelDateString(m.date)}|${s.sku}|${c.channel}`) ?? { units: 0, netRevenue: 0, contribution: 0 };
      for (const g of geos) {
        const netRevenue = agg.netRevenue * g.mix;
        const contribution = agg.contribution * g.mix;
        geoRows.push([m.date, m.label, m.period, s.sku, s.name, c.channel, c.customerType, g.geo, agg.units * g.mix, netRevenue, contribution, netRevenue === 0 ? 0 : contribution / netRevenue]);
      }
    }
  }
}
geoView.getRange(rangeAddr(5, 1, 4 + geoRows.length, geoHeaders.length)).values = geoRows;
geoView.getRange(`A5:A${4 + geoRows.length}`).setNumberFormat(fmt.date);
geoView.getRange(`I5:I${4 + geoRows.length}`).setNumberFormat(fmt.num);
geoView.getRange(`J5:K${4 + geoRows.length}`).setNumberFormat(fmt.money1);
geoView.getRange(`L5:L${4 + geoRows.length}`).setNumberFormat(fmt.pct);
addTable(geoView, rangeAddr(4, 1, 4 + geoRows.length, geoHeaders.length), "GeoRevenueViewTable", "TableStyleMedium4");
geoView.freezePanes.freezeRows(4);

// Inventory model
setTitle(inventory, "Weekly Inventory Model", "SKU-level inventory availability constrains weekly revenue demand through the fill-rate formula.", 16);
const invHeaders = ["Week Start", "Month", "Period", "SKU", "Opening Inventory", "Production Received", "Gross Demand Units", "Sellable Units", "Fill Rate", "Units Sold", "Returns Restocked", "Ending Inventory", "Weeks of Supply", "Stockout Status", "Suggested Action", "Production Cost $000s"];
inventory.getRange(rangeAddr(4, 1, 4, invHeaders.length)).values = [invHeaders];
styleHeader(inventory.getRange(rangeAddr(4, 1, 4, invHeaders.length)));
const invDims = [];
for (const s of skus) {
  for (const w of weeks) {
    invDims.push([w.date, w.month, w.period, s.sku]);
  }
}
inventory.getRange(rangeAddr(5, 1, 4 + invDims.length, 4)).values = invDims;
const demandBySkuWeek = new Map();
revDims.forEach((row, i) => {
  const key = `${excelDateString(row[0])}|${row[4]}`;
  const existing = demandBySkuWeek.get(key) ?? { demand: 0, sold: 0 };
  existing.demand += revCalcValues[i][2];
  existing.sold += revCalcValues[i][4];
  demandBySkuWeek.set(key, existing);
});
const openingBySku = new Map(skus.map((s) => [s.sku, s.startInv]));
const invValueRows = [];
for (const row of invDims) {
  const [weekStart, , period, skuId] = row;
  const s = skuById.get(skuId);
  const key = `${excelDateString(weekStart)}|${skuId}`;
  const demand = demandBySkuWeek.get(key)?.demand ?? 0;
  const plannedSold = demandBySkuWeek.get(key)?.sold ?? 0;
  const opening = openingBySku.get(skuId) ?? s.startInv;
  const weekNo = Math.floor((weekStart - dateUtc(weekStart.getUTCFullYear(), 1, 1)) / (7 * 86400000)) + 1;
  let received = 0;
  if (period === "Actual") {
    received = weekNo % 8 === 1 ? s.moq : 0;
  } else if (opening < demand * s.safetyWeeks) {
    received = Math.ceil(Math.max(0, demand * s.safetyWeeks * 1.15 - opening) / s.moq) * s.moq;
  }
  const sellable = Math.min(demand, opening + received);
  const fillRate = demand === 0 ? 1 : sellable / demand;
  const unitsSold = sellable;
  const returnsRestocked = plannedSold * s.returnRate * 0.5;
  const ending = opening + received - unitsSold + returnsRestocked;
  const weeksOfSupply = demand === 0 ? 99 : ending / demand;
  const status = fillRate < 0.98 ? "Stockout Risk" : weeksOfSupply < s.safetyWeeks ? "Below Safety Stock" : "OK";
  const action = status === "Stockout Risk" ? "Reduce promo or expedite PO" : status === "Below Safety Stock" ? "Review reorder / ad pacing" : "Maintain plan";
  const productionCost = received * (s.unitCost + s.packaging + s.inbound + s.duty) / 1000;
  invValueRows.push([opening, received, demand, sellable, fillRate, unitsSold, returnsRestocked, ending, weeksOfSupply, status, action, productionCost]);
  openingBySku.set(skuId, ending);
}
inventory.getRange(`E5:P${invLast}`).values = invValueRows;
inventory.getRange(`A5:B${invLast}`).setNumberFormat(fmt.date);
inventory.getRange(`E5:H${invLast}`).setNumberFormat(fmt.num);
inventory.getRange(`I5:I${invLast}`).setNumberFormat(fmt.pct);
inventory.getRange(`J5:M${invLast}`).setNumberFormat(fmt.num1);
inventory.getRange(`P5:P${invLast}`).setNumberFormat(fmt.money1);
addTable(inventory, rangeAddr(4, 1, invLast, invHeaders.length), "InventoryTable", "TableStyleMedium4");
inventory.freezePanes.freezeRows(4);

// Shipping and warehouse monthly sortable table
setTitle(shipping, "Shipping and Warehousing", "Monthly cost rollup by major logistics cost type. Values are formula-driven from revenue and inventory detail.", 9);
const swHeaders = ["Month", "Month Label", "Period", "Cost Type", "Cost Basis", "Amount $000s", "Driver", "Owner", "Notes"];
shipping.getRange(rangeAddr(4, 1, 4, swHeaders.length)).values = [swHeaders];
styleHeader(shipping.getRange(rangeAddr(4, 1, 4, swHeaders.length)));
const swTypes = [
  ["Outbound Shipping", "Variable per fulfilled unit", "Revenue_Model outbound shipping", "Ops"],
  ["Pick/Pack", "Variable per fulfilled unit", "Revenue_Model pick/pack", "Ops"],
  ["Storage", "Average ending units", "Inventory_Model ending units x storage rate", "Ops"],
  ["Inbound Freight", "Production receipts", "Inventory_Model receipts x SKU inbound freight", "Ops"],
  ["Warehouse Rent", "Fixed monthly", "Headcount_Opex warehouse rent", "Ops"],
];
const swData = [];
for (const m of months) {
  for (const t of swTypes) swData.push([m.date, m.label, m.period, ...t, ""]);
}
shipping.getRange(rangeAddr(5, 1, 4 + swData.length, 8)).values = swData.map((r) => r.slice(0, 8));
const revenueByMonth = new Map();
revDims.forEach((row, i) => {
  const key = excelDateString(row[1]);
  const existing = revenueByMonth.get(key) ?? { cogs: 0, outbound: 0, pickPack: 0 };
  existing.cogs += revCalcValues[i][10];
  existing.outbound += revCalcValues[i][13];
  existing.pickPack += revCalcValues[i][14];
  revenueByMonth.set(key, existing);
});
const inventoryByMonth = new Map();
invDims.forEach((row, i) => {
  const key = excelDateString(row[1]);
  inventoryByMonth.set(key, (inventoryByMonth.get(key) ?? 0) + invValueRows[i][7]);
});
const swValueRows = [];
const swNoteRows = [];
for (let i = 0; i < swData.length; i++) {
  const [monthDate, , period, costType] = swData[i];
  const key = excelDateString(monthDate);
  const rev = revenueByMonth.get(key) ?? { cogs: 0, outbound: 0, pickPack: 0 };
  const inventoryUnits = inventoryByMonth.get(key) ?? 0;
  const monthRamp = period === "Actual" ? 0.92 + ((monthDate.getUTCMonth() + 1) / 12) * 0.08 : 1;
  const amount =
    costType === "Outbound Shipping" ? rev.outbound :
    costType === "Pick/Pack" ? rev.pickPack :
    costType === "Storage" ? inventoryUnits * 0.04 / 1000 :
    costType === "Inbound Freight" ? rev.cogs * 0.08 :
    costType === "Warehouse Rent" ? 28 * monthRamp :
    0;
  swValueRows.push([amount]);
  swNoteRows.push(["Formula rollup"]);
}
shipping.getRange(`F5:F${4 + swData.length}`).values = swValueRows;
shipping.getRange(`I5:I${4 + swData.length}`).values = swNoteRows;
shipping.getRange(`A5:A${4 + swData.length}`).setNumberFormat(fmt.date);
shipping.getRange(`F5:F${4 + swData.length}`).setNumberFormat(fmt.money1);
addTable(shipping, rangeAddr(4, 1, 4 + swData.length, swHeaders.length), "ShippingWarehouseTable", "TableStyleMedium2");

// Marketing
setTitle(marketing, "Weekly Marketing", "Traffic-driven spend model by channel. CPC and traffic are sourced from assumptions and revenue detail.", 11);
const mktHeaders = ["Week Start", "Month", "Month Label", "Period", "Channel", "Traffic", "CPC $", "Ad Spend $000s", "Units Sold", "CAC $", "Notes"];
marketing.getRange(rangeAddr(4, 1, 4, mktHeaders.length)).values = [mktHeaders];
styleHeader(marketing.getRange(rangeAddr(4, 1, 4, mktHeaders.length)));
const mktDims = [];
for (const w of weeks) {
  for (const c of channels) mktDims.push([w.date, w.month, w.monthLabel, w.period, c.channel]);
}
marketing.getRange(rangeAddr(5, 1, 4 + mktDims.length, 5)).values = mktDims;
const marketingByWeekChannel = new Map();
revDims.forEach((row, i) => {
  const key = `${excelDateString(row[0])}|${row[9]}`;
  const existing = marketingByWeekChannel.get(key) ?? { traffic: 0, units: 0 };
  existing.traffic += revCalcValues[i][0];
  existing.units += revCalcValues[i][4];
  marketingByWeekChannel.set(key, existing);
});
const mktValueRows = [];
for (const row of mktDims) {
  const [weekStart, , , period, channelName] = row;
  const c = channelByName.get(channelName);
  const key = `${excelDateString(weekStart)}|${channelName}`;
  const agg = marketingByWeekChannel.get(key) ?? { traffic: 0, units: 0 };
  const cpc = c.cpc;
  const adSpend = agg.traffic * cpc / 1000;
  const cac = agg.units === 0 ? 0 : adSpend * 1000 / agg.units;
  mktValueRows.push([agg.traffic, cpc, adSpend, agg.units, cac, period === "Actual" ? "Seeded historic marketing actual" : "Forecast driven by traffic and scenario"]);
}
marketing.getRange(`F5:K${4 + mktDims.length}`).values = mktValueRows;
marketing.getRange(`A5:B${4 + mktDims.length}`).setNumberFormat(fmt.date);
marketing.getRange(`F5:F${4 + mktDims.length}`).setNumberFormat(fmt.num);
marketing.getRange(`G5:G${4 + mktDims.length}`).setNumberFormat("$0.00");
marketing.getRange(`H5:H${4 + mktDims.length}`).setNumberFormat(fmt.money1);
marketing.getRange(`I5:I${4 + mktDims.length}`).setNumberFormat(fmt.num);
marketing.getRange(`J5:J${4 + mktDims.length}`).setNumberFormat("$0.00");
addTable(marketing, rangeAddr(4, 1, 4 + mktDims.length, mktHeaders.length), "MarketingTable", "TableStyleMedium4");

// Opex
setTitle(opex, "Headcount and Opex", "Monthly operating budget by department, account, and cash/non-cash type.", 9);
const opexHeaders = ["Month", "Month Label", "Period", "Account", "Department", "Expense Type", "Amount $000s", "Driver", "Cash / Non-Cash", "Base Monthly Cost $000s"];
opex.getRange(rangeAddr(4, 1, 4, opexHeaders.length)).values = [opexHeaders];
styleHeader(opex.getRange(rangeAddr(4, 1, 4, opexHeaders.length)));
const opexDims = [];
for (const m of months) {
  for (const a of opexAccounts) opexDims.push([m.date, m.label, m.period, a[1], a[0], a[2], null, a[3], a[4], a[5]]);
}
opex.getRange(rangeAddr(5, 1, 4 + opexDims.length, 6)).values = opexDims.map((r) => r.slice(0, 6));
opex.getRange(rangeAddr(5, 8, 4 + opexDims.length, 10)).values = opexDims.map((r) => [r[7], r[8], r[9]]);
const opexValueRows = [];
for (const row of opexDims) {
  const [monthDate, , period, , , expenseType, , , , baseCost] = row;
  const actualRamp = period === "Actual" ? 0.92 + ((monthDate.getUTCMonth() + 1) / 12) * 0.08 : 1;
  const payrollLoad = expenseType === "Payroll" ? 1.24 : 1;
  opexValueRows.push([baseCost * actualRamp * payrollLoad]);
}
opex.getRange(`G5:G${4 + opexRows}`).values = opexValueRows;
opex.getRange(`A5:A${4 + opexRows}`).setNumberFormat(fmt.date);
opex.getRange(`G5:G${4 + opexRows}`).setNumberFormat(fmt.money1);
opex.getRange(`J5:J${4 + opexRows}`).setNumberFormat(fmt.money1);
opex.getRange(`J5:J${4 + opexRows}`).format = { fill: colors.inputYellow, font: { color: "#0000FF" } };
addTable(opex, rangeAddr(4, 1, 4 + opexRows, opexHeaders.length), "OpexTable", "TableStyleMedium2");

// Financial model
setTitle(financial, "Financial Model", "Monthly cash-basis operating model in $000s. Columns roll up weekly detail and feed board reporting.", 27);
const finMonths = months.map((m) => m.date);
financial.getRange(rangeAddr(4, 1, 4, 1 + finMonths.length)).values = [["Metric", ...finMonths]];
styleHeader(financial.getRange(rangeAddr(4, 1, 4, 1 + finMonths.length)));
financial.getRange(rangeAddr(5, 2, 5, 1 + finMonths.length)).values = [months.map((m) => m.period)];
financial.getRange(rangeAddr(6, 2, 6, 1 + finMonths.length)).values = [months.map((m) => m.label)];
financial.getRange("A5:A6").values = [["Period"], ["Month Label"]];
const finRows = [
  ["Units Sold", fmt.num],
  ["Gross Revenue", fmt.money1],
  ["Discounts", fmt.money1],
  ["Returns", fmt.money1],
  ["Net Revenue", fmt.money1],
  ["COGS", fmt.money1],
  ["Gross Profit", fmt.money1],
  ["Gross Margin %", fmt.pct],
  ["Payment + Marketplace Fees", fmt.money1],
  ["Outbound Shipping", fmt.money1],
  ["Pick/Pack", fmt.money1],
  ["Warranty", fmt.money1],
  ["Contribution Margin", fmt.money1],
  ["Contribution Margin %", fmt.pct],
  ["Marketing", fmt.money1],
  ["Payroll", fmt.money1],
  ["Other Opex", fmt.money1],
  ["EBITDA", fmt.money1],
  ["EBITDA Margin %", fmt.pct],
  ["Inventory Purchases Cash", fmt.money1],
  ["Capex / Tooling", fmt.money1],
  ["Debt Interest", fmt.money1],
  ["Cash Taxes", fmt.money1],
  ["Net Cash Flow", fmt.money1],
  ["Beginning Cash", fmt.money1],
  ["Ending Cash", fmt.money1],
  ["Ending Inventory Units", fmt.num],
  ["Stockout Risk SKU-Weeks", fmt.num],
];
financial.getRange(rangeAddr(7, 1, 6 + finRows.length, 1)).values = finRows.map((r) => [r[0]]);
styleSection(financial.getRange("A7:Y7"), colors.blue);
const financialFormulaColumns = Array.from({ length: finRows.length }, () => []);
for (let c = 2; c <= 25; c++) {
  const monthCell = `${col(c)}$4`;
  const prevEndCash = c === 2 ? `${quoteSheet("Assumptions")}!$B$18` : `${col(c - 1)}32`;
  const formulas = [
    `=SUMIFS(${quoteSheet("Revenue_Model")}!$Q$5:$Q$${revLast},${quoteSheet("Revenue_Model")}!$B$5:$B$${revLast},${monthCell})`,
    `=SUMIFS(${quoteSheet("Revenue_Model")}!$S$5:$S$${revLast},${quoteSheet("Revenue_Model")}!$B$5:$B$${revLast},${monthCell})`,
    `=SUMIFS(${quoteSheet("Revenue_Model")}!$T$5:$T$${revLast},${quoteSheet("Revenue_Model")}!$B$5:$B$${revLast},${monthCell})`,
    `=SUMIFS(${quoteSheet("Revenue_Model")}!$U$5:$U$${revLast},${quoteSheet("Revenue_Model")}!$B$5:$B$${revLast},${monthCell})`,
    `=SUMIFS(${quoteSheet("Revenue_Model")}!$V$5:$V$${revLast},${quoteSheet("Revenue_Model")}!$B$5:$B$${revLast},${monthCell})`,
    `=SUMIFS(${quoteSheet("Revenue_Model")}!$W$5:$W$${revLast},${quoteSheet("Revenue_Model")}!$B$5:$B$${revLast},${monthCell})`,
    `=B11-B12`,
    `=IF(B11=0,0,B13/B11)`,
    `=SUMIFS(${quoteSheet("Revenue_Model")}!$X$5:$X$${revLast},${quoteSheet("Revenue_Model")}!$B$5:$B$${revLast},${monthCell})+SUMIFS(${quoteSheet("Revenue_Model")}!$Y$5:$Y$${revLast},${quoteSheet("Revenue_Model")}!$B$5:$B$${revLast},${monthCell})`,
    `=SUMIFS(${quoteSheet("Revenue_Model")}!$Z$5:$Z$${revLast},${quoteSheet("Revenue_Model")}!$B$5:$B$${revLast},${monthCell})`,
    `=SUMIFS(${quoteSheet("Revenue_Model")}!$AA$5:$AA$${revLast},${quoteSheet("Revenue_Model")}!$B$5:$B$${revLast},${monthCell})`,
    `=SUMIFS(${quoteSheet("Revenue_Model")}!$AB$5:$AB$${revLast},${quoteSheet("Revenue_Model")}!$B$5:$B$${revLast},${monthCell})`,
    `=B11-B12-B15-B16-B17-B18`,
    `=IF(B11=0,0,B19/B11)`,
    `=SUMIFS(${quoteSheet("Marketing")}!$H$5:$H$${4 + marketingRows},${quoteSheet("Marketing")}!$B$5:$B$${4 + marketingRows},${monthCell})`,
    `=SUMIFS(${quoteSheet("Headcount_Opex")}!$G$5:$G$${4 + opexRows},${quoteSheet("Headcount_Opex")}!$A$5:$A$${4 + opexRows},${monthCell},${quoteSheet("Headcount_Opex")}!$F$5:$F$${4 + opexRows},"Payroll")`,
    `=SUMIFS(${quoteSheet("Headcount_Opex")}!$G$5:$G$${4 + opexRows},${quoteSheet("Headcount_Opex")}!$A$5:$A$${4 + opexRows},${monthCell})-B22`,
    `=B19-B21-B22-B23`,
    `=IF(B11=0,0,B24/B11)`,
    `=SUMIFS(${quoteSheet("Inventory_Model")}!$P$5:$P$${invLast},${quoteSheet("Inventory_Model")}!$B$5:$B$${invLast},${monthCell})`,
    `=${quoteSheet("Assumptions")}!$B$21`,
    `=${quoteSheet("Assumptions")}!$B$19*${quoteSheet("Assumptions")}!$B$20/12`,
    `=MAX(0,B24)*${quoteSheet("Assumptions")}!$B$18`,
    `=B24-B26-B27-B28-B29`,
    `=${prevEndCash}`,
    `=B31+B30`,
    `=SUMIFS(${quoteSheet("Inventory_Model")}!$L$5:$L$${invLast},${quoteSheet("Inventory_Model")}!$B$5:$B$${invLast},${monthCell})`,
    `=COUNTIFS(${quoteSheet("Inventory_Model")}!$B$5:$B$${invLast},${monthCell},${quoteSheet("Inventory_Model")}!$N$5:$N$${invLast},"Stockout Risk")`,
  ];
  // Convert relative B-row formulas to the active output column.
  const adjusted = formulas.map((f) => f.replaceAll("B11", `${col(c)}11`).replaceAll("B12", `${col(c)}12`).replaceAll("B13", `${col(c)}13`).replaceAll("B15", `${col(c)}15`).replaceAll("B16", `${col(c)}16`).replaceAll("B17", `${col(c)}17`).replaceAll("B18", `${col(c)}18`).replaceAll("B19", `${col(c)}19`).replaceAll("B21", `${col(c)}21`).replaceAll("B22", `${col(c)}22`).replaceAll("B23", `${col(c)}23`).replaceAll("B24", `${col(c)}24`).replaceAll("B26", `${col(c)}26`).replaceAll("B27", `${col(c)}27`).replaceAll("B28", `${col(c)}28`).replaceAll("B29", `${col(c)}29`).replaceAll("B30", `${col(c)}30`).replaceAll("B31", `${col(c)}31`));
  adjusted.forEach((f, i) => financialFormulaColumns[i].push(f));
}
financial.getRange("B7:Y34").formulas = financialFormulaColumns;
financial.getRange("B4:Y4").setNumberFormat(fmt.date);
financial.getRange("B7:Y34").format = { font: { color: colors.black } };
for (let i = 0; i < finRows.length; i++) {
  financial.getRange(rangeAddr(7 + i, 2, 7 + i, 25)).setNumberFormat(finRows[i][1]);
}
financial.freezePanes.freezeRows(6);
financial.freezePanes.freezeColumns(1);

// Monthly Board table
setTitle(board, "Monthly Board Reporting", "Board-ready monthly table fed by the weekly operating model. Use filters for period and month.", 18);
const boardHeaders = [
  "Month", "Month Label", "Period", "Units Sold", "Net Revenue $000s", "Gross Margin %",
  "Contribution Margin $000s", "Contribution Margin %", "Marketing $000s", "Payroll $000s",
  "Other Opex $000s", "EBITDA $000s", "EBITDA Margin %", "Net Cash Flow $000s", "Ending Cash $000s",
  "Ending Inventory Units", "Stockout Risk SKU-Weeks", "Model Status"
];
board.getRange(rangeAddr(4, 1, 4, boardHeaders.length)).values = [boardHeaders];
styleHeader(board.getRange(rangeAddr(4, 1, 4, boardHeaders.length)));
board.getRange(rangeAddr(5, 1, 28, 3)).values = months.map((m) => [m.date, m.label, m.period]);
for (let r = 5; r <= 28; r++) {
  const fcol = col(r - 3);
  board.getRange(rangeAddr(r, 4, r, 18)).formulas = [[
    `=${quoteSheet("Financial_Model")}!${fcol}7`,
    `=${quoteSheet("Financial_Model")}!${fcol}11`,
    `=${quoteSheet("Financial_Model")}!${fcol}14`,
    `=${quoteSheet("Financial_Model")}!${fcol}19`,
    `=${quoteSheet("Financial_Model")}!${fcol}20`,
    `=${quoteSheet("Financial_Model")}!${fcol}21`,
    `=${quoteSheet("Financial_Model")}!${fcol}22`,
    `=${quoteSheet("Financial_Model")}!${fcol}23`,
    `=${quoteSheet("Financial_Model")}!${fcol}24`,
    `=${quoteSheet("Financial_Model")}!${fcol}25`,
    `=${quoteSheet("Financial_Model")}!${fcol}30`,
    `=${quoteSheet("Financial_Model")}!${fcol}32`,
    `=${quoteSheet("Financial_Model")}!${fcol}33`,
    `=${quoteSheet("Financial_Model")}!${fcol}34`,
    `=IF(Q${r}>0,"Inventory Watch",IF(O${r}<500,"Cash Watch","OK"))`,
  ]];
}
board.getRange("A5:A28").setNumberFormat(fmt.date);
board.getRange("D5:D28").setNumberFormat(fmt.num);
board.getRange("E5:E28").setNumberFormat(fmt.money1);
board.getRange("F5:F28").setNumberFormat(fmt.pct);
board.getRange("G5:G28").setNumberFormat(fmt.money1);
board.getRange("H5:H28").setNumberFormat(fmt.pct);
board.getRange("I5:O28").setNumberFormat(fmt.money1);
board.getRange("P5:Q28").setNumberFormat(fmt.num);
addTable(board, rangeAddr(4, 1, 28, boardHeaders.length), "MonthlyBoardTable", "TableStyleMedium9");

// Sensitivity
setTitle(sensitivity, "Sensitivity Analysis", "Forecast-year EBITDA sensitivity to pricing and fully loaded unit cost multipliers.", 10);
sensitivity.getRange("A4").values = [["FY Forecast EBITDA $000s"]];
sensitivity.getRange("B4").formulas = [[`=SUMIFS(${quoteSheet("Monthly_Board")}!$L$5:$L$28,${quoteSheet("Monthly_Board")}!$C$5:$C$28,"Forecast")`]];
sensitivity.getRange("A6:F6").values = [["Price \\ COGS", "90%", "95%", "100%", "105%", "110%"]];
sensitivity.getRange("A7:A11").values = [["90%"], ["95%"], ["100%"], ["105%"], ["110%"]];
styleHeader(sensitivity.getRange("A6:F6"));
styleHeader(sensitivity.getRange("A7:A11"));
const priceMults = [0.9, 0.95, 1, 1.05, 1.1];
const cogsMults = [0.9, 0.95, 1, 1.05, 1.1];
for (let r = 0; r < priceMults.length; r++) {
  for (let c = 0; c < cogsMults.length; c++) {
    const rr = 7 + r;
    const cc = 2 + c;
    sensitivity.getRange(addr(rr, cc)).formulas = [[`=SUMIFS(${quoteSheet("Monthly_Board")}!$L$5:$L$28,${quoteSheet("Monthly_Board")}!$C$5:$C$28,"Forecast")+(SUMIFS(${quoteSheet("Revenue_Model")}!$V$5:$V$${revLast},${quoteSheet("Revenue_Model")}!$D$5:$D$${revLast},"Forecast")*${priceMults[r]}-SUMIFS(${quoteSheet("Revenue_Model")}!$V$5:$V$${revLast},${quoteSheet("Revenue_Model")}!$D$5:$D$${revLast},"Forecast"))-(SUMIFS(${quoteSheet("Revenue_Model")}!$W$5:$W$${revLast},${quoteSheet("Revenue_Model")}!$D$5:$D$${revLast},"Forecast")*${cogsMults[c]}-SUMIFS(${quoteSheet("Revenue_Model")}!$W$5:$W$${revLast},${quoteSheet("Revenue_Model")}!$D$5:$D$${revLast},"Forecast"))`]];
  }
}
sensitivity.getRange("B4:F11").setNumberFormat(fmt.money1);

// Checks
setTitle(checks, "Model Checks", "Visible controls for scenario validity, mix totals, rollup tie-outs, and risk flags.", 9);
const checkHeaders = ["Check", "Actual", "Expected", "Difference", "Tolerance", "Status", "Where to Fix", "Notes"];
checks.getRange("A4:H4").values = [checkHeaders];
styleHeader(checks.getRange("A4:H4"));
const checkRows = [
  ["Scenario selector valid", `=COUNTIF(${quoteSheet("Scenarios")}!$A$5:$A$7,${quoteSheet("Assumptions")}!$B$10)`, 1, null, 0, null, "Assumptions!B10", "Selector must match a scenario row"],
  ["Channel mix totals to 100%", `=SUM(${quoteSheet("Channel_Assumptions")}!$C$5:$C$8)`, 1, null, 0.0001, null, "Channel_Assumptions!C5:C8", "Traffic mix should sum to 100%"],
  ["Geo mix totals to 100%", `=SUM(${quoteSheet("Assumptions")}!$B$32:$B$35)`, 1, null, 0.0001, null, "Assumptions!B32:B35", "Geographic mix should sum to 100%"],
  ["SKU traffic weights total to 100%", `=SUM(${quoteSheet("SKU_Master")}!$V$5:$V$9)`, 1, null, 0.0001, null, "SKU_Master!V5:V9", "SKU demand allocation should sum to 100%"],
  ["Monthly board revenue ties to detail", `=SUM(${quoteSheet("Monthly_Board")}!$E$5:$E$28)`, `=SUM(${quoteSheet("Revenue_Model")}!$V$5:$V$${revLast})`, null, 0.1, null, "Monthly_Board / Revenue_Model", "Net revenue rollup"],
  ["Monthly board EBITDA ties to financial model", `=SUM(${quoteSheet("Monthly_Board")}!$L$5:$L$28)`, `=SUM(${quoteSheet("Financial_Model")}!$B$24:$Y$24)`, null, 0.1, null, "Financial_Model", "EBITDA rollup"],
  ["No negative ending cash", `=MIN(${quoteSheet("Financial_Model")}!$B$32:$Y$32)`, 0, null, 0, null, "Financial_Model row 32", "Warning if ending cash falls below zero"],
  ["Inventory stockout risk weeks", `=SUM(${quoteSheet("Monthly_Board")}!$Q$5:$Q$28)`, 0, null, 0, null, "Inventory_Model", "Warning if demand exceeds sellable inventory"],
];
checks.getRange("A5:H12").values = checkRows.map((r) => [r[0], null, r[2], null, r[4], null, r[6], r[7]]);
for (let r = 5; r <= 12; r++) {
  checks.getRange(`B${r}`).formulas = [[checkRows[r - 5][1]]];
  checks.getRange(`D${r}`).formulas = [[`=B${r}-C${r}`]];
  checks.getRange(`F${r}`).formulas = [[r <= 10 ? `=IF(ABS(D${r})<=E${r},"OK","FAIL")` : `=IF(B${r}>=C${r},"WATCH","OK")`]];
}
checks.getRange("B5:E12").setNumberFormat(fmt.num1);
checks.getRange("A14:B14").values = [["MODEL STATUS", null]];
checks.getRange("B14").formulas = [[`=IF(COUNTIF(F5:F10,"FAIL")>0,"FAIL",IF(COUNTIF(F11:F12,"WATCH")>0,"WATCH","PASS"))`]];
styleSection(checks.getRange("A14:B14"), colors.teal);
addTable(checks, "A4:H12", "ChecksTable", "TableStyleMedium3");

// Sources
setTitle(sources, "Sources and Assumption Log", "The current model uses illustrative placeholder assumptions because no live company exports were provided yet.", 10);
const sourceHeaders = ["Item", "Value", "Units", "Period / As-of", "Source Type", "Source Name", "Ref", "Owner", "Notes", "Accessed / Refreshed"];
sources.getRange(rangeAddr(4, 1, 4, sourceHeaders.length)).values = [sourceHeaders];
styleHeader(sources.getRange(rangeAddr(4, 1, 4, sourceHeaders.length)));
sources.getRange("A5:J17").values = [
  ["Historic actuals", "Seeded illustrative data", "$000s / units", "2025", "Assumption", "Codex generated placeholder", "Revenue_Model, Inventory_Model", "Management", "Replace with Shopify/Amazon/3PL/accounting exports", excelDateString(new Date())],
  ["Forecast assumptions", "Base / Downside / Upside", "Multipliers", "2026", "Assumption", "Codex generated placeholder", "Scenarios", "Finance", "Editable scenario drivers", excelDateString(new Date())],
  ["SKU prices", "$15-$65 range", "$", "Current", "User-directed assumption", "User prompt", "SKU_Master", "Product", "User requested random reasonable prices between $15 and $65", excelDateString(new Date())],
  ["Manufacturing costs", "Reasonable physical goods estimates", "$/unit", "Current", "Assumption", "Codex generated placeholder", "SKU_Master", "Ops", "Replace with vendor quotes or ERP data", excelDateString(new Date())],
  ["Channel fees", "Blended DTC/Amazon/Wholesale/TikTok defaults", "% / $", "Current", "Assumption", "Codex generated placeholder", "Channel_Assumptions", "Growth", "Replace with actual channel contracts and fee schedules", excelDateString(new Date())],
  ["Warehousing", "3PL-style pick/pack/storage", "$/unit", "Current", "Assumption", "Codex generated placeholder", "Shipping_Warehouse", "Ops", "Replace with 3PL invoices", excelDateString(new Date())],
  ["Marketing CPC", "Channel CPC assumptions", "$", "Current", "Assumption", "Codex generated placeholder", "Marketing", "Growth", "Replace with ad platform exports", excelDateString(new Date())],
  ["Opex", "Monthly department budget", "$000s", "2025-2026", "Assumption", "Codex generated placeholder", "Headcount_Opex", "Finance", "Replace with payroll, AP, and GL data", excelDateString(new Date())],
  ["Cash basis", "Cash-oriented model", "$000s", "2025-2026", "User-directed", "User prompt", "Financial_Model", "Finance", "Inventory purchases and cash expenses are visible in cash flow rows", excelDateString(new Date())],
  ["Board reporting", "Monthly rollups", "$000s / KPI", "2025-2026", "User-directed", "User prompt", "Monthly_Board", "Finance", "Weekly model feeds monthly board table", excelDateString(new Date())],
  ["Seasonality", "2 seasonal SKUs", "Demand multiplier", "2025-2026", "Assumption", "Codex generated placeholder", "Assumptions", "Product", "Summer and winter peaks selected for SunNest and EmberTrail", excelDateString(new Date())],
  ["Discontinuation", "2 SKUs discontinued in forecast", "Date", "2026", "Assumption", "Codex generated placeholder", "SKU_Master", "Product", "SunNest and EmberTrail discontinue at different times", excelDateString(new Date())],
  ["Inventory policy", "MOQ and safety stock", "Units / weeks", "2025-2026", "Assumption", "Codex generated placeholder", "Inventory_Model", "Ops", "Receipts are formula-driven and designed for planning, not PO execution", excelDateString(new Date())],
];
addTable(sources, "A4:J17", "SourceLogTable", "TableStyleMedium2");

// Cover after dependent sheets exist
setTitle(cover, "DreamBig Ecommerce Financial Model", "Weekly operating model with monthly board reporting; 2025 seeded actuals and 2026 formula-driven forecast.", 10);
cover.getRange("A4:D4").values = [["Model Metadata", "Value", "Notes", ""]];
styleHeader(cover.getRange("A4:D4"));
cover.getRange("A5:C12").values = [
  ["Company", "DreamBig", "Existing ecommerce company"],
  ["Model Purpose", "Board reporting and operating planning", "Weekly detail rolls into monthly board view"],
  ["Currency", "$000s", "Unit economics stay in dollars where labeled"],
  ["Basis", "Cash basis", "Cash flow rows include inventory purchases, capex, interest, and taxes"],
  ["Historic Data", "2025 seeded actuals", "Replace with real exports when available"],
  ["Forecast Data", "2026 Base case", "Controlled by scenario selector"],
  ["Scenario", null, "Linked to Assumptions!B10"],
  ["Model Status", null, "Linked to Checks!B14"],
];
cover.getRange("B11").formulas = [[`=${quoteSheet("Assumptions")}!$B$10`]];
cover.getRange("B12").formulas = [[`=${quoteSheet("Checks")}!$B$14`]];
cover.getRange("A15:F15").values = [["Board KPI", "2025 Actual", "2026 Forecast", "Change", "Notes", ""]];
styleHeader(cover.getRange("A15:F15"));
cover.getRange("A16:E23").values = [
  ["Net Revenue", null, null, null, "Monthly_Board rollup"],
  ["Gross Margin %", null, null, null, "Weighted annual margin"],
  ["Contribution Margin", null, null, null, "After COGS, fees, shipping, pick/pack, warranty"],
  ["Marketing", null, null, null, "Traffic-driven spend"],
  ["EBITDA", null, null, null, "Contribution less marketing, payroll, other opex"],
  ["Ending Cash", null, null, null, "December ending cash"],
  ["Ending Inventory Units", null, null, null, "December ending inventory"],
  ["Stockout Risk SKU-Weeks", null, null, null, "Inventory watch metric"],
];
cover.getRange("B16:C23").formulas = [
  [`=SUMIFS(${quoteSheet("Monthly_Board")}!$E$5:$E$28,${quoteSheet("Monthly_Board")}!$C$5:$C$28,"Actual")`, `=SUMIFS(${quoteSheet("Monthly_Board")}!$E$5:$E$28,${quoteSheet("Monthly_Board")}!$C$5:$C$28,"Forecast")`],
  [`=SUMIFS(${quoteSheet("Financial_Model")}!$B$13:$M$13,${quoteSheet("Financial_Model")}!$B$5:$M$5,"Actual")/SUMIFS(${quoteSheet("Financial_Model")}!$B$11:$M$11,${quoteSheet("Financial_Model")}!$B$5:$M$5,"Actual")`, `=SUMIFS(${quoteSheet("Financial_Model")}!$N$13:$Y$13,${quoteSheet("Financial_Model")}!$N$5:$Y$5,"Forecast")/SUMIFS(${quoteSheet("Financial_Model")}!$N$11:$Y$11,${quoteSheet("Financial_Model")}!$N$5:$Y$5,"Forecast")`],
  [`=SUMIFS(${quoteSheet("Monthly_Board")}!$G$5:$G$28,${quoteSheet("Monthly_Board")}!$C$5:$C$28,"Actual")`, `=SUMIFS(${quoteSheet("Monthly_Board")}!$G$5:$G$28,${quoteSheet("Monthly_Board")}!$C$5:$C$28,"Forecast")`],
  [`=SUMIFS(${quoteSheet("Monthly_Board")}!$I$5:$I$28,${quoteSheet("Monthly_Board")}!$C$5:$C$28,"Actual")`, `=SUMIFS(${quoteSheet("Monthly_Board")}!$I$5:$I$28,${quoteSheet("Monthly_Board")}!$C$5:$C$28,"Forecast")`],
  [`=SUMIFS(${quoteSheet("Monthly_Board")}!$L$5:$L$28,${quoteSheet("Monthly_Board")}!$C$5:$C$28,"Actual")`, `=SUMIFS(${quoteSheet("Monthly_Board")}!$L$5:$L$28,${quoteSheet("Monthly_Board")}!$C$5:$C$28,"Forecast")`],
  [`=${quoteSheet("Financial_Model")}!M32`, `=${quoteSheet("Financial_Model")}!Y32`],
  [`=${quoteSheet("Financial_Model")}!M33`, `=${quoteSheet("Financial_Model")}!Y33`],
  [`=SUMIFS(${quoteSheet("Monthly_Board")}!$Q$5:$Q$28,${quoteSheet("Monthly_Board")}!$C$5:$C$28,"Actual")`, `=SUMIFS(${quoteSheet("Monthly_Board")}!$Q$5:$Q$28,${quoteSheet("Monthly_Board")}!$C$5:$C$28,"Forecast")`],
];
for (let r = 16; r <= 23; r++) cover.getRange(`D${r}`).formulas = [[`=C${r}-B${r}`]];
cover.getRange("B16:D23").setNumberFormat(fmt.money1);
cover.getRange("B17:D17").setNumberFormat(fmt.pct);
cover.getRange("B22:D23").setNumberFormat(fmt.num);
cover.getRange("A26:F26").values = [["Navigation", "Purpose", "Primary Sort / Filter Cuts", "Next Step Chart Use", "", ""]];
styleHeader(cover.getRange("A26:F26"));
cover.getRange("A27:D34").values = [
  ["SKU_Master", "Product economics and lifecycle", "SKU, behavior, seasonality, status", "SKU margin, discontinuation analysis"],
  ["Revenue_Model", "Weekly revenue and contribution detail", "Week, month, SKU, channel, customer type", "Revenue, units, margin trends"],
  ["Geo_Revenue_View", "Monthly geography allocation", "Month, SKU, channel, customer type, geography", "Regional revenue and margin cuts"],
  ["Inventory_Model", "SKU inventory availability and stockout risk", "SKU, week, stockout status", "Inventory runway, stockout flags"],
  ["Marketing", "Traffic and CAC by channel", "Week, month, channel", "CAC and spend efficiency"],
  ["Shipping_Warehouse", "Logistics cost rollup", "Month, cost type", "Fulfillment cost trend"],
  ["Headcount_Opex", "Department operating budget", "Department, account, fixed/variable", "Opex bridge"],
  ["Monthly_Board", "Board reporting feed", "Period, month, model status", "Board charts"],
];

console.log("SHEETS_POPULATED");

// Widen important text columns and cap oversized views. Fixed widths avoid slow global autofit on large model tables.
cover.getRange("A:A").format.columnWidth = 24;
cover.getRange("B:D").format.columnWidth = 20;
assumptions.getRange("A:D").format.columnWidth = 22;
skuSheet.getRange("A:W").format.columnWidth = 16;
channelSheet.getRange("A:M").format.columnWidth = 18;
revenue.getRange("A:AD").format.columnWidth = 15;
geoView.getRange("A:L").format.columnWidth = 17;
inventory.getRange("A:P").format.columnWidth = 17;
shipping.getRange("A:I").format.columnWidth = 18;
marketing.getRange("A:K").format.columnWidth = 16;
opex.getRange("A:J").format.columnWidth = 18;
financial.getRange("A:A").format.columnWidth = 26;
financial.getRange("B:Y").format.columnWidth = 13;
board.getRange("A:R").format.columnWidth = 17;
sources.getRange("A:J").format.columnWidth = 20;

// Comments on key assumption cells.
workbook.comments.setSelf({ displayName: "User" });
workbook.comments.addThread({ cell: assumptions.getRange("B10") }, "Assumption: Scenario selector controls forecast traffic, conversion, pricing, cost, shipping, and opex multipliers.");
workbook.comments.addThread({ cell: assumptions.getRange("B7") }, "Assumption: Forecast begins January 2026 after 12 months of seeded 2025 weekly actuals.");
workbook.comments.addThread({ cell: skuSheet.getRange("I5") }, "Assumption: SKU prices were selected within the user-requested $15-$65 range and should be replaced with current pricing.");
workbook.comments.addThread({ cell: skuSheet.getRange("J5") }, "Assumption: Manufacturing and landed costs are reasonable placeholders for physical goods; replace with vendor quotes or ERP actuals.");
workbook.comments.addThread({ cell: channelSheet.getRange("C5") }, "Assumption: Channel mix is illustrative and should be replaced with actual or forecasted channel traffic allocation.");

console.log("FORMATTING_AND_COMMENTS_DONE");

// Compact visual and formula verification artifacts.
const inspectBoard = await workbook.inspect({
  kind: "table",
  sheetId: "Monthly_Board",
  range: "A4:R12",
  include: "values,formulas",
  tableMaxRows: 10,
  tableMaxCols: 18,
});
console.log("MONTHLY_BOARD_INSPECT");
console.log(inspectBoard.ndjson);

const errors = await workbook.inspect({
  kind: "match",
  searchTerm: "#REF!|#DIV/0!|#VALUE!|#NAME\\?|#N/A",
  options: { useRegex: true, maxResults: 300 },
  summary: "final formula error scan",
});
console.log("FORMULA_ERROR_SCAN");
console.log(errors.ndjson);

const previewSheets = [
  ["Cover", "A1:F34"],
  ["Assumptions", "A1:N35"],
  ["SKU_Master", "A1:W9"],
  ["Channel_Assumptions", "A1:M8"],
  ["Revenue_Model", "A1:AD24"],
  ["Geo_Revenue_View", "A1:L24"],
  ["Inventory_Model", "A1:O24"],
  ["Shipping_Warehouse", "A1:I24"],
  ["Marketing", "A1:K24"],
  ["Headcount_Opex", "A1:J24"],
  ["Financial_Model", "A1:Y34"],
  ["Monthly_Board", "A1:R28"],
  ["Scenarios", "A1:I7"],
  ["Sensitivity", "A1:F11"],
  ["Checks", "A1:H14"],
  ["Sources", "A1:J17"],
];
await fs.mkdir(`${outputDir}/previews`, { recursive: true });
for (const [sheetName, range] of previewSheets) {
  const preview = await workbook.render({ sheetName, range, scale: 1, format: "png" });
  await fs.writeFile(`${outputDir}/previews/${sheetName}.png`, new Uint8Array(await preview.arrayBuffer()));
}

const output = await SpreadsheetFile.exportXlsx(workbook);
await output.save(`${outputDir}/DreamBig_ecommerce_financial_model.xlsx`);
console.log(`${outputDir}/DreamBig_ecommerce_financial_model.xlsx`);
