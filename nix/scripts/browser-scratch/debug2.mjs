import { chromium } from 'playwright';
const browser = await chromium.launch({ headless: true });
const page = await browser.newPage();
const results = {};

async function step(name, fn) {
  try {
    results[name] = await fn();
  } catch (e) {
    results[name] = `ERROR: ${e.message.split('\n')[0]}`;
  }
}

await page.goto('http://localhost:4210/users-poc/toolbar', { waitUntil: 'networkidle' });

await step('roleFilter', async () => {
  const roleField = page.locator('span.text-sm.font-medium', { hasText: 'Role' }).locator('..');
  await roleField.locator('button[role="combobox"]').click();
  await page.waitForTimeout(200);
  const options = await page.locator('[role="option"]').allInnerTexts();
  await page.locator('[role="option"]', { hasText: 'GdmAdmin' }).click();
  await page.waitForTimeout(250);
  const filteredCount = await page.locator('app-user-card').count();
  const hasChip = (await page.locator('body').innerText()).includes('Role: GdmAdmin');
  return { options, filteredCount, hasChip };
});

await step('clearAll', async () => {
  await page.locator('button:has-text("Clear all filters")').click();
  await page.waitForTimeout(250);
  return page.locator('app-user-card').count();
});

await step('numberRangeFilter', async () => {
  const filteredBefore = await page.locator('app-user-card').count();
  await page.locator('input[placeholder="Min"]').fill('10');
  await page.locator('input[placeholder="Min"]').blur();
  await page.waitForTimeout(250);
  const filteredAfter = await page.locator('app-user-card').count();
  const hasChip = (await page.locator('body').innerText()).includes('Login attempts:');
  await page.locator('button:has-text("Clear all")').first().click();
  await page.waitForTimeout(200);
  return { filteredBefore, filteredAfter, hasChip };
});

console.log(JSON.stringify(results, null, 2));

await page.goto('http://localhost:4210/users-poc/sidebar', { waitUntil: 'networkidle' });
const r2 = {};
async function step2(name, fn) {
  try {
    r2[name] = await fn();
  } catch (e) {
    r2[name] = `ERROR: ${e.message.split('\n')[0]}`;
  }
}
await step2('tenantMultiSelect', async () => {
  const before = await page.locator('app-user-card').count();
  await page.locator('button:has-text("All tenants")').click();
  await page.waitForTimeout(200);
  const items = await page.locator('button[hlmDropdownMenuCheckbox]').allInnerTexts();
  await page.locator('button[hlmDropdownMenuCheckbox]', { hasText: 'Ensor' }).click();
  await page.waitForTimeout(200);
  await page.keyboard.press('Escape');
  await page.waitForTimeout(150);
  const after = await page.locator('app-user-card').count();
  const hasChip = (await page.locator('body').innerText()).includes('Tenant: Ensor');
  return { before, items, after, hasChip };
});
console.log(JSON.stringify(r2, null, 2));

await browser.close();
