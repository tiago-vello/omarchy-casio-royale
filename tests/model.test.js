// Run: node tests/model.test.js Model.js
const fs=require('fs');const src=fs.readFileSync(process.argv[2],'utf8').replace('.pragma library','');
const M=new Function(src+';return {initial,startStop,splitReset,shown,barLabel,parts,isZero};')();
let s=M.initial();
s=M.startStop(s,1000);                       // start
s=M.splitReset(s,6000); console.log('split1', M.shown(s,9000)); // 5000
s=M.startStop(s,8000); console.log('stopped, still split', M.shown(s,99999)); //5000
s=M.splitReset(s,9000); console.log('2nd place', M.shown(s,99999)); //7000
s=M.splitReset(s,9000); console.log('reset zero', M.isZero(s));
s=M.startStop(s,1); s=M.startStop(s,3723457); console.log(M.barLabel(M.shown(s,0)), JSON.stringify(M.parts(M.shown(s,0))));
