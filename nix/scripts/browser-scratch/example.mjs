// Template for ad hoc browser checks. Copy this pattern into a throwaway
// .mjs file (or edit this one in place) rather than inventing a new
// invocation style each time - see ../../CLAUDE.md's Playwright section
// for why this project exists.
//
// Run with: bun example.mjs   (or: node example.mjs)
import { chromium } from "playwright";

const url = process.argv[2] || "http://localhost:4200";

const browser = await chromium.launch({ headless: true });
const page = await browser.newPage();
await page.goto(url, { waitUntil: "networkidle" });

// Prefer cheap, targeted reads over screenshots - a few hundred bytes of
// text instead of thousands of tokens of image.
const title = await page.title();
console.log("title:", title);

// Example: read computed style instead of eyeballing a screenshot.
// const el = await page.$(".some-selector");
// console.log(await el.evaluate((e) => getComputedStyle(e).color));

// Example: extract text/state instead of a full accessibility dump.
// console.log(await page.locator("header").innerText());

// Only screenshot when a human/visual check is genuinely needed, and
// scope it (viewport, not full page) unless full page is the point.
// await page.screenshot({ path: "out.png" });

await browser.close();
