import { chromium } from 'playwright';
const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 1400, height: 900 } });
await page.goto('http://localhost:4210/users-poc');
await page.getByRole('button', { name: 'Table view' }).click();
await page.waitForTimeout(600);
await page.screenshot({ path: '/tmp/claude-1000/-home-cgpp-dev-nova-gdm-demo-ui/f60c1738-7ac7-4628-b0df-494787e3762c/scratchpad/diag1.png' });

const info = await page.evaluate(() => {
  const ths = [...document.querySelectorAll('thead th')];
  const sticky = ths[ths.length - 1];
  const cs = getComputedStyle(sticky);
  const wrapper = sticky.closest('div');
  return {
    stickyClass: sticky.className,
    stickyRect: sticky.getBoundingClientRect(),
    position: cs.position,
    top: cs.top,
    zIndex: cs.zIndex,
    wrapperOverflowY: getComputedStyle(wrapper).overflowY,
  };
});
console.log(JSON.stringify(info, null, 2));
await browser.close();
