const sbbsIniPath = "/sbbs/ctrl/sbbs.ini";
let sbbsIni = await Deno.readTextFile(sbbsIniPath);
if (/^\s*Interface\s*=.*$/m.test(sbbsIni)) {
  sbbsIni = sbbsIni.replace(
    /^\s*Interface\s*=.*$/m,
    "    Interface = 0.0.0.0",
  );
}
await Deno.writeTextFile(sbbsIniPath, sbbsIni);

const modoptsPath = "/sbbs/ctrl/modopts.ini";
let modopts = await Deno.readTextFile(modoptsPath);
modopts = modopts.replaceAll("../webv4", "../web");
await Deno.writeTextFile(modoptsPath, modopts);
