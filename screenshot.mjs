import puppeteer from 'puppeteer';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const screenshotsDir = path.join(__dirname, 'temporary screenshots');

if (!fs.existsSync(screenshotsDir)) {
  fs.mkdirSync(screenshotsDir, { recursive: true });
}

const url = process.argv[2] || 'http://localhost:3000';
const label = process.argv[3] || '';

const existing = fs.readdirSync(screenshotsDir)
  .filter(f => f.startsWith('screenshot-') && f.endsWith('.png'))
  .map(f => {
    const match = f.match(/^screenshot-(\d+)/);
    return match ? parseInt(match[1]) : 0;
  });

const nextN = existing.length > 0 ? Math.max(...existing) + 1 : 1;
const filename = label ? `screenshot-${nextN}-${label}.png` : `screenshot-${nextN}.png`;
const outputPath = path.join(screenshotsDir, filename);

// Optional viewport from 3rd arg: "375", "768", "1440" (default)
const viewportArg = process.argv[4] ? parseInt(process.argv[4]) : 1440;
const viewportH   = viewportArg <= 375 ? 812 : viewportArg <= 768 ? 1024 : 900;

const browser = await puppeteer.launch({ headless: true });
const page = await browser.newPage();
await page.setViewport({ width: viewportArg, height: viewportH, deviceScaleFactor: viewportArg <= 768 ? 2 : 1 });
await page.goto(url, { waitUntil: 'networkidle2' });

// Scroll through page to trigger IntersectionObserver for all elements
await page.evaluate(async () => {
  await new Promise(resolve => {
    const height = document.body.scrollHeight;
    const step = 400;
    let y = 0;
    const scroll = () => {
      window.scrollTo(0, y);
      y += step;
      if (y < height) requestAnimationFrame(scroll);
      else { window.scrollTo(0, 0); setTimeout(resolve, 400); }
    };
    scroll();
  });
});

await page.screenshot({ path: outputPath, fullPage: true });
await browser.close();

console.log(`Screenshot saved: ${outputPath}`);
