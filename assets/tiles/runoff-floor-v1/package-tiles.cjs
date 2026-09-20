// Packaging generated source art: nearest-neighbor sampling, consistent seams,
// PNG export, atlas assembly and enlarged nearest-neighbor previews.
const fs = require('fs');
const zlib = require('zlib');
const path = require('path');
const bmp = fs.readFileSync(process.argv[2]);
const w = bmp.readInt32LE(18), rawH = bmp.readInt32LE(22), h = Math.abs(rawH);
const bpp = bmp.readUInt16LE(28), offset = bmp.readUInt32LE(10);
if (bpp !== 32) throw new Error('Expected 32-bit BMP source');
function source(x,y) {
  const i = offset + ((rawH < 0 ? y : h-1-y)*w+x)*4;
  return [bmp[i+2],bmp[i+1],bmp[i],255];
}
function crc(buf) {
  let c=0xffffffff;
  for (const v of buf) {c^=v; for(let n=0;n<8;n++) c=(c>>>1)^((c&1)?0xedb88320:0);}
  return (c^0xffffffff)>>>0;
}
function chunk(type,data) {
  const t=Buffer.from(type), b=Buffer.alloc(12+data.length);
  b.writeUInt32BE(data.length);t.copy(b,4);data.copy(b,8);
  b.writeUInt32BE(crc(Buffer.concat([t,data])),8+data.length);return b;
}
function png(name,width,height,pixel) {
  const raw=Buffer.alloc(height*(1+width*4));
  for(let y=0;y<height;y++) for(let x=0;x<width;x++) Buffer.from(pixel(x,y)).copy(raw,y*(1+width*4)+1+x*4);
  const ih=Buffer.alloc(13);ih.writeUInt32BE(width);ih.writeUInt32BE(height,4);ih[8]=8;ih[9]=6;
  fs.writeFileSync(path.join(__dirname,name),Buffer.concat([Buffer.from([137,80,78,71,13,10,26,10]),chunk('IHDR',ih),chunk('IDAT',zlib.deflateSync(raw)),chunk('IEND',Buffer.alloc(0))]));
}
const names=['plain','cracked','mossy','damp'];
const tiles=names.map((name,i)=>Array.from({length:1024},(_,p)=>{
  const x=p%32,y=Math.floor(p/32);
  return source(Math.min(w-1,Math.floor(((i%2)+(x+.5)/32)*w/2)),Math.min(h-1,Math.floor((Math.floor(i/2)+(y+.5)/32)*h/2)));
}));
// Uniform one-pixel mortar perimeter makes all variants interchangeable.
const mortar=[39,46,43,255];
for(const tile of tiles) for(let y=0;y<32;y++) for(let x=0;x<32;x++) if(x===0||y===0||x===31||y===31) tile[y*32+x]=mortar;
for(let i=0;i<4;i++) png('floor_'+names[i]+'.png',32,32,(x,y)=>tiles[i][y*32+x]);
png('floor_atlas_32.png',64,64,(x,y)=>tiles[Math.floor(y/32)*2+Math.floor(x/32)][(y%32)*32+x%32]);
png('preview_variants.png',512,512,(x,y)=>tiles[Math.floor(y/256)*2+Math.floor(x/256)][Math.floor(y%256/8)*32+Math.floor(x%256/8)]);
const layout=[0,0,1,0,2,0,0,3,0,1,0,0,3,0,2,0,0,0,0,1,0,2,0,0];
png('preview_tiled.png',768,512,(x,y)=>tiles[layout[Math.floor(y/128)*6+Math.floor(x/128)]][Math.floor(y%128/4)*32+Math.floor(x%128/4)]);
for(const tile of tiles) for(let n=0;n<32;n++) {
  if(String(tile[n])!==String(mortar)||String(tile[n*32])!==String(mortar)) throw new Error('Seam mismatch');
}
console.log('Exported four 32x32 RGBA tiles, 64x64 atlas, and two nearest-neighbor previews. Matching perimeter verified.');
