// 배포 사이트 만들기: site/index.html(내려받기 안내) + build/web(웹 버전) → build/site
// 사용: node site/build.mjs
import fs from 'fs';
import path from 'path';

const root = path.resolve(path.dirname(new URL(import.meta.url).pathname.replace(/^\/([A-Za-z]:)/, '$1')), '..');
const web = path.join(root, 'build', 'web');
const out = path.join(root, 'build', 'site');

fs.rmSync(out, { recursive: true, force: true });
fs.mkdirSync(path.join(out, 'play'), { recursive: true });
for (const f of fs.readdirSync(web)) if (!f.endsWith('.import')) fs.copyFileSync(path.join(web, f), path.join(out, 'play', f));
fs.copyFileSync(path.join(root, 'site', 'index.html'), path.join(out, 'index.html'));
fs.cpSync(path.join(root, 'site', 'img'), path.join(out, 'img'), { recursive: true });
fs.copyFileSync(path.join(root, 'assets', 'tex', 'icon.png'), path.join(out, 'icon.png'));
fs.writeFileSync(path.join(out, '.nojekyll'), '');
fs.copyFileSync(path.join(root, 'site', 'version.json'), path.join(out, 'version.json'));

// 이용 안내 및 약관: 게임 · 설치 프로그램과 같은 글(data/terms.json)
const T = JSON.parse(fs.readFileSync(path.join(root, 'data', 'terms.json'), 'utf8'));
const esc = (t) => String(t).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
const link = (t) => esc(t).replace(/https:\/\/[^\s]+/g, (u) => `<a href="${u}">${u}</a>`);
const termsHtml = `<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<meta name="theme-color" content="#14110f">
<title>마지막 방 — ${esc(T.subtitle)}</title>
<link rel="icon" type="image/png" href="icon.png">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Nanum+Gothic:wght@400;700&family=Nanum+Myeongjo:wght@700;800&display=swap">
<style>
* { box-sizing: border-box; }
body { margin: 0; background: #13100e; color: #d8d0c4; font-family: "Nanum Gothic", "Apple SD Gothic Neo", "Malgun Gothic", sans-serif; line-height: 1.7; }
.wrap { max-width: 820px; margin: 0 auto; padding: 40px 20px 56px; }
.back { color: #9d9488; font-size: 14px; text-decoration: none; }
.back:hover { color: #efe9df; }
.sheet { margin-top: 18px; background: #ece4d6; color: #2b2622; padding: 36px 40px; border: 1px solid #cfc3ae; box-shadow: 0 18px 40px rgba(0,0,0,.45); }
.kicker { margin: 0; font-size: 13px; letter-spacing: .2em; color: #6b6157; }
h1 { margin: 4px 0 0; font-family: "Nanum Myeongjo", serif; font-weight: 800; font-size: 28px; }
.owner { margin: 14px 0 0; font-weight: 700; font-size: 15px; }
.intro { margin: 14px 0 0; padding-top: 14px; border-top: 2px solid #2b2622; font-size: 15px; }
h2 { margin: 26px 0 6px; font-family: "Nanum Myeongjo", serif; font-size: 19px; }
ul { margin: 0; padding-left: 20px; font-size: 15px; }
li { margin: 4px 0; }
.date { margin: 28px 0 0; font-size: 13px; color: #6b6157; }
a { color: #2b2622; }
@media (max-width: 560px) { .sheet { padding: 26px 18px; } h1 { font-size: 23px; } }
</style>
</head>
<body>
<div class="wrap">
  <a class="back" href="./">← 마지막 방 내려받기</a>
  <article class="sheet">
    <p class="kicker">${esc(T.subtitle)}</p>
    <h1>${esc(T.title)}</h1>
    <p class="owner">${T.owner.map(esc).join('<br>')}</p>
    <p class="intro">${esc(T.intro)}</p>
${T.sections.map((sec, i) => `    <h2>${i + 1}. ${esc(sec.h)}</h2>
    <ul>
${sec.items.map((it) => `      <li>${link(it)}</li>`).join('\n')}
    </ul>`).join('\n')}
    <p class="date">적용일: ${esc(T.version)}</p>
  </article>
</div>
</body>
</html>
`;
fs.writeFileSync(path.join(out, 'terms.html'), termsHtml);

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
