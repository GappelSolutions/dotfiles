import { chromium } from 'playwright';
const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 900, height: 700 } });
await page.goto('http://localhost:4210/users-poc');
await page.getByRole('button', { name: 'Table view' }).click();
await page.waitForTimeout(500);
// scroll table horizontally
await page.evaluate(() => {
  document.querySelector('.overflow-x-auto').scrollLeft = 500;
});
await page.waitForTimeout(200);
await page.mouse.move(700, 400);
await page.mouse.wheel(0, 300);
await page.waitForTimeout(400);
await page.screenshot({ path: '/tmp/claude-1000/-home-cgpp-dev-nova-gdm-demo-ui/f60c1738-7ac7-4628-b0df-494787e3762c/scratchpad/diag3.png' });
await browser.close();
