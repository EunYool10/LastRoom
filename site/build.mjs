// 배포 사이트 만들기: site/index.html(내려받기 안내) + build/web(웹 버전) → build/site
// 사용: node site/build.mjs
import fs from 'fs';
import path from 'path';

const root = path.resolve(path.dirname(new URL(import.meta.url).pathname.replace(/^\/([A-Za-z]:)/, '$1')), '..');
const web = path.join(root, 'build', 'web');
const out = path.join(root, 'build', 'site');

fs.rmSync(out, { recursive: true, force: true });
fs.mkdirSync(path.join(out, 'play'), { recursive: true });
for (const f of fs.readdirSync(web)) fs.copyFileSync(path.join(web, f), path.join(out, 'play', f));
fs.copyFileSync(path.join(root, 'site', 'index.html'), path.join(out, 'index.html'));
fs.cpSync(path.join(root, 'site', 'img'), path.join(out, 'img'), { recursive: true });
fs.copyFileSync(path.join(root, 'assets', 'tex', 'icon.png'), path.join(out, 'icon.png'));
fs.writeFileSync(path.join(out, '.nojekyll'), '');

// 웹 버전 첫 화면: 불러오는 중 화면과 세로 화면 안내를 게임 분위기에 맞춘다
const p = path.join(out, 'play', 'index.html');
let h = fs.readFileSync(p, 'utf8');
const swap = (a, b) => {
  if (!h.includes(a)) throw new Error('shell changed: ' + a.slice(0, 50));
  h = h.replace(a, b);
};
swap('<html lang="en">', '<html lang="ko">');
swap('</style>', `
#lr-load { text-align: center; font-family: "Nanum Myeongjo", "AppleMyungjo", "Batang", serif; color: #efe9df; margin-bottom: 7vh; }
#lr-load .k { font-size: 14px; letter-spacing: .3em; color: #a39b8e; margin: 0 0 6px; }
#lr-load .t { font-size: 46px; font-weight: 800; margin: 0; }
#lr-load .m { font-family: sans-serif; font-size: 13px; color: #7d756a; margin: 18px 0 0; }
#status-progress { -webkit-appearance: none; appearance: none; height: 2px; width: min(360px, 60%); bottom: 26%; border: 0; background: #2f2a25; }
#status-progress::-webkit-progress-bar { background: #2f2a25; }
#status-progress::-webkit-progress-value { background: #d9b26a; }
#status-progress::-moz-progress-bar { background: #d9b26a; }
#status-notice { background: #241f1b; border: 1px solid #5a4f40; border-radius: 0; font-family: sans-serif; }
#lr-rotate { display: none; }
@media (orientation: portrait) and (max-width: 900px) {
  #lr-rotate { display: flex; position: fixed; inset: 0; z-index: 10; background: #14110f; color: #d8d0c4; align-items: center; justify-content: center; text-align: center; font-family: sans-serif; font-size: 16px; line-height: 1.7; padding: 24px; }
}
</style>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Nanum+Myeongjo:wght@800&display=swap">`);
swap('<div id="status">', `<div id="lr-rotate"><div>휴대폰을 가로로 돌려 주세요.<br><small style="color:#7d756a">마지막 방은 가로 화면에서 합니다.</small></div></div>
		<div id="status">
			<div id="lr-load"><p class="k">특수청소부의 기록</p><p class="t">마지막 방</p><p class="m">처음 한 번은 내려받는 데 시간이 걸립니다.</p></div>`);
swap(`'Error\\nThe following features required to run Godot projects on the Web are missing:\\n'`, `'이 브라우저에서는 실행할 수 없습니다.\\n최신 Chrome · Edge · Safari로 열어 주세요.\\n\\n빠진 기능:\\n'`);
swap(`'An unknown error occurred.'`, `'알 수 없는 문제로 시작하지 못했습니다. 새로 고침해 주세요.'`);
h = h.replace('Your browser does not support the canvas tag.', '이 브라우저에서는 실행할 수 없습니다.').replace('Your browser does not support JavaScript.', 'JavaScript를 켜야 실행할 수 있습니다.');
fs.writeFileSync(p, h);

let total = 0;
for (const f of fs.readdirSync(path.join(out, 'play'))) total += fs.statSync(path.join(out, 'play', f)).size;
console.log('site ready:', out, 'play/', (total / 1e6).toFixed(1) + 'MB');
