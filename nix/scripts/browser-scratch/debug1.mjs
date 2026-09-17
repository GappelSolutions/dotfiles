import { chromium } from 'playwright';
const browser = await chromium.launch({ headless: true });
const page = await browser.newPage();
await page.goto('http://localhost:4210/users-poc/toolbar', { waitUntil: 'networkidle' });
const sortDiv = await page.locator('span.text-xs:has-text("Sort")').locator('..').innerHTML();
console.log(sortDiv);
await browser.close();
