// data/terms.json → installer/license_ko.txt (설치 화면의 이용 안내, UTF-16LE)
// 사용: node installer/make_license.mjs
import fs from 'fs';
import path from 'path';

const here = path.dirname(new URL(import.meta.url).pathname.replace(/^\/([A-Za-z]:)/, '$1'));
const T = JSON.parse(fs.readFileSync(path.join(here, '..', 'data', 'terms.json'), 'utf8'));

// 설치 창 글상자 폭에 맞춰 줄 바꾸기 (한글은 두 칸으로 센다)
const cols = (s) => [...s].reduce((n, ch) => n + (/[ᄀ-ᇿ　-鿿가-힣＀-￯]/.test(ch) ? 2 : 1), 0);
function wrap(text, first, rest, width = 64) {
  const out = [];
  let line = first;
  for (const word of text.split(' ')) {
    const next = line.trim() === '' || line === first ? line + word : line + ' ' + word;
    if (cols(next) > width && line !== first && line.trim() !== '') {
      out.push(line);
      line = rest + word;
    } else {
      line = next;
    }
  }
  out.push(line);
  return out;
}

const L = [];
L.push(T.title, T.subtitle, '', ...T.owner, '');
L.push(...wrap(T.intro, '', ''), '');
T.sections.forEach((s, i) => {
  L.push(`${i + 1}. ${s.h}`);
  for (const it of s.items) L.push(...wrap(it, '   - ', '     '));
  L.push('');
});
L.push(`적용일: ${T.version}`, '', '위 내용에 동의하면 [동의함]을 눌러 설치를 계속하세요.', '');

const text = L.join('\r\n');
fs.writeFileSync(path.join(here, 'license_ko.txt'), Buffer.concat([Buffer.from([0xff, 0xfe]), Buffer.from(text, 'utf16le')]));
console.log('license_ko.txt', L.length, 'lines');
