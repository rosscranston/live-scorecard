import fs from "node:fs/promises";
import path from "node:path";
import { FileBlob, Presentation, PresentationFile, SpreadsheetFile } from "@oai/artifact-tool";

const TMP_DIR = "/Users/rossegates/Documents/desktop automation/outputs/dreambig_board_deck/tmp";
const FINAL_PPTX = "/Users/rossegates/Documents/desktop automation/outputs/dreambig_board_deck/DreamBig_monthly_board_reporting_deck.pptx";
const WORKBOOK_PATH = "/Users/rossegates/Documents/desktop automation/outputs/dreambig_financial_model/DreamBig_ecommerce_financial_model.xlsx";

await fs.mkdir(TMP_DIR, { recursive: true });
await fs.mkdir(path.dirname(FINAL_PPTX), { recursive: true });

const workbook = await SpreadsheetFile.importXlsx(await FileBlob.load(WORKBOOK_PATH));
const board = workbook.worksheets.getItem("Monthly_Board");
const raw = board.getRange("A4:R28").values;
const headers = raw[0].map(String);
const rows = raw.slice(1).map((r) => Object.fromEntries(headers.map((h, i) => [h, r[i]])));

function dateLabel(v) {
  const d = excelDate(v);
  return d.toLocaleString("en-US", { month: "short", year: "numeric", timeZone: "UTC" });
}

function excelDate(v) {
  if (v instanceof Date) return v;
  if (typeof v === "number") {
    // Excel serial date system: day 1 is 1899-12-31, with Excel's 1900 leap-year quirk.
    return new Date(Date.UTC(1899, 11, 30 + v));
  }
  return new Date(v);
}

const forecast = rows.filter((r) => r.Period === "Forecast").map((r) => ({
  month: r.Month,
  label: dateLabel(r.Month),
  short: dateLabel(r.Month).split(" ")[0],
  units: Number(r["Units Sold"] ?? 0),
  revenue: Number(r["Net Revenue $000s"] ?? 0),
  grossMargin: Number(r["Gross Margin %"] ?? 0),
  contribution: Number(r["Contribution Margin $000s"] ?? 0),
  contributionMargin: Number(r["Contribution Margin %"] ?? 0),
  marketing: Number(r["Marketing $000s"] ?? 0),
  payroll: Number(r["Payroll $000s"] ?? 0),
  otherOpex: Number(r["Other Opex $000s"] ?? 0),
  ebitda: Number(r["EBITDA $000s"] ?? 0),
  ebitdaMargin: Number(r["EBITDA Margin %"] ?? 0),
  cashFlow: Number(r["Net Cash Flow $000s"] ?? 0),
  endingCash: Number(r["Ending Cash $000s"] ?? 0),
  inventory: Number(r["Ending Inventory Units"] ?? 0),
  stockoutWeeks: Number(r["Stockout Risk SKU-Weeks"] ?? 0),
  status: String(r["Model Status"] ?? ""),
}));

const avgRevenue = forecast.reduce((s, m) => s + m.revenue, 0) / forecast.length;
const avgEbitda = forecast.reduce((s, m) => s + m.ebitda, 0) / forecast.length;
const maxRevenue = Math.max(...forecast.map((m) => m.revenue));
const minCash = Math.min(...forecast.map((m) => m.endingCash));

function money(v) {
  const sign = v < 0 ? "(" : "";
  const close = v < 0 ? ")" : "";
  return `${sign}$${Math.abs(v).toLocaleString("en-US", { maximumFractionDigits: 1 })}${close}`;
}
function pct(v) {
  return `${(v * 100).toFixed(1)}%`;
}
function units(v) {
  return v.toLocaleString("en-US", { maximumFractionDigits: 0 });
}
function delta(current, previous) {
  if (!previous) return null;
  return current - previous;
}
function directionWord(v, unit = "$") {
  if (v == null) return "opens the forecast year";
  if (Math.abs(v) < 0.05) return "is essentially flat";
  const display = unit === "%" ? `${(Math.abs(v) * 100).toFixed(1)} pts` : money(Math.abs(v));
  return `${v > 0 ? "improves" : "declines"} by ${display}`;
}
function takeaway(month, prev) {
  const revDelta = delta(month.revenue, prev?.revenue);
  const cashDelta = delta(month.endingCash, prev?.endingCash);
  const invDelta = delta(month.inventory, prev?.inventory);
  const revenuePhrase = revDelta == null
    ? `Forecast revenue starts at ${money(month.revenue)}`
    : `Revenue ${directionWord(revDelta)}`;
  const gmPhrase = `gross margin holds at ${pct(month.grossMargin)}`;
  const cashPhrase = cashDelta == null
    ? `ending cash is ${money(month.endingCash)}`
    : `cash ${directionWord(cashDelta)}`;
  const inventoryPhrase = invDelta == null
    ? `inventory closes at ${units(month.inventory)} units`
    : `inventory ${invDelta >= 0 ? "builds" : "draws down"} by ${units(Math.abs(invDelta))} units`;
  const riskPhrase = month.endingCash < 0
    ? "Cash remains the central board issue."
    : month.stockoutWeeks > 0
      ? "Inventory requires a sell-through and reorder review."
      : "No modeled stockout weeks appear in the month.";
  return `${revenuePhrase}; ${gmPhrase}. ${cashPhrase}, while ${inventoryPhrase}. ${riskPhrase}`;
}
function titleFor(month, prev) {
  const revDelta = delta(month.revenue, prev?.revenue);
  if (month.endingCash < minCash + 1) return `${month.label}: cash pressure reaches the year low`;
  if (month.revenue >= maxRevenue - 0.1) return `${month.label}: revenue peaks, but cash still tightens`;
  if (revDelta != null && revDelta > 35) return `${month.label}: demand steps up, not enough to offset spend`;
  if (revDelta != null && revDelta < -35) return `${month.label}: revenue softens and cash burn persists`;
  return `${month.label}: stable margin, persistent cash watch`;
}

const presentation = Presentation.create({ slideSize: { width: 1280, height: 720 } });

const C = {
  ink: "#000000",
  panel: "#F2F2F2",
  rule: "#B8BCC4",
  accent: "#6DCBF4",
  accentStrong: "#3D8DFF",
  pale: "#D0EDFA",
  red: "#D94B4B",
  white: "#FFFFFF",
};

function textBox(slide, name, text, position, style = {}) {
  const shape = slide.shapes.add({
    geometry: "textbox",
    name,
    position,
    fill: "none",
    line: { style: "solid", fill: "none", width: 0 },
  });
  shape.text = text;
  shape.text.style = {
    fontSize: style.fontSize ?? 24,
    typeface: "Helvetica Neue",
    color: style.color ?? C.ink,
    bold: style.bold ?? false,
    alignment: style.alignment ?? "left",
    verticalAlignment: style.verticalAlignment ?? "top",
    autoFit: style.autoFit ?? "shrinkText",
  };
  return shape;
}

function panel(slide, position, fill = C.panel, line = "none") {
  return slide.shapes.add({
    geometry: "roundRect",
    position,
    fill,
    line: { style: "solid", fill: line, width: line === "none" ? 0 : 1.3 },
  });
}

function addFooter(slide, n) {
  textBox(slide, `footer-${n}`, String(n), { left: 1184.18, top: 659.24, width: 54.48, height: 25.33 }, {
    fontSize: 13.33,
    alignment: "right",
    verticalAlignment: "bottom",
  });
}

function slideNotes(slide, month) {
  slide.speakerNotes.textFrame.setText(
    `Key interpretation: ${takeaway(month, forecast[forecast.indexOf(month) - 1])}\n\n[Sources]\nDreamBig ecommerce financial model workbook: ${WORKBOOK_PATH}\nSource range: Monthly_Board!A4:R28. Values are the forecast month row for ${month.label}; charts use the 2026 forecast rows from the same range.`
  );
  slide.speakerNotes.setVisible(true);
}

async function renderChartImage(type, config, width, height) {
  const chartDeck = Presentation.create({ slideSize: { width, height } });
  const chartSlide = chartDeck.slides.add();
  chartSlide.background.fill = C.white;
  chartSlide.charts.add(type, {
    ...config,
    position: { left: 0, top: 0, width, height },
  });
  const png = await chartDeck.export({ slide: chartSlide, format: "png", scale: 2 });
  return new Uint8Array(await png.arrayBuffer());
}

function lineChartConfig() {
  const categories = forecast.map((m) => m.short);
  return {
    categories,
    series: [
      {
        name: "Net Revenue $000s",
        categories,
        values: forecast.map((m) => Number(m.revenue.toFixed(1))),
        line: { style: "solid", width: 3, fill: C.accentStrong },
        marker: { symbol: "circle", size: 5 },
      },
      {
        name: "EBITDA $000s",
        categories,
        values: forecast.map((m) => Number(m.ebitda.toFixed(1))),
        line: { style: "solid", width: 3, fill: C.red },
        marker: { symbol: "circle", size: 5 },
      },
    ],
    hasLegend: true,
    legend: { position: "bottom", overlay: false, textStyle: { fontSize: 12, fill: C.ink } },
    chartFill: C.white,
    chartLine: { style: "solid", width: 0, fill: C.white },
    plotAreaFill: { type: "none" },
    plotAreaLine: { style: "solid", width: 0, fill: C.white },
    xAxis: { visible: true, line: { style: "solid", width: 1, fill: C.rule }, textStyle: { fontSize: 11, fill: C.ink } },
    yAxis: {
      visible: true,
      numberFormatCode: "$#,##0",
      majorGridlines: { style: "solid", width: 1, fill: "#EDEDED" },
      line: { style: "solid", width: 0, fill: C.white },
      textStyle: { fontSize: 11, fill: C.ink },
    },
    lineOptions: { grouping: "standard" },
  };
}

function barChartConfig(month) {
  const metrics = ["Revenue", "Contribution", "Marketing", "EBITDA"];
  return {
    categories: metrics,
    series: [
      {
        name: month.short,
        categories: metrics,
        values: [month.revenue, month.contribution, month.marketing, month.ebitda].map((v) => Number(v.toFixed(1))),
        fill: C.accent,
      },
      {
        name: "FY avg",
        categories: metrics,
        values: [avgRevenue, forecast.reduce((s, m) => s + m.contribution, 0) / 12, forecast.reduce((s, m) => s + m.marketing, 0) / 12, avgEbitda].map((v) => Number(v.toFixed(1))),
        fill: C.accentStrong,
      },
    ],
    hasLegend: true,
    legend: { position: "bottom", overlay: false, textStyle: { fontSize: 12, fill: C.ink } },
    dataLabels: { showValue: true, textStyle: { fontSize: 11, fill: C.ink } },
    chartFill: C.white,
    chartLine: { style: "solid", width: 0, fill: C.white },
    plotAreaFill: { type: "none" },
    plotAreaLine: { style: "solid", width: 0, fill: C.white },
    barOptions: { direction: "column", grouping: "clustered", gapWidth: 58 },
    xAxis: { visible: true, line: { style: "solid", width: 1, fill: C.rule }, textStyle: { fontSize: 11, fill: C.ink } },
    yAxis: {
      visible: true,
      numberFormatCode: "$#,##0",
      majorGridlines: { style: "solid", width: 1, fill: "#EDEDED" },
      line: { style: "solid", width: 0, fill: C.white },
      textStyle: { fontSize: 11, fill: C.ink },
    },
  };
}

async function addLineSlide(month, idx) {
  const prev = idx > 0 ? forecast[idx - 1] : null;
  const slide = presentation.slides.add();
  slide.background.fill = C.white;
  addFooter(slide, idx + 1);
  textBox(slide, `title-${idx}`, titleFor(month, prev), { left: 41.33, top: 36.12, width: 1197.33, height: 109.97 }, { fontSize: 38.67 });

  slide.images.add({
    blob: await renderChartImage("line", lineChartConfig(), 581.02, 527.51),
    contentType: "image/png",
    alt: "Trend chart: 2026 net revenue and EBITDA by month",
    fit: "contain",
    position: { left: 40.51, top: 131.73, width: 581.02, height: 527.51 },
  });

  textBox(slide, `takeaway-${idx}`, takeaway(month, prev), { left: 657.33, top: 180, width: 581.61, height: 132 }, { fontSize: 28 });

  panel(slide, { left: 658.48, top: 352.76, width: 271.07, height: 278.9 });
  panel(slide, { left: 968.42, top: 352.76, width: 271.07, height: 278.9 });
  textBox(slide, `stat-revenue-${idx}`, money(month.revenue), { left: 683.4, top: 375.85, width: 223.97, height: 121.35 }, { fontSize: 36, bold: true, verticalAlignment: "bottom" });
  textBox(slide, `stat-revenue-label-${idx}`, `Net revenue\n${directionWord(delta(month.revenue, prev?.revenue))}`, { left: 690.39, top: 522.1, width: 216.98, height: 92 }, { fontSize: 24 });
  textBox(slide, `stat-cash-${idx}`, money(month.endingCash), { left: 993.34, top: 375.85, width: 223.97, height: 121.35 }, { fontSize: 36, bold: true, verticalAlignment: "bottom", color: month.endingCash < 0 ? C.red : C.ink });
  textBox(slide, `stat-cash-label-${idx}`, `Ending cash\n${month.status}`, { left: 1000.33, top: 522.1, width: 216.98, height: 92 }, { fontSize: 24 });
  slideNotes(slide, month);
}

async function addColumnSlide(month, idx) {
  const prev = idx > 0 ? forecast[idx - 1] : null;
  const slide = presentation.slides.add();
  slide.background.fill = C.white;
  addFooter(slide, idx + 1);
  textBox(slide, `title-${idx}`, titleFor(month, prev), { left: 41.33, top: 36.12, width: 1197.33, height: 109.97 }, { fontSize: 38.67 });

  panel(slide, { left: 41.33, top: 109.33, width: 580.19, height: 570.61 }, "none", C.ink);
  slide.images.add({
    blob: await renderChartImage("bar", barChartConfig(month), 528.06, 502.32),
    contentType: "image/png",
    alt: `Column chart: ${month.label} metrics versus forecast-year average`,
    fit: "contain",
    position: { left: 66.61, top: 138.84, width: 528.06, height: 502.32 },
  });

  textBox(slide, `takeaway-${idx}`, takeaway(month, prev), { left: 675.36, top: 179.45, width: 559.75, height: 169.46 }, { fontSize: 28 });
  textBox(slide, `stat-gm-${idx}`, pct(month.grossMargin), { left: 668.36, top: 427.54, width: 223.97, height: 94.88 }, { fontSize: 36, bold: true, verticalAlignment: "bottom" });
  textBox(slide, `gm-label-${idx}`, `Gross margin\n${pct(month.contributionMargin)} contribution margin`, { left: 675.36, top: 522.1, width: 216.98, height: 92 }, { fontSize: 24 });
  textBox(slide, `stat-inventory-${idx}`, units(month.inventory), { left: 978.31, top: 427.54, width: 223.97, height: 94.88 }, { fontSize: 36, bold: true, verticalAlignment: "bottom" });
  textBox(slide, `inventory-label-${idx}`, `Ending inventory\n${month.stockoutWeeks ? `${month.stockoutWeeks} risk weeks` : "no stockout weeks"}`, { left: 985.3, top: 522.1, width: 216.98, height: 92 }, { fontSize: 24 });
  slideNotes(slide, month);
}

for (const [idx, month] of forecast.entries()) {
  if (idx % 2 === 0) await addLineSlide(month, idx);
  else await addColumnSlide(month, idx);
}

await fs.writeFile(
  path.join(TMP_DIR, "source-notes.txt"),
  `DreamBig monthly board reporting deck\n\n[Sources]\nWorkbook: ${WORKBOOK_PATH}\nRange: Monthly_Board!A4:R28\nUsage: all month-level KPIs, chart values, and takeaways are derived from 2026 forecast rows.\n`
);

const previewDir = path.join(TMP_DIR, "previews");
await fs.mkdir(previewDir, { recursive: true });
for (const [index, slide] of presentation.slides.items.entries()) {
  const stem = `slide-${String(index + 1).padStart(2, "0")}`;
  const png = await presentation.export({ slide, format: "png", scale: 1 });
  await fs.writeFile(path.join(previewDir, `${stem}.png`), new Uint8Array(await png.arrayBuffer()));
  const layout = await slide.export({ format: "layout" });
  await fs.writeFile(path.join(previewDir, `${stem}.layout.json`), await layout.text());
}

const montage = await presentation.export({ format: "webp", montage: true, scale: 1 });
await fs.writeFile(path.join(TMP_DIR, "deck-montage.webp"), new Uint8Array(await montage.arrayBuffer()));

const inspect = await presentation.inspect({ kind: "slide,textbox,shape,chart,notes", maxChars: 12000 });
await fs.writeFile(path.join(TMP_DIR, "deck-inspect.ndjson"), inspect.ndjson);
console.log(inspect.ndjson);

const pptx = await PresentationFile.exportPptx(presentation);
await pptx.save(FINAL_PPTX);
console.log(FINAL_PPTX);
