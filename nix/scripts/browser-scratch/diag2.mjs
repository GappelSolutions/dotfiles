import { chromium } from 'playwright';
const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 1400, height: 900 } });
await page.goto('http://localhost:4210/users-poc');
await page.getByRole('button', { name: 'Table view' }).click();
await page.waitForTimeout(500);
await page.mouse.move(700, 500);
await page.mouse.wheel(0, 400);
await page.waitForTimeout(400);
await page.screenshot({ path: '/tmp/claude-1000/-home-cgpp-dev-nova-gdm-demo-ui/f60c1738-7ac7-4628-b0df-494787e3762c/scratchpad/diag2.png' });
const info = await page.evaluate(() => {
  const ths = [...document.querySelectorAll('thead th')];
  const sticky = ths[ths.length - 1];
  return { rect: sticky.getBoundingClientRect() };
});
console.log(JSON.stringify(info));
await browser.close();
